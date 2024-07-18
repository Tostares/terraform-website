#! /bin/bash

# # Install updates
sudo yum update -y

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
#DBRootPassword='rootpassword'
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

# Change the Wordpress configuration to direct connection instead of FTP
sudo echo "define( 'FS_METHOD', 'direct' );" >> /var/www/html/wp-config.php