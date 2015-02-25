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
            "location $.op $.path \{\n"
            ~ (@.directives ?? @.directives».Str.join("\n").indent(8) ~ "\n" !! '')
            ~ '}';
    }
}

class Return {
    has $.value;

    method Str {
        return "return $.value;";
    }
}

# vim: ft=perl6
