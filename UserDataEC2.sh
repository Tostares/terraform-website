#!/bin/bash

# Install updates
sudo yum update -y

# Install Apache server
sudo yum install -y httpd

# Install MariaDB, PHP, and necessary tools
sudo wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
sudo yum localinstall -y mysql57-community-release-el7-11.noarch.rpm

# Import GPG key
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022# Update repository metadata
sudo yum clean all
sudo yum makecache

# Install MySQL server
sudo yum install -y mysql-community-server

# Start and enable MySQL service
sudo systemctl start mysqld.service
sudo systemctl enable mysqld.service

# Retrieve the temporary root password
temp_password=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

# Set the desired root password
DBRootPassword='root@258!Password'

# Change the root password using the temporary password
mysql -u root -p"$temp_password" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DBRootPassword';"

# Install PHP
sudo amazon-linux-extras install -y php7.4

# Update all installed packages
sudo yum update -y

# Restart Apache
sudo systemctl restart httpd

# Set database variables
DBName="wordpress"
DBUser="wordpress"
DBPassword="admin1234"
DBRootPassword="rootpassword1234"
DBHost="localhost"

# Start Apache server and enable it on system startup
sudo systemctl start httpd
sudo systemctl enable httpd

# Start MariaDB service and enable it on system startup
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Wait for MariaDB to fully start
sleep 10

# Set MariaDB root password
sudo mysqladmin -u root password "$DBRootPassword"

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
sudo sed -i "s/'localhost'/'$DBHost'/g" wp-config.php

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