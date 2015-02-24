use Apache::Config::Parser;
use Apache::Config::Actions;
my $parser = Apache::Config::Parser.new;
my $actions = Apache::Config::Actions.new;
say $parser.parse("<VirtualHost *:80> ProxyPassMatch ^/(?!error|icons|cgi-bin|(a|A)app\$) http://0:8084/\n</VirtualHost>\n", :actions($actions)).ast.perl;
