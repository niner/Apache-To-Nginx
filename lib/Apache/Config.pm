class Apache::Config;

has $.virtual_hosts;

method Str() {
    return $.virtual_hosts».Str.join("\n");
}

class Domain {
    has $.name;
}

class Directive {
}

class ErrorDocument is Directive {
    has $.status;
    has $.uri;

    method Str() {
        return "ErrorDocument $.status $.uri";
    }
}

class RewriteCond is Directive {
    has $.value;
    has $.regex;
    has $.options = '';

    method canonical_host() {
        return unless $.value eq '%{HTTP_HOST}';
        return unless $.regex.negated;
        return unless $.regex ~~ /^(.*)\$$/;
        return $0.Str.subst(/\\/, '');
    }

    method is_case_sensitive() {
        return ($.options !~~ /<wb>NC<wb>/).Bool;
    }

    method Str() {
        return 'RewriteCond ' ~ ($.value.Str, $.regex.Str, $.options.Str).grep(/\S/).join(' ');
    }
}

class RewriteRule is Directive {
    has $.regex;
    has $.replacement;
    has $.options = '';

    method is_redirect() {
        return ($.options ~~ /<wb>R<wb>\=?/).Bool;
    }

    method Str() {
        return 'RewriteRule ' ~ ($.regex.Str, $.replacement.Str, $.options.Str).join(' ');
    }
}

class Redirect is Directive {
    has $.path;
    has $.uri;

    method Str() {
        return "Redirect $.path $.uri";
    }
}

class RedirectMatch is Directive {
    has $.regex;
    has $.uri;

    method Str() {
        return "RedirectMatch { $.regex.perl } $.uri";
    }
}

class ProxyPass is Directive {
    has $.path;
    has $.uri;
    has $.options = '';

    method Str() {
        return 'ProxyPass ' ~ $.path.Str ~ ' ' ~ $.uri.Str ~ ' ' ~ ($.options // '').Str;
    }
}

class ProxyPassMatch is Directive {
    has $.regex;
    has $.uri;
    has $.options = '';

    method is_cms() {
        return $!uri eq 'http://0:8084/';
    }

    method Str() {
        return 'ProxyPassMatch ' ~ $.regex.Str ~ ' ' ~ $.uri.Str ~ ' ' ~ $.options.Str;
    }
}

class ExpiresActive is Directive {
    method Str() {
        return 'ExpiresActive On';
    }
}

class ExpiresByType is Directive {
    has Str $.mime_type;
    has Str $.string;

    method Str() {
        return "ExpiresByType $.mime_type $.string";
    }
}

class DocumentRoot is Directive {
    has $.path;

    method Str() {
        return "DocumentRoot $.path";
    }
}

class UnknownDirective is Directive {
    has $.name;
    has $.data;

    method Str() {
        return "$.name $.data";
    }
}

class VirtualHost {
    has $.name;
    has @.aliases;
    has @.directives is rw;

    method is_cms() {
        return @.directives.grep(ProxyPassMatch).first(*.is_cms);
    }

    method redirects_to_canonical_domain {
    }

    method Str() {
        return "<VirtualHost *:80>\n" ~ @.directives».Str.join("\n").indent(8) ~ "\n</VirtualHost>";
    }
}

class RegexAtom {
}
class RegexGroup is RegexAtom {
    has RegexAtom @.atoms;
    method Str() {
        return '(' ~ @.atoms».Str.join('') ~ ')';
    }
}
class RegexAlternation is RegexAtom {
    has @.alternatives;
    method Str() {
        return @.alternatives.map(*».Str.join(''))».Str.join('|');
    }
}
class RegexLiteral is RegexAtom {
    has Str $.content;
    method Str() {
        return $.content;
    }
}
class RegexEndAnchor is RegexAtom {
    method Str() {
        return '$';
    }
}
class Expression {
    has Bool $.begin_anchored = False;
    has Bool $.negated = False;
    has RegexAtom @.atoms;

    method is_exact_string_match() {
        return (
            self.atoms.elems == 2
            and self.atoms[0] ~~ RegexLiteral
            and self.atoms[1] ~~ RegexEndAnchor
        )
    }

    method Str() {
        return ($.begin_anchored ?? '^' !! '') ~ @.atoms».Str.join('');
    }
}

# vim: ft=perl6
