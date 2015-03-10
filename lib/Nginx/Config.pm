class Nginx::Config;

class Server {
    has @.names;
    has @.directives;

    method Str {
        return qq:heredoc/CONFIG/;
            server \{
                    server_name { @.names.join(', ') };
            { @.directives».Str.join("\n").indent(8) }
            \}
            CONFIG
    }
}

class ErrorPage {
    has $.status;
    has $.uri;
    
    method Str {
        return "error_page $.status $.uri;";
    }
}

class Root {
    has $.path;

    method Str {
        return "root $.path;";
    }
}

class CMS {
    method Str {
        return 'include stanzas/cms.conf;';
    }
}

class DomainRedirect {
    method Str {
        return 'include stanzas/domain_redirect.conf;';
    }
}

class MobileRedirect {
    method Str {
        return 'include stanzas/mobile_redirect.conf;';
    }
}

class AppWebViewRedirect {
    method Str {
        return 'include stanzas/app_web_view_redirect.conf;';
    }
}

class InAppRedirect {
    method Str {
        return 'include stanzas/in_app_redirect.conf;';
    }
}

class CachingDirectives {
    method Str {
        return 'include stanzas/caching.conf;';
    }
}

class StandardDirectives {
    method Str {
        return 'include stanzas/standard_directives.conf;';
    }
}

class Generic {
    has $.content;

    method Str {
        return '#' ~ $.content;
    }
}

class Location {
    has $.path;
    has $.op = '';
    has @.directives;

    method Str {
        return
            qq[location $.op "$.path" \{\n]
            ~ (@.directives ?? @.directives».Str.join("\n").indent(8) ~ "\n" !! '')
            ~ '}';
    }
}

class Return {
    has $.value;

    method Str {
        return "return $.value;" if $.value ~~ /^http/;
        return "return \$scheme://\$host$.value;" if $.value ~~ m!^\/!;
        return "return \$scheme://\$host/$.value;";
    }
}

class Rewrite {
    has $.regex;
    has $.replacement;
    has Bool $.redirect = False;

    method Str {
        return qq/rewrite "$.regex" $.replacement/ ~ ($.redirect ?? ' redirect' !! '') ~ ';';
    }
}

class If {
    has $.variable;
    has $.op;
    has $.value;
    has @.directives;

    method Str {
        return
            qq/if ($.variable $.op "$.value") \{\n/
            ~ (@.directives ?? @.directives».Str.join("\n").indent(8) ~ "\n" !! '')
            ~ '}';
    }
}

# vim: ft=perl6
