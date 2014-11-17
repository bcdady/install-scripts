#!/bin/bash

PS3='Package Manager to use : '
options=("apt-get" "aptitude")
select opt in "${options[@]}"
do
    case $opt in
        "apt-get")
            aptbin=apt-get
            break;;
        "aptitude")
            aptbin=aptitude
            break;;
        *)
        echo invalid option
        break;;
    esac
done

PS3='SQL DB to use (default "MySQL 5.5"): '
options=("MySQL 5.5" "MySQL 5.6" "MySQL 5.7" "MariaDB 5.5" "MariaDB 10.0")
select opt in "${options[@]}"
do
    case $opt in
        "MySQL 5.5")
            sqldb='mysql'
            sudo add-apt-repository ppa:ondrej/mysql-5.5
            break;;
        "MySQL 5.6")
            sqldb='mysql'
            sudo add-apt-repository ppa:ondrej/mysql-5.6
            break;;
        "MySQL 5.7")
            sqldb='mysql'
            sudo add-apt-repository -y ppa:ondrej/mysql-5.7
            break;;
        "MariaDB 5.5")
            sqldb='mariadb'
            sudo $aptbin -y install software-properties-common
            sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
            sudo add-apt-repository 'deb http://mirrors.linsrv.net/mariadb/repo/5.5/ubuntu saucy main'
            break;;
        "MariaDB 10.0")
            sqldb='mariadb'
            sudo $aptbint -y install software-properties-common
            sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
            sudo add-apt-repository 'deb http://mirrors.linsrv.net/mariadb/repo/10.0/ubuntu saucy main'
            break;;
        *)
            sqldb='mysql'
            break;;
    esac
done

# Latest PHP5
sudo add-apt-repository ppa:ondrej/php5

sudo $aptbin -y update 
sudo $aptbin -y dist-upgrade 

case $sqldb in
    "mysql")
        sudo $aptbin -y install mysql-client mysql-server libmysqlclient-dev 
        break;;
    "mariadb")
        sudo $aptbin -y install mariadb-client mariadb-server libmariadbclient-dev
        break;;
    *)
    break;;
esac

sudo $aptbin -y install curl postfix
sudo $aptbin -y install apache2-mpm-worker apache2-utils libapache2-mod-fastcgi apache2-threaded-dev
sudo $aptbin -y install php5 php-apc php-pear php5-cgi php5-cli php5-fpm php5-dev php5-curl php5-gd php5-imagick php5-imap php5-intl php5-mcrypt php5-sqlite php5-xdebug php5-xmlrpc php5-xsl imagemagick libmagickcore-dev libmagickwand-dev
sudo $aptbin -y install php5-mysql 
#sudo $aptbin -y install postgresql libpq-dev
#sudo $aptbin -y install php5-pgsql

# Configure Apache and fastcgi for php fpm
sudo cp -R assets/etc/apache2/sites-available/* /etc/apache2/sites-available/
sudo cp -R assets/etc/apache2/conf.d/* /etc/apache2/conf.d/
sudo cp -R assets/etc/php5/fpm/pool.d/* /etc/php5/fpm/pool.d/
sudo cp -R assets/var/www/* /var/www/

sudo sed -i '/ServerRoot \"\/etc\/apache2\"/ aServerName workstation.local' /etc/apache2/apache2.conf
# fastcgi and php fpm
sudo a2enmod actions alias fastcgi headers vhost_alias rewrite env expires deflate
sudo service apache2 restart
sudo service php5-fpm restart

# DB Admins
sudo $aptbin -y install phpmyadmin
#sudo $aptbin -y install phppgadmin

# configure PHP
for app in cli cgi fpm
do
    sudo sed -i 's|;\(date.timezone =\)|\1 Europe\/Paris|' /etc/php5/$app/php.ini
    sudo sed -i 's/^\(error_reporting =\).*$/\1 E_ALL | E_STRICT/' /etc/php5/$app/php.ini 
    sudo sed -i 's/^\(display_errors =\).*$/\1 On/' /etc/php5/$app/php.ini 
done

for app in cgi fpm
do
    sudo sed -i 's/^\(memory_limit =\).*$/\1 128M/' /etc/php5/$app/php.ini 
    sudo sed -i 's/^\(html_errors =\).*$/\1 On/' /etc/php5/$app/php.ini 
done

sudo $aptbin -y install apache2-mpm-worker apache2-threaded-dev 
sudo $aptbin -y remove libapache2-mod-php5 apache2-mpm-prefork

# configure mysql
sudo sed -i "/\[mysqld\]/ a\
# encoding and storage engine\n\
default-storage-engine=INNODB\n\
init-connect='SET NAMES utf8'\n\
# mysql 5.1\n\
#default-character-set=utf8\n\
#default-collation=utf8_unicode_ci\n\
\n\
#mysql 5.5\n\
character-set-server=utf8\n\
collation-server=utf8_unicode_ci\n\
" /etc/mysql/my.cnf

# Xdebug config
sudo sed -i '/zend_extension=.*/ a \
xdebug.remote_enable=On \
xdebug.remote_host="localhost" \
xdebug.remote_port=9001 \
xdebug.remote_handler="dbgp" \
xdebug.idekey=netbeans-xdebug \
xdebug.cli_color=2 \
xdebug.max_nesting_level=1000 \
xdebug.collect_params=2 \
xdebug.collect_return=On \
' /etc/php5/conf.d/20-xdebug.ini

sudo service apache2 restart
sudo service php5-fpm restart
sudo service mysql restart

# PHP Tools
sudo mkdir /opt/composer
curl -s https://getcomposer.org/installer | sudo php -- --install-dir=/opt/composer
sudo chmod 755 /opt/composer/composer.phar
sudo ln -s /opt/composer/composer.phar /usr/local/bin/composer

sudo mkdir /opt/php-cs-fixer
sudo curl http://cs.sensiolabs.org/get/php-cs-fixer.phar -o /opt/php-cs-fixer/php-cs-fixer.phar
sudo chmod 755 /opt/php-cs-fixer/php-cs-fixer.phar
sudo ln -s /opt/php-cs-fixer/php-cs-fixer.phar /usr/local/bin/php-cs-fixer

sudo pear config-set auto_discover 1
sudo pear update-channels
sudo pear upgrade
sudo pear install Console_Getopt
sudo pear install PHP_CodeSniffer

sudo pear install pear.phpunit.de/PHPUnit
sudo pear install phpunit/PHPUnit_SkeletonGenerator
sudo pear install phpunit/PHPUnit_Story
sudo pear install phpunit/DbUnit
sudo pear install phpunit/PHPUnit_Selenium
sudo pear install phpunit/PHP_Invoker

sudo pear channel-discover pear.phpmd.org 
sudo pear channel-discover pear.pdepend.org 
sudo pear install phpmd/PHP_PMD

sudo pear channel-discover pear.phpdoc.org
sudo pear install phpdoc/phpDocumentor-alpha
