use Test;

use Apache::Config::Converter::Nginx;

my $converter = Apache::Config::Converter::Nginx.new;

is($converter.convert('<VirtualHost *:80>
    DocumentRoot /srv/www/htdocs/void.atikon.at
    ServerName void.atikon.at
</VirtualHost>'), 'server {
        server_name void.atikon.at;

}
');
is($converter.convert('<VirtualHost *:80>
    DocumentRoot /srv/www/htdocs/void.atikon.at
    ServerName void.atikon.at

    RewriteCond %{HTTP_USER_AGENT} ip(hone|od)|android|windowssce|iemobile|windows\ ce;|avantgo|blackberry|blazer|elaine|hiptop|kindle|midp|mmp|o2|opera\ mini|palm(\ os)?|pda|plucker|pocket|psp|smartphone|symbian|treo|up\.(browser|link)|vodafone|wap|windows\ ce;\ (iemobile|ppc)|xiino [NC,OR]
    RewriteCond %{HTTP_COOKIE} version=mobile
    RewriteCond %{HTTP_COOKIE} !version=desktop
    RewriteCond %{REQUEST_URI} !^/common/pdf_magazin/
    RewriteRule ^(.*)/index_ger\.html$ $1/mobile_ger.html [R,L] 

</VirtualHost>'), 'server {
        server_name void.atikon.at;
        include stanzas/mobile_redirect.conf;
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
        error_page 404 /404.html;
        location = /news {
                    return /news.html;
        }

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

        location = / {
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

        #ProxyPassMatch ^/(?!error|icons|cgi-bin|htdig|statistik$|news$|facebook$|twitter$|impressum$|net$|(a|A)pp$|(a|A)pp$|sys_static|(a|A)pp$) http://0:8084/ connectiontimeout=20 timeout=900 retry=0 disablereuse=On
        #RewriteCond %{HTTP_USER_AGENT} AppWebView [NC]
        #RewriteRule ^(.*)/index_ger\.html(.*) $1/app_ger.html$2 [R,NE,L]
        include stanzas/mobile_redirect.conf;
}
');

done;

# vim: ft=perl6