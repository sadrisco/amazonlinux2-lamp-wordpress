#!/bin/sh
# Originally written by Artnic, updated by sadrisco
# You can put this script on an Amazon Linux AMI 2 instance to setup a LAMP Server quickly.
# To configure a new instance, run "lamp-and-wordpress-install.sh".

_SITE_URL_='site.example.com' # note that there's no protocol in the URL here
_DB_ROOT_PASS_='ReallyStrongDatabaseRootPassword'
_DB_USER_='MySQLUserAllowedToAccessFromOutside'
_DB_USERPASS_='CreatedMySQLUsersPassword'
_DB_NAME_='DatabaseNameForTheWPInstallation'
_WP_SITE_TITLE_='Wordpress Site Title'
_WP_ADMIN_PASS_='WordpressAdminPassword'
_WP_ADMIN_EMAIL_='WordpressAdminEmail' # once completed, server sends 'installation completed' email to this one

# I usually do this to know which sites are installed in this machine quickly
touch /home/ec2-user/${_SITE_URL_}

sudo yum update -y
# configuring httpd.conf and adding a site (VirtualHost) to it
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

# BONUS: installing Wordpress via wpcli with given URL and database
# You should remove lines below if you don't want to fresh install wordpress
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
/usr/local/bin/wp --info
sudo mkdir /opt/wpcli/
cd  /opt/wpcli/
sudo wget https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
sudo echo 'source /opt/wpcli/wp-completion.bash' >> /root/.bash_profile
sudo echo 'source /opt/wpcli/wp-completion.bash' >> /home/ec2-user/.bash_profile
cd /var/www/html/${_SITE_URL_}

sudo /usr/local/bin/wp core download --allow-root
sudo /usr/local/bin/wp core config --dbhost=localhost --dbname=${_DB_NAME_} --dbuser=${_DB_USER_} --dbpass=${_DB_USERPASS_} --allow-root
sudo /usr/local/bin/wp core install --url=${_SITE_URL_} --title="${_WP_SITE_TITLE_}" --admin_name=admin --admin_password=${_WP_ADMIN_PASS_} --admin_email=${_WP_ADMIN_EMAIL_} --allow-root
sudo chown apache:apache /var/www/html/${_SITE_URL_} -Rf

