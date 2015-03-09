class Apache::Config::Actions;

use Apache::Config;

sub get_directive(@directives, Str $name) {
    return @directives.grep({ $_{$name}:exists })[0]{$name}.ast;
}

sub get_directives(@directives, Str $name) {
    return @directives.grep({ $_{$name}:exists })»{$name}».ast;
}

method TOP($/) {
    make Apache::Config.new(
        virtual_hosts => get_directives($<declaration>, 'virtual_host'),
    );
}

method virtual_host($/) {
    make Apache::Config::VirtualHost.new(
        name => get_directive($<directive>, 'server_name'),
        aliases => [ get_directives($<directive>, 'server_alias').list ],
        directives => $<directive>».ast.grep({ $_ ~~ Apache::Config::Directive }),
    );
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
    make Apache::Config::ErrorDocument.new(
        status => $<http_status_code>.Str,
        uri    => $<uri>.ast,
    );
}

method document_root($/) {
    make Apache::Config::DocumentRoot.new(
        path => $<path>.Str,
    );
}

method rewrite_cond($/) {
    make Apache::Config::RewriteCond.new(
        value   => $<value>.ast,
        regex   => $<regex>.ast,
        options => $<rewrite_options>.ast // '',
    );
}

method rewrite_rule($/) {
    make Apache::Config::RewriteRule.new(
        regex       => $<regex>.ast,
        replacement => $<replacement>.ast,
        options     => $<rewrite_options>.ast // '',
    );
}

method redirect($/) {
    make Apache::Config::Redirect.new(
        path => $<path>.Str,
        uri  => $<uri>.Str,
    );
}

method redirect_match($/) {
    make Apache::Config::RedirectMatch.new(
        regex => $<regex>.ast,
        uri   => $<uri>.Str,
    );
}

method proxy_pass($/) {
    make Apache::Config::ProxyPass.new(
        path => $<path>,
        uri  => $<uri>,
        options => $<proxy_pass_option>».ast,
    );
}

method proxy_pass_match($/) {
    make Apache::Config::ProxyPassMatch.new(
        regex   => $<regex>.ast,
        uri     => $<uri>.ast,
        options => $<proxy_pass_option>».ast,
    );
}

method expires_active($/) {
    make Apache::Config::ExpiresActive.new;
}

method expires_by_type($/) {
    make Apache::Config::ExpiresByType.new(
        mime_type => $<mime_type>.ast,
        string    => $<string>.ast,
    );
}

method unknown_directive($/) {
    make Apache::Config::UnknownDirective.new(
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

method mime_type($/) {
    make $/.Str;
}

method string($/) {
    make $/.Str;
}

method regex($/) {
    make Apache::Config::Expression.new(
        negated        => $<negator> ?? True !! False,
        begin_anchored => $<begin_anchor> ?? True !! False,
        atoms          => $<regex_atom>».ast.grep(Apache::Config::RegexAtom),
    );
}

method regex_atom($/) {
    make $/.hash.values[0].ast;
}

method regex_group($/) {
    make Apache::Config::RegexGroup.new(
        atoms => $<regex_atom>».ast,
    );
}

method regex_literal($/) {
    make Apache::Config::RegexLiteral.new(
        content => $/.Str,
    );
}

method regex_alternative($/) {
    make $/.hash.values[0].ast;
}

method regex_alternatives($/) {
    make [ $/.hash.values[0]».ast ];
}

method regex_alternation($/) {
    make Apache::Config::RegexAlternation.new(
        alternatives => $<regex_alternatives>».ast,
    );
}

method end_anchor($/) {
    make Apache::Config::RegexEndAnchor.new;
}

# vim: ft=perl6
