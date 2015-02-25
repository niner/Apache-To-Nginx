use Apache::Config::Converter::Nginx;

my $converter = Apache::Config::Converter::Nginx.new;
say $converter.convert("virtual_hosts.conf".IO.slurp(enc => "latin-1"));

# vim: ft=perl6
