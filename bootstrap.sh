#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='php'
PROJECTFOLDER='project'

# create project folder
sudo mkdir "/var/www/html/${PROJECTFOLDER}"

sudo apt-get update && sudo apt-get install python-software-properties
sudo add-apt-repository ppa:ondrej/php5-5.6
sudo add-apt-repository ppa:chris-lea/node.js 

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install nginx 1.4.6 and php 5.6
sudo apt-get install -y nginx
sudo apt-get install -y php5-fpm
sudo apt-get install -y php5-memcached 
sudo apt-get install -y memcached
sudo apt-get install -y php5-memcache
sudo apt-get install -y php5-curl

# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
sudo apt-get install -y php5-mysql
sudo apt-get install -y php5-xdebug

# install phpmyadmin and give password(s) to installer
# for simplicity I'm using the same password for mysql and phpmyadmin
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
sudo apt-get -y install phpmyadmin


# setup hosts file
VHOST=$(cat <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    root /var/www/html/${PROJECTFOLDER};
    index index.php index.html index.htm;

    server_name php.local.com;

    location / {
        try_files \$uri \$uri/ =404;
    }

    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html/${PROJECTFOLDER};
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location /phpmyadmin {
        root /usr/share/;
        index index.php index.html index.htm;
        location ~ ^/phpmyadmin/(.+\.php)$ {
            try_files \$uri =404;
            root /usr/share/;
            fastcgi_pass unix:/var/run/php5-fpm.sock; # or 127.0.0.1:9000
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include /etc/nginx/fastcgi_params;
        }

        location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
            root /usr/share/;
        }
    }

    location /phpMyAdmin {
        rewrite ^/* /phpmyadmin last;
    }
}
EOF
)
echo "${VHOST}" > /etc/nginx/sites-available/default


# config php.ini
sed -i '/upload_max_filesize/s/= *2M/= 400M/' /etc/php5/fpm/php.ini
sed -i '/post_max_size/s/= *8M/= 400M/' /etc/php5/fpm/php.ini
#sed -i '/zlib.output_compression/s/= *Off/= On/' /etc/php5/fpm/php.ini
sed -i '/max_execution_time/s/= *30/= 60/' /etc/php5/fpm/php.ini
sed -i '/display_errors/s/= *Off/= On/' /etc/php5/fpm/php.ini
sed -i '/cgi.fix_pathinfo/s/= *1/= 0/' /etc/php5/fpm/php.ini
sed -i '/^;cgi.fix_pathinfo/s/^;//' /etc/php5/fpm/php.ini

# restart nginx
sudo service nginx restart
sudo service php5-fpm restart

# install git
sudo apt-get -y install git

# install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# install wp-cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

#install phpunit
wget https://phar.phpunit.de/phpunit.phar
chmod +x phpunit.phar
sudo mv phpunit.phar /usr/local/bin/phpunit

# Setup DB
#sudo mysql -u "root" "-p$PASSWORD" < "/var/www/html/databases/db.sql"
