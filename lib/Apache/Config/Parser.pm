#use Grammar::Debugger;
grammar Apache::Config::Parser;

token ws { <!ww> \h* }
rule TOP {
    <declaration>+
}
rule declaration {
    <virtual_host>
    | <directive>
}
rule virtual_host {
    '<VirtualHost *:80>' \s*
    <directive>* \s*
    '</VirtualHost>' \s*
}
rule directive {
    <comment> \n\s*
    | <block>
    | <server_name> \n\s*
    | <server_alias> \n\s*
    | <document_root> \n\s*
    | <error_document> \n\s*
    | <rewrite_cond> \n\s*
    | <rewrite_rule> \n\s*
    | <redirect> \n\s*
    | <redirect_match> \n\s*
    | <proxy_pass> \n\s*
    | <proxy_pass_match> \n\s*
    | <expires_active> \n\s*
    | <expires_by_type> \n\s*
    | <unknown_directive> \n\s*
}
rule block {
    <unknown_block>
}
rule server_name {
    ServerName <domain>
}
rule server_alias {
    ServerAlias <domain> *
}
rule document_root {
    DocumentRoot <path>
}
rule error_document {
    ErrorDocument <http_status_code> <uri>
}
rule rewrite_cond {
    RewriteCond <value> <regex> <rewrite_options>?
}
rule rewrite_rule {
    RewriteRule <regex> <replacement> <rewrite_options>?
}
rule redirect {
    Redirect <path> <uri>
}
rule redirect_match {
    RedirectMatch <regex> <uri>
}
rule proxy_pass {
    ProxyPass <path> <uri> <proxy_pass_option> *
}
rule proxy_pass_match {
    ProxyPassMatch <regex> <uri> <proxy_pass_option> *
}
rule expires_active {
    ExpiresActive On
}
rule expires_by_type {
    ExpiresByType <mime_type> <string>
}
rule unknown_directive {
    <name> (\N+)
}
rule unknown_block {
    '<' <!before VirtualHost>(<name>) <string> '>' \s*
    <directive>*
    '</' $0 '>' \s*
}
token comment {
    \s* '#' \N*
}
token name {
    \w+
}
token domain {
    [<[\w-]>+ | \*] [\. <[\w-]>+]*
}
token string {
    \" <-[ " ]>* \"
    | \' <-[ ' ]>* \'
    | <-[ "'> ]>+
}
token path {
    <[\w\./-]>+
}
token value {
    \S+
}
token replacement {
    \S+
}
token uri {
    \S+
}
token http_status_code {
    \d+
}
token mime_type {
    'image/gif'
    | 'image/png'
    | 'image/jpeg'
    | 'image/x-icon'
    | 'text/css'
    | 'text/javascript'
    | 'text/x-c'
    | 'text/x-js'
    | 'application/x-javascript'
    | 'application/x-shockwave-flash'
}
token rewrite_options {
    '[' <rewrite_option> [','<rewrite_option>]* ']'
}
token rewrite_option{
    \w+(\=\w+)?
}
token proxy_pass_option {
    \w+\=\w+
}
token regex {
    # ^/(?!error|icons|cgi-bin|htdig|statistik\$|news\$|facebook\$|twitter\$|impressum\$|net\$|(a|A)pp\$|(a|A)pp\$|sys_static|(a|A)pp\$)
    <negator>?
    <begin_anchor>?
    <regex_atom>*
}
token negator {
    '!'
}
token begin_anchor {
    '^'
}
token end_anchor {
    '$'
}
token regex_atom {
    <regex_alternation>
    | <regex_group>
    | <regex_literal>
    | <end_anchor>
}
token regex_group {
    '('
    '?!'?
    <regex_atom>+
    ')'
}
token regex_alternative {
    <regex_group>
    | <regex_literal>
    | <end_anchor>
}
token regex_alternatives {
    <regex_alternative>+
}
token regex_alternation {
    <regex_alternatives>
    [
        '|'
        <regex_alternatives>
    ]+
}
token regex_literal {
    [ <-[ \s \( \) \| \$ ]> | '\$' | \\ \s ]+
}

# vim: ft=perl6
