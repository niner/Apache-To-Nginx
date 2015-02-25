class Apache::Config::Converter::Nginx;

use Apache::Config::Parser;
use Apache::Config::Actions;
use Nginx::Config;

# RewriteCond %{HTTP_HOST} !www\.kollegger.co.at$
# RewriteRule ^(.*)$ http://www.kollegger.co.at$1 [R=301,L]

subset CanonicalHostCondition of Apache::Config::RewriteCond where *.canonical_host;
subset CanonicalHostRewrite of Apache::Config::RewriteRule where *.regex.Str eq '^(.*)$';

multi method convert_directive(
    @directives where (
            @directives[0] ~~ CanonicalHostCondition 
        and @directives[1] ~~ CanonicalHostRewrite
    )
) {
    $*canonical_host = @directives[0].canonical_host;
    shift @directives;
    shift @directives;
    return;
}

#RewriteCond.new(value => "\%\{HTTP_USER_AGENT}", regex => "ip(hone|od)|android|windowssce|iemobile|windows\\ ce;|avantgo|blackberry|blazer|elaine|hiptop|kindle|midp|mmp|o2|opera\\ mini|palm(\\ os)?|pda|plucker|pocket|psp|smartphone|symbian|treo|up\\.(browser|link)|vodafone|wap|windows\\ ce;\\ (iemobile|ppc)|xiino", options => "[NC,OR]")
#RewriteCond.new(value => "\%\{HTTP_COOKIE}", regex => "version=mobile", options => Any)
#RewriteCond.new(value => "\%\{HTTP_COOKIE}", regex => "!version=desktop", options => Any)
#RewriteCond.new(value => "\%\{REQUEST_URI}", regex => "!^/common/pdf_magazin/", options => Any)
#RewriteRule.new(regex => "^(.*)/index_ger\\.html\$", replacement => Any, options => "[R,L]"

subset MobileCondition of Apache::Config::RewriteCond
    where {$_.value eq '%{HTTP_USER_AGENT}' and $_.regex ~~ /android/};

multi method convert_directive(
    @directives where @directives[0] ~~ MobileCondition
) {
    True until @directives.shift ~~ Apache::Config::RewriteRule;
    return Nginx::Config::MobileRedirect.new;
}

multi method convert_directive(
    @directives where @directives[0] ~~ Apache::Config::ErrorDocument
) {
    my $error_page = @directives.shift;
    return Nginx::Config::ErrorPage.new(
        status => $error_page.status,
        uri    => $error_page.uri,
    );
}

subset ProxyException of Apache::Config::ProxyPass
    where *.uri eq '!';

multi method convert_directive(
    @directives where @directives[0] ~~ ProxyException
) {
    return Nginx::Config::Location.new(path => @directives.shift.path);
}

subset CMSProxy of Apache::Config::ProxyPassMatch where *.uri eq 'http://0:8084/';

multi method convert_directive(
    @directives where @directives[0] ~~ CMSProxy
) {
    my $directive = @directives.shift;
    my $alternatives = $directive.regex.atoms[1].atoms[0].alternatives;
    for <error icons cgi-bin htdig statistik statistik$ statistik\$ sys_static> -> $obsolete {
        my $i = $alternatives.first-index({$_.Str eq $obsolete});
        $alternatives.splice($i, 1) if defined $i;
    }
    return Nginx::Config::Location.new(op => '~', path => $directive.regex.Str);
}

subset CMSProxyStatic of Apache::Config::ProxyPassMatch
    where *.regex.Str eq '^/static(/content)/(.*)';

multi method convert_directive(
    @directives where @directives[0] ~~ CMSProxyStatic
) {
    @directives.shift;
    return;
}

multi method convert_directive(
    @directives where @directives[0] ~~ Apache::Config::Redirect
) {
    my $redirect = @directives.shift;
    Nginx::Config::Location.new(
        path       => $redirect.path,
        directives => Nginx::Config::Return.new(
            value => $redirect.uri,
        ),
    )
}

multi method convert_directive(
    @directives where @directives[0] ~~ Apache::Config::RedirectMatch
) {
    my $redirect = @directives.shift;
    return if $redirect.regex.atoms[0].Str eq '/statistik'; # already handled by include
    return Nginx::Config::Location.new(
        op         => $redirect.regex.end_anchored ?? '=' !! '~',
        path       => $redirect.regex.end_anchored ?? $redirect.regex.atoms[0].Str !! $_.regex.Str,
        directives => Nginx::Config::Return.new(
            value => $redirect.uri,
        ),
    );
}

subset ObsoleteDirective of Apache::Config::UnknownDirective
    where {
        $_.name ~~ /XSendFile/
        or $_.name eq 'RewriteEngine'
        or $_.data ~~ /zms_instance/
        or $_.name eq 'Alias' and .data ~~ /static/
        or $_.name eq 'ProxyPassReverse'
        or $_.name eq 'ProxyPreserveHost'
    };

multi method convert_directive(
    @directives where @directives[0] ~~ ObsoleteDirective
) {
    @directives.shift;
    return;
}

multi method convert_directive(
    @directives,
) {
    return Nginx::Config::Generic.new(content => @directives.shift.Str);
}

method convert(Str $config) {
    my $parser = Apache::Config::Parser.new;
    my $actions = Apache::Config::Actions.new;

    my @cms = $parser.parse(
        $config,
        :actions($actions),
    ).ast.virtual_hosts.grep(Apache::Config::VirtualHost);

    my Str $nginx_config = '';

    for @cms -> $cms {
        my @nginx_directives;
        my @directives = $cms.directives;
        my $*canonical_host;
        while @directives {
            push @nginx_directives, self.convert_directive(@directives);
        }

        if $*canonical_host and $*canonical_host eq $cms.name {
            $nginx_config ~= Nginx::Config::Server.new(
                names => $cms.aliases,
                directives => [
                    Nginx::Config::DomainRedirect.new,
                ],
            ).Str;
            $nginx_config ~= Nginx::Config::Server.new(
                names      => $*canonical_host,
                directives => @nginx_directives,
            ).Str;
        }
        else {
            $nginx_config ~= Nginx::Config::Server.new(
                names      => [$cms.name, $cms.aliases.list],
                directives => @nginx_directives,
            ).Str;
        }
    }

    return $nginx_config;
}

# vim: ft=perl6