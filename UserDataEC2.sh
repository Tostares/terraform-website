#! /bin/bash

# # Install updates
sudo yum update -y

# Install Curl
sudo yum install curl -y
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

# Configure AWS CLI with IAM role credentials
aws configure set default.region us-west-2

#Install stresstesting to test load balancing, can be removed in production
sudo yum install -y stress-ng

#Install httpd
sudo yum install -y httpd

#Install PHP
sudo amazon-linux-extras install -y php8.0


# Retrieve RDS variables from Terraform output
sudo touch DB_VAR.txt
sudo chmod 777 DB_VAR.txt
DBName=${db_name} >> DB_VAR.txt
DBUser=${db_username} >> DB_VAR.txt
DBRootPassword='rootpassword'
DBPassword=${db_password} >> DB_VAR.txt
db_endpoint=${db_endpoint} >> DB_VAR.txt

# Start Apache server and enable it on system startup
sudo systemctl start httpd
sudo systemctl enable httpd

# Download and install WordPress
sudo wget http://wordpress.org/latest.tar.gz -P /var/www/html
cd /var/www/html
sudo tar -zxvf latest.tar.gz
sudo cp -rvf wordpress/* .
sudo rm -R wordpress
sudo rm latest.tar.gz

# Install WordPress Core
wp core install --path=/var/www/html

# Making changes to the wp-config.php file, setting the DB name
sudo cp ./wp-config-sample.php ./wp-config.php 
sudo sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sudo sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sudo sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
sudo sed -i "s/'localhost'/'$db_endpoint'/g" wp-config.php

# Grant permissions
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www
sudo find /var/www -type d -exec chmod 2775 {} \;
sudo find /var/www -type f -exec chmod 0664 {} \;

# Create WordPress database
echo "CREATE DATABASE IF NOT EXISTS $DBName;" | mysql -u root --password=$DBRootPassword
echo "CREATE USER IF NOT EXISTS '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" | mysql -u root --password=$DBRootPassword
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" | mysql -u root --password=$DBRootPassword
echo "FLUSH PRIVILEGES;" | mysql -u root --password=$DBRootPassword

# Install and activate a Spectra plugin
SPECTRA="spectra"
SPECTRA_ZIP_URL="https://downloads.wordpress.org/plugin/ultimate-addons-for-gutenberg.2.14.1.zip"

# Download the plugin ZIP file
wget "$SPECTRA_ZIP_URL" -O "/tmp/$SPECTRA.zip"

# Install the plugin
cd /var/www/html/wp-content/plugins
unzip "/tmp/$SPECTRA.zip"
rm "/tmp/$SPECTRA.zip"

# Activate the plugin
wp plugin activate "$SPECTRA" --path="/var/www/html"

# Install and activate a Updraft plugin
UPDRAFT="Updraft"
UPDRAFT_ZIP_URL="https://downloads.wordpress.org/plugin/updraftplus.1.24.4.zip"

# Download the plugin ZIP file
wget "$UPDRAFT_ZIP_URL" -O "/tmp/$UPDRAFT.zip"

# Install the plugin
cd /var/www/html/wp-content/plugins
unzip "/tmp/$UPDRAFT.zip"
rm "/tmp/$UPDRAFT.zip"

# Activate the plugin
wp plugin activate "$UPDRAFT" --path="/var/www/html"


# Download the theme ZIP file
THEME_NAME="Astra"
THEME_ZIP_URL="https://downloads.wordpress.org/theme/astra.4.7.3.zip"
wget "$THEME_ZIP_URL" -O "/tmp/$THEME_NAME.zip"

# Install the theme
cd /var/www/html/wp-content/themes
unzip "/tmp/$THEME_NAME.zip"
rm "/tmp/$THEME_NAME.zip"

# Activate the theme
wp theme activate "$THEME_NAME" --path="/var/www/html"

# WGET Backup Files
sudo curl -L "https://drive.google.com/uc?export=download&id=1gz0cIvrDoWhlquofnEZ1c03Pq2cyqwMZ" --output /tmp/backup.zip

# Restore the WordPress site from S3
wp updraftplus restore /tmp/backup.zip --file-entities=all --migration=true

# Change the Wordpress configuration to direct connection instead of FTP
sudo echo "define( 'FS_METHOD', 'direct' );" >> /var/www/html/wp-config.php