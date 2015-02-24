class Apache::Config::Actions;

class Config {
    has $.virtual_hosts;
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

role CMS is export {
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

sub get_directive(@directives, Str $name) {
    return @directives.grep({ $_{$name}:exists })[0]{$name}.ast;
}

sub get_directives(@directives, Str $name) {
    return @directives.grep({ $_{$name}:exists })»{$name}».ast;
}

method TOP($/) {
    make Config.new(
        virtual_hosts => get_directives($<declaration>, 'virtual_host'),
    );
}

method virtual_host($/) {
    make VirtualHost.new(
        name => get_directive($<directive>, 'server_name'),
        aliases => [ get_directives($<directive>, 'server_alias').list ],
        directives => $<directive>».ast.grep({ $_ ~~ Directive }),
    );
    $/.ast does CMS if $/.ast.is_cms;
}

method directive($/) {
    make $/.values[0].ast;
}

method server_name($/) {
    make $<domain>.Str;
}

method server_alias($/) {
    make $<domain>».Str;
}

method error_document($/) {
    make ErrorDocument.new(
        status => $<http_status_code>.Str,
        uri    => $<uri>.ast,
    );
}

method rewrite_cond($/) {
    make RewriteCond.new(
        value   => $<value>.ast,
        regex   => $<regex>.ast,
        options => $<rewrite_options>.ast // '',
    );
}

method rewrite_rule($/) {
    make RewriteRule.new(
        regex       => $<regex>.ast,
        replacement => $<replacement>.ast,
        options     => $<rewrite_options>.ast // '',
    );
}

method redirect($/) {
    make Redirect.new(
        path => $<path>.Str,
        uri  => $<uri>.Str,
    );
}

method redirect_match($/) {
    make RedirectMatch.new(
        regex => $<regex>.ast,
        uri   => $<uri>.Str,
    );
}

method proxy_pass($/) {
    make ProxyPass.new(
        path => $<path>,
        uri  => $<uri>,
        options => $<proxy_pass_option>».ast,
    );
}

method proxy_pass_match($/) {
    make ProxyPassMatch.new(
        regex   => $<regex>.ast,
        uri     => $<uri>.ast,
        options => $<proxy_pass_option>».ast,
    );
}

method unknown_directive($/) {
    make UnknownDirective.new(
        name => $<name>.Str,
        data => $/.list[0].Str,
    );
}

method replacement($/) {
    make $/.Str;
}

method rewrite_options($/) {
    make $/.Str;
}

method uri($/) {
    make $/.Str;
}

method value($/) {
    make $/.Str;
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

method regex($/) {
    make Expression.new(
        begin_anchored => $<begin_anchor> ?? True !! False,
        atoms => $<regex_atom>».ast.grep(RegexAtom),
        end_anchored => $<end_anchor> ?? True !! False,
    );
}

method regex_atom($/) {
    make $/.hash.values[0].ast;
}

method regex_group($/) {
    make RegexGroup.new(
        atoms => $<regex_atom>».ast,
    );
}

method regex_literal($/) {
    make RegexLiteral.new(
        content => $/.Str,
    );
}

method regex_alternative($/) {
    make $/.hash.values[0].ast;
}

method regex_alternation($/) {
    make RegexAlternation.new(
        alternatives => $<regex_alternative>».ast,
    );
}

# vim: ft=perl6
