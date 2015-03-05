use Test;

use Apache::Config::Converter::Nginx;

my $converter = Apache::Config::Converter::Nginx.new;

is($converter.convert('<VirtualHost *:80>
    DocumentRoot /srv/www/htdocs/void.atikon.at
    ServerName void.atikon.at
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        root /srv/www/htdocs/void.atikon.at;
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at

    RewriteCond %{HTTP_USER_AGENT} ip(hone|od)|android|windowssce|iemobile|windows\ ce;|avantgo|blackberry|blazer|elaine|hiptop|kindle|midp|mmp|o2|opera\ mini|palm(\ os)?|pda|plucker|pocket|psp|smartphone|symbian|treo|up\.(browser|link)|vodafone|wap|windows\ ce;\ (iemobile|ppc)|xiino [NC,OR]
    RewriteCond %{HTTP_COOKIE} version=mobile
    RewriteCond %{HTTP_COOKIE} !version=desktop
    RewriteCond %{REQUEST_URI} !^/common/pdf_magazin/
    RewriteRule ^(.*)/index_ger\.html$ $1/mobile_ger.html [R,L] 

</VirtualHost>'), 'server {
        server_name void.atikon.at;
        include stanzas/mobile_redirect.conf;
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at
    RedirectMatch /news$ /news.html
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at
    RewriteRule ^/foo/bar$ /content/foo/bar [R=301,L]
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        location = /foo/bar {
                return /content/foo/bar;
        }
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at
    RewriteRule ^/global/site/leist_steuerberatung.html /content/steuerberater_wirtschaftspruefer/leistungen/steuerberater_rosenheim/index.html [R=301,L]
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        location ~ ^/global/site/leist_steuerberatung.html {
                return /content/steuerberater_wirtschaftspruefer/leistungen/steuerberater_rosenheim/index.html;
        }
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at
    RewriteRule ^/foo/bar$ /content/foo/bar
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        rewrite "^/foo/bar$" /content/foo/bar;
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at
    RewriteCond %{HTTP_USER_AGENT} FooBar [NC]
    RewriteRule ^(.*)/index.html(.*) $1/app_ger.html$2 [R]
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        if ($http_user_agent ~* "FooBar") {
                rewrite "^(.*)/index.html(.*)" $1/app_ger.html$2 redirect;
        }
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at
    RewriteCond %{HTTP_USER_AGENT} AppWebView [NC]
    RewriteRule ^(.*)/index.html(.*) $1/app_ger.html$2 [R]
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        include stanzas/app_web_view_redirect.conf;
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at
    RewriteCond %{HTTP_USER_AGENT} AppWebView [NC]
    RewriteRule ^(.*)/index.html(.*) $1/app_ger.html$2 [R,NE,L]
    RewriteCond %{HTTP_USER_AGENT} AppWebView [NC]
    RewriteRule ^(.*)/$ $1/app_ger.html$2 [R,NE,L]
    RewriteCond %{HTTP_USER_AGENT} AppWebView [NC]
    RewriteCond %{DOCUMENT_ROOT}%{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)/app(.*).html$ $1/mobile$2.html [R=301,L]
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        include stanzas/app_web_view_redirect.conf;
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at
    RewriteCond %{HTTP_USER_AGENT} InApp [NC,OR]
    RewriteCond %{HTTP_COOKIE} version=mobile
    RewriteCond %{HTTP_COOKIE} !version=desktop
    RewriteRule ^\/(.*)(\/|\/index\.html)$ $1\/mobile_ger.html [R=301,L]
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        include stanzas/in_app_redirect.conf;
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
    ServerName void.atikon.at
    ProxyPassMatch ^/(?!error|icons|cgi-bin|htdig|statistik$|news$|sys_static) http://0:8084/ connectiontimeout=20 timeout=900 retry=0 disablereuse=On
</VirtualHost>'), 'server {
        server_name void.atikon.at;
        include stanzas/cms.conf;
        location ~ ^/(news$) {
        }
        include stanzas/standard_directives.conf;
}
');
is($converter.convert('<VirtualHost *:80>
	ServerName void.atikon.at
        ServerAlias nix.atikon.at www.void.atikon.at

	RewriteCond %{HTTP_HOST} !void.atikon.at$
	RewriteRule ^(.*)$ http://void.atikon.at$1 [R=301,L]
</VirtualHost>
'), 'server {
        server_name nix.atikon.at, www.void.atikon.at;
        include stanzas/domain_redirect.conf;
}
server {
        server_name void.atikon.at;
        include stanzas/standard_directives.conf;
}
');

is($converter.convert('<VirtualHost *:80>
	ServerName www.haubner-stb.de
	ServerAlias haubner-stb.de
	DocumentRoot /srv/www/htdocs/kunden/haubner-stb.de
	ErrorDocument 404 /404.html
	<FilesMatch "\.(pdf|doc|xls|ppt|vcf)$">
		Header add "Content-Disposition" "attachment"
	</FilesMatch>
	<FilesMatch "\.(ico|flv|jpe?g|png|gif|js|css|swf)$">
		#Static files expires after 30 days in Browser-Cache
		Header set Cache-Control "max-age=2592000, must-revalidate"
	</FilesMatch>
	RedirectMatch /statistik$ http://www.haubner-stb.de/cgi-bin/awstats.pl?config=haubner-stb.de
	RedirectMatch /news$ /news.html
        RedirectMatch /facebook$ https://www.facebook.com/pages/Haubner-Schäfer-Partner/190673467622036
        RedirectMatch /twitter$ https://twitter.com/haubner_stb
        RedirectMatch /impressum$ /content/inhalte/kanzlei/impressum/index_ger.html
        RedirectMatch /net$ /content/inhalte/kanzlei/kanzlei_im_netz/index_ger.html
        RedirectMatch /(a|A)pp$ /content/inhalte/kanzlei/kanzlei_app/index_ger.html

	RequestHeader set zms_instance haubner-stb.de
	XSendFile on
	XSendFilePath /data/shared-web/srv/www/cgi-bin/ZMS/root/static/instances/haubner-stb.de
	Alias /static /srv/www/cgi-bin/ZMS/root/static/instances/haubner-stb.de
	Alias /sys_static /srv/www/cgi-bin/ZMS/root/static
	ProxyPreserveHost On
	ProxyPass /facebook !
	ProxyPass /news !
	ProxyPass /twitter !
	ProxyPass /impressum !
	ProxyPass /net !
	ProxyPass /app !
	ProxyPass /App !
	ProxyPassMatch ^/static(?!/content)/(.*) !
	ProxyPassMatch ^/(?!error|icons|cgi-bin|htdig|statistik$|news$|facebook$|twitter$|impressum$|net$|(a|A)pp$|(a|A)pp$|sys_static|(a|A)pp$) http://0:8084/ connectiontimeout=20 timeout=900 retry=0 disablereuse=On
	ProxyPassReverse / http://0:8084/

	RewriteEngine On

	#Redirect on App
        RewriteCond %{HTTP_USER_AGENT} AppWebView [NC]
	RewriteRule ^(.*)/index_ger\.html(.*) $1/app_ger.html$2 [R,NE,L]

	#Redirect on mobile Browser
        RewriteCond %{HTTP_USER_AGENT} ip(hone|od)|android|windowssce|iemobile|windows\ ce;|avantgo|blackberry|blazer|elaine|hiptop|kindle|midp|mmp|o2|opera\ mini|palm(\ os)?|pda|plucker|pocket|psp|smartphone|symbian|treo|up\.(browser|link)|vodafone|wap|windows\ ce;\ (iemobile|ppc)|xiino [NC,OR]
        RewriteCond %{HTTP_COOKIE} version=mobile
        RewriteCond %{HTTP_COOKIE} !version=desktop
        RewriteCond %{REQUEST_URI} !^/common/pdf_magazin/
        RewriteRule ^(.*)/index_ger\.html$ $1/mobile_ger.html [R,L] 

	RewriteCond %{HTTP_HOST} !www.haubner-stb.de$
	RewriteRule ^(.*)$ http://www.haubner-stb.de$1 [R=301,L]
</VirtualHost>
'), 'server {
        server_name haubner-stb.de;
        include stanzas/domain_redirect.conf;
}
server {
        server_name www.haubner-stb.de;
        root /srv/www/htdocs/kunden/haubner-stb.de;
        location = /facebook {
                return https://www.facebook.com/pages/Haubner-Schäfer-Partner/190673467622036;
        }
        location = /twitter {
                return https://twitter.com/haubner_stb;
        }
        location = /impressum {
                return /content/inhalte/kanzlei/impressum/index_ger.html;
        }
        location = /net {
                return /content/inhalte/kanzlei/kanzlei_im_netz/index_ger.html;
        }
        location ~ /(a|A)pp$ {
                return /content/inhalte/kanzlei/kanzlei_app/index_ger.html;
        }
        location  /facebook {
        }
        location  /news {
        }
        location  /twitter {
        }
        location  /impressum {
        }
        location  /net {
        }
        location  /app {
        }
        location  /App {
        }
        include stanzas/cms.conf;
        location ~ ^/(news$|facebook$|twitter$|impressum$|net$|(a|A)pp$|(a|A)pp$|(a|A)pp$) {
        }
        include stanzas/app_web_view_redirect.conf;
        include stanzas/mobile_redirect.conf;
        include stanzas/standard_directives.conf;
}
');

done;

# vim: ft=perl6
