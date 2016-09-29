unit class Apache::Config::Converter::Nginx;

use Apache::Config::Parser;
use Apache::Config::Actions;
use Nginx::Config;

my %variable_map = (
    '%{HTTP_USER_AGENT}' => '$http_user_agent',
    '%{HTTP_HOST}'       => '$host',
    '%{QUERY_STRING}'    => '$query_string',
    '%{SERVER_NAME}'     => '$server_name',
);
sub replace_variables(Str $string is copy) {
    for %variable_map.kv -> $k, $v {
        $string.=subst($k, $v);
    }
    return $string;
}

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
    %*vhost<canonical_host> = @directives[0].canonical_host;
    shift @directives;
    shift @directives;
    return;
}

# DocumentRoot /srv/www/htdocs/void.atikon.at

multi method convert_directive(
    @directives where @directives[0] ~~ Apache::Config::DocumentRoot
) {
    my $document_root = @directives.shift;
    return Nginx::Config::Root.new(
        path => $document_root.path,
    );
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
    return if %*vhost<mobile_redirect>;
    %*vhost<mobile_redirect> = True;
    return Nginx::Config::MobileRedirect.new;
}

#RewriteCond %{HTTP_USER_AGENT} AppWebView [NC]
#RewriteRule ^(.*)/index.html(.*) $1/app_ger.html$2 [R]

subset AppWebViewCondition of Apache::Config::RewriteCond
    where {$_.value eq '%{HTTP_USER_AGENT}' and $_.regex eq 'AppWebView'};

multi method convert_directive(
    @directives where @directives[0] ~~ AppWebViewCondition
) {
    True until @directives.shift ~~ Apache::Config::RewriteRule;
    return if %*vhost<app_web_view>;
    %*vhost<app_web_view> = True;
    return Nginx::Config::AppWebViewRedirect.new;
}

#RewriteCond %{HTTP_USER_AGENT} InApp [NC,OR]
#RewriteCond %{HTTP_COOKIE} version=mobile
#RewriteCond %{HTTP_COOKIE} !version=desktop
#RewriteRule ^\/(.*)(\/|\/index\.html)$ $1\/mobile_ger.html [R=301,L]

subset InAppCondition of Apache::Config::RewriteCond
    where {$_.value eq '%{HTTP_USER_AGENT}' and $_.regex eq 'InApp'};

multi method convert_directive(
    @directives where @directives[0] ~~ InAppCondition
) {
    True until @directives.shift ~~ Apache::Config::RewriteRule;
    return Nginx::Config::InAppRedirect.new;
}

multi method convert_directive(
    @directives where @directives[0] ~~ Apache::Config::ErrorDocument
) {
    my $error_page = @directives.shift;

    # handeled by standard_directives.conf:
    return if $error_page.status == 404 and $error_page.uri eq '/404.html';

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
    for <error icons cgi-bin htdig statistik statistik$ statistik\$ sys_static>, 'statistik $' -> $obsolete {
        my $i = $alternatives.first-index({$_.Str eq $obsolete});
        $alternatives.splice($i, 1) if defined $i;
    }
    return
        Nginx::Config::CMS.new,
        Nginx::Config::Location.new(op => '~', path => $directive.regex.Str);
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
    return Nginx::Config::Location.new(
        path       => $redirect.path,
        directives => Nginx::Config::Return.new(
            value => replace_variables($redirect.uri),
        ),
    )
}

#RedirectMatch /news$ /news.html

multi method convert_directive(
    @directives where (
        @directives[0] ~~ Apache::Config::RedirectMatch
        and @directives[0].regex.Str eq '/news$'
        and @directives[0].uri eq '/news.html'
    )
) {
    @directives.shift;
    return; # handled by standard_directives.conf
}

multi method convert_directive(
    @directives where @directives[0] ~~ Apache::Config::RedirectMatch
) {
    my $redirect = @directives.shift;
    return if $redirect.regex.atoms[0].Str eq '/statistik'; # already handled by include
    return Nginx::Config::Location.new(
        op         => $redirect.regex.is_exact_string_match ?? '=' !! '~',
        path       => $redirect.regex.is_exact_string_match
            ?? $redirect.regex.atoms[0].Str
            !! $redirect.regex.Str,
        directives => Nginx::Config::Return.new(
            value => replace_variables($redirect.uri),
        ),
    );
}

#RewriteRule ^/archiv/newsarchiv.html$ /steuerberater/news/index.html [R=301,L]

subset RewriteExactRedirect of Apache::Config::RewriteRule
    where {
        $_.regex.is_exact_string_match
        and $_.is_redirect
    };

multi method convert_directive(
    @directives where { not %*vhost<if_block> and @directives[0] ~~ RewriteExactRedirect }
) {
    my $redirect = @directives.shift;
    return Nginx::Config::Location.new(
        op         => '=',
        path       => $redirect.regex.atoms[0].Str,
        directives => Nginx::Config::Return.new(
            value => replace_variables($redirect.replacement),
        ),
    );
}

subset RewriteRedirect of Apache::Config::RewriteRule where *.is_redirect;

multi method convert_directive(
    @directives where { not %*vhost<if_block> and @directives[0] ~~ RewriteRedirect }
) {
    my $redirect = @directives.shift;
    return Nginx::Config::Location.new(
        op         => '~',
        path       => $redirect.regex.Str,
        directives => Nginx::Config::Return.new(
            value => replace_variables($redirect.replacement),
        ),
    );
}

multi method convert_directive(
    @directives where {
        @directives[0] ~~ Apache::Config::RewriteRule
        and @directives[0].replacement !~~ /\%\{REQUEST_URI\}/
    }
) {
    my $rewrite = @directives.shift;
    return Nginx::Config::Rewrite.new(
        regex       => $rewrite.regex.Str,
        replacement => replace_variables($rewrite.replacement),
        redirect    => $rewrite.is_redirect,
    );
}

multi method convert_directive(
    @directives where {
        not %*vhost<if_block>
        and @directives[0] ~~ Apache::Config::RewriteCond
        and %variable_map{@directives[0].value.Str}:exists
    }
) {
    my $cond = @directives.shift;
    %*vhost<if_block> = True;
    my @sub = self.convert_directive(@directives);
    %*vhost<if_block> = False;
    return Nginx::Config::If.new(
        variable   => %variable_map{$cond.value.Str},
        op         => ($cond.regex.negated ?? '!' !! '') ~ ($cond.is_case_sensitive ?? '~' !! '~*'),
        value      => $cond.regex.Str,
        directives => @sub,
    );
}

subset CachingHeader of Apache::Config::UnknownDirective
    where {
        .name eq 'Header'
        and .data eq 'append Cache-Control "public, must-revalidate"'
    };

multi method convert_directive(
    @directives where @directives[0] ~~ Apache::Config::ExpiresActive
) {
    @directives.shift
        while @directives[0] ~~ Apache::Config::ExpiresActive|Apache::Config::ExpiresByType|CachingHeader;
    return Nginx::Config::CachingDirectives.new;
}

subset ObsoleteDirective of Apache::Config::UnknownDirective
    where {
        .name ~~ /XSendFile/
        or .name eq 'RewriteEngine'
        or .data ~~ /zms_instance/
        or .name eq 'Alias' and .data ~~ /static/
        or .name eq 'ProxyPassReverse'
        or .name eq 'ProxyPreserveHost'
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
        my %*vhost;
        while @directives {
            push @nginx_directives, self.convert_directive(@directives);
        }
        push @nginx_directives, Nginx::Config::StandardDirectives.new;

        if %*vhost<canonical_host> and %*vhost<canonical_host> eq $cms.name {
            $nginx_config ~= Nginx::Config::Server.new(
                names => $cms.aliases,
                directives => [
                    Nginx::Config::DomainRedirect.new,
                ],
            ).Str;
            $nginx_config ~= Nginx::Config::Server.new(
                names      => %*vhost<canonical_host>,
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
