class Apache::Config::Converter::Nginx;

use Apache::Config::Parser;
use Apache::Config::Actions;
use Nginx::Config;

method convert(Str $config) {
    my $parser = Apache::Config::Parser.new;
    my $actions = Apache::Config::Actions.new;

    my @cms = $parser.parse(
        $config,
        :actions($actions),
    ).ast.virtual_hosts.grep(Apache::Config::Actions::VirtualHost);

    my Str $nginx_config = '';

    for @cms -> $cms {
        my $canonical   = canonical_domain($cms);
        my $mobile      = mobile_redirect($cms);
        my @locations   = non_proxied_locations($cms);
        my @redirects   = redirects($cms);
        my @error_pages = error_pages($cms);

        my @directives = $cms.directives\
            .grep({ not (
                $_ ~~ Apache::Config::Actions::UnknownDirective
                and (
                    .name ~~ /XSendFile/
                    or .name eq 'RewriteEngine'
                    or .data ~~ /zms_instance/
                    or .name eq 'Alias' and .data ~~ /static/
                )
            ) })\
            .grep({ not ($_ ~~ Apache::Config::Actions::RedirectMatch and $_.regex.Str ~~ m!\/statistik!) })\
            .map({Nginx::Config::Generic.new(content => $_.Str)});
        push @directives, @error_pages;
        push @directives, Nginx::Config::CMS.new if $cms.is_cms;
        push @directives, @locations;
        push @directives, @redirects;
        push @directives, Nginx::Config::MobileRedirect.new;

        if $canonical and $canonical eq $cms.name {
            $nginx_config ~= Nginx::Config::Server.new(
                names => $cms.aliases,
                directives => [
                    Nginx::Config::DomainRedirect.new,
                ],
            ).Str;
            $nginx_config ~= Nginx::Config::Server.new(
                names      => $canonical,
                directives => @directives,
            ).Str;
        }
        else {
            $nginx_config ~= Nginx::Config::Server.new(
                names      => [$cms.name, $cms.aliases.list],
                directives => @directives,
            ).Str;
        }
    }

    return $nginx_config;
}

sub canonical_domain(Apache::Config::Actions::VirtualHost $vhost) {
    # RewriteCond %{HTTP_HOST} !www\.kollegger.co.at$
    # RewriteRule ^(.*)$ http://www.kollegger.co.at$1 [R=301,L]

    my @conds = $vhost.directives.grep-index(Apache::Config::Actions::RewriteCond);
    for @conds -> $cond {
        (my $domain = $vhost.directives[$cond].canonical_host) or next;
        if $vhost.directives[$cond + 1] ~~ { $_ ~~ Apache::Config::Actions::RewriteRule and $_.regex.Str eq '^(.*)$' } {
            $vhost.directives.splice($cond, 2);
            return $domain;
        }
    }
    return;
}

sub mobile_redirect(Apache::Config::Actions::VirtualHost $vhost) {
    #RewriteCond.new(value => "\%\{HTTP_USER_AGENT}", regex => "ip(hone|od)|android|windowssce|iemobile|windows\\ ce;|avantgo|blackberry|blazer|elaine|hiptop|kindle|midp|mmp|o2|opera\\ mini|palm(\\ os)?|pda|plucker|pocket|psp|smartphone|symbian|treo|up\\.(browser|link)|vodafone|wap|windows\\ ce;\\ (iemobile|ppc)|xiino", options => "[NC,OR]")
    #RewriteCond.new(value => "\%\{HTTP_COOKIE}", regex => "version=mobile", options => Any)
    #RewriteCond.new(value => "\%\{HTTP_COOKIE}", regex => "!version=desktop", options => Any)
    #RewriteCond.new(value => "\%\{REQUEST_URI}", regex => "!^/common/pdf_magazin/", options => Any)
    #RewriteRule.new(regex => "^(.*)/index_ger\\.html\$", replacement => Any, options => "[R,L]"

    my @conds = $vhost.directives.grep-index({
        $_ ~~ Apache::Config::Actions::RewriteCond
        and $_.value eq '%{HTTP_USER_AGENT}'
        and $_.regex ~~ /android/
    });
    for @conds -> $cond {
        1 until $vhost.directives.splice($cond, 1)[0] ~~ Apache::Config::Actions::RewriteRule;
        return True;
    }
    return;
}

sub non_proxied_locations(Apache::Config::Actions::VirtualHost $vhost) {
    my @directives;
    my @locations;
    for $vhost.directives -> $directive {
        given $directive {
            when ($_ ~~ Apache::Config::Actions::ProxyPass and $_.uri eq '!') {
                @locations.push(Nginx::Config::Location.new(path => $_.path));
            }
            when ($_ ~~ Apache::Config::Actions::ProxyPassMatch and $_.uri eq 'http://0:8084/') {
                my $alternatives = $_.regex.atoms[1].atoms[0].alternatives;
                for <error icons cgi-bin htdig statistik statistik$ statistik\$ sys_static> -> $obsolete {
                    my $i = $alternatives.first-index({$_.Str eq $obsolete});
                    $alternatives.splice($i, 1) if defined $i;
                }
                @locations.push(Nginx::Config::Location.new(op => '~', path => $_.regex.Str));
            }
            when (
                $_ ~~ Apache::Config::Actions::ProxyPassMatch
                and $_.regex.Str eq '^/static(/content)/(.*)'
            ) { }
            when (
                $_ ~~ Apache::Config::Actions::UnknownDirective
                and (.name eq 'ProxyPassReverse' or .name eq 'ProxyPreserveHost')
            ) { }
            default {
                @directives.push($directive);
            }
        }
    }
    $vhost.directives = @directives;
    return @locations;
}

sub redirects(Apache::Config::Actions::VirtualHost $vhost) {
    my @directives;
    my @locations;
    for $vhost.directives -> $directive {
        given $directive {
            when Apache::Config::Actions::Redirect {
                @locations.push(
                    Nginx::Config::Location.new(
                        path       => $_.path,
                        directives => Nginx::Config::Return.new(
                            value => $_.uri,
                        ),
                    )
                );
            }
            when Apache::Config::Actions::RedirectMatch {
                next if $_.regex.atoms[0].Str eq '/statistik'; # already handled by include
                @locations.push(
                    Nginx::Config::Location.new(
                        op         => $_.regex.end_anchored ?? '=' !! '~',
                        path       => $_.regex.end_anchored ?? $_.regex.atoms[0].Str !! $_.regex.Str,
                        directives => Nginx::Config::Return.new(
                            value => $_.uri,
                        ),
                    )
                );
            }
            default {
                @directives.push($directive);
            }
        }
    }
    $vhost.directives = @directives;
    return @locations;
}

sub error_pages(Apache::Config::Actions::VirtualHost $vhost) {
    my @directives;
    my @error_pages;
    for $vhost.directives -> $directive {
        given $directive {
            when Apache::Config::Actions::ErrorDocument {
                @error_pages.push(
                    Nginx::Config::ErrorPage.new(
                        status => $_.status,
                        uri    => $_.uri,
                    )
                );
            }
            default {
                @directives.push($directive);
            }
        }
    }
    $vhost.directives = @directives;
    return @error_pages;
}

# vim: ft=perl6
