class Apache::Config;

has $.virtual_hosts;

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
        return unless $.regex ~~ /^\!(.*)\$$/;
        return $0.Str.subst(/\\/, '');
    }

    method Str() {
        return 'RewriteCond ' ~ ($.value.Str, $.regex.Str, $.options.Str).join(' ');
    }
}

class RewriteRule is Directive {
    has $.regex;
    has $.replacement;
    has $.options = '';

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
        return 'ProxyPass ' ~ $.path.Str ~ ' ' ~ $.uri.Str ~ ' ' ~ $.options.Str;
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
    has RegexAtom @.alternatives;
    method Str() {
        return @.alternatives».Str.join('|');
    }
}
class RegexLiteral is RegexAtom {
    has Str $.content;
    method Str() {
        return $.content;
    }
}
class Expression {
    has Bool $.begin_anchored = False;
    has Bool $.end_anchored = False;
    has RegexAtom @.atoms;

    method Str() {
        return ($.begin_anchored ?? '^' !! '') ~ @.atoms».Str.join('') ~ ($.end_anchored ?? '$' !! '');
    }
}

# vim: ft=perl6
