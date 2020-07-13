#!/bin/sh
# Originally written by Artnic, updated by sadrisco
# You can put this script on an Amazon Linux AMI 2 to setup a Wordpress website quickly.
# Requires a LAMP installation


_SITE_URL_='site.example.com' # don't use protocols
_DB_ROOT_PASS_='ReallyStrongDatabaseRootPassword'
_DB_USER_='MySQLUserAllowedToAccessFromOutside'
_DB_USERPASS_='CreatedMySQLUsersPassword'
_DB_NAME_='DatabaseNameForTheWPInstallation'
_WP_SITE_TITLE_='Wordpress Site Title'
_WP_ADMIN_PASS_='WordpressAdminPassword'
_WP_ADMIN_EMAIL_='WordpressAdminEmail' # once completed, server sends 'installation completed' email to this one

# do this to know which sites are installed in this machine quickly
touch /home/ec2-user/${_SITE_URL_}

sudo yum update -y
# configuring httpd.conf and virtualhost
sudo mkdir -p /var/www/html/${_SITE_URL_}
sudo chmod +x /var/www/html/${_SITE_URL_} -Rf

echo '<VirtualHost *:80>
   DocumentRoot /var/www/html/${_SITE_URL_}/
   ServerName ${_SITE_URL_}
   ServerAlias www.${_SITE_URL_}

   <Directory "/var/www/html/${_SITE_URL_}">
       Require all granted
       Options +Indexes 
   </Directory>

   ErrorLog logs/${_SITE_URL_}-error_log
   CustomLog logs/${_SITE_URL_}-access_log common
</VirtualHost>' | sudo tee /etc/httpd/conf.d/${_SITE_URL_}.conf

sudo service httpd restart

# configuring mysql users
mysqladmin -u root password ${_DB_ROOT_PASS_}
mysql -uroot -p${_DB_ROOT_PASS_} -e "GRANT ALL on *.* to '${_DB_USER_}'@'localhost' identified by '${_DB_USERPASS_}';grant all on *.* to '${_DB_USER_}'@'%' identified by '${_DB_USERPASS_}'; FLUSH PRIVILEGES;"
mysqladmin -uroot -p${_DB_ROOT_PASS_} create ${_DB_NAME_}

# installing wordpress
cd /var/www/html/${_SITE_URL_}
sudo /usr/local/bin/wp core download --allow-root
sudo /usr/local/bin/wp core config --dbhost=localhost --dbname=${_DB_NAME_} --dbuser=${_DB_USER_} --dbpass=${_DB_USERPASS_} --allow-root
sudo /usr/local/bin/wp core install --url=${_SITE_URL_} --title="${_WP_SITE_TITLE_}" --admin_name=admin --admin_password=${_WP_ADMIN_PASS_} --admin_email=${_WP_ADMIN_EMAIL_} --allow-root
sudo chown apache:apache /var/www/html/${_SITE_URL_} -Rf

