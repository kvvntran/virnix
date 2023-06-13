#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Update system
echo "Updating server, this may take some time."
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1

# Install Apache, MySQL, PHP, and other dependencies
echo "Install Apache, MySQL, PHP, and other dependencies"
apt install -y apache2 mysql-server php libapache2-mod-php php-mysql certbot python3-certbot-apache > /dev/null 2>&1

# Enable required Apache modules
echo "nable required Apache modules"
a2enmod rewrite ssl  > /dev/null 2>&1

# Restart Apache
systemctl restart apache2 > /dev/null 2>&1

# Prompt for domain name
read -p "Enter your domain name (example.com): " domain

# Prompt for email address
read -p "Enter your email address: " email

# Obtain SSL certificate using Let's Encrypt
certbot --apache -d "$domain" --non-interactive --agree-tos --email "$email" > /dev/null 2>&1

# Secure MySQL installation
echo "Installing MySQL"
mysql_secure_installation > /dev/null 2>&1

# Generate random password for MySQL root user
echo "Generating MySQL Password"
mysql_root_password=$(openssl rand -base64 12) > /dev/null 2>&1

# Print MySQL root user password
echo "MySQL root user password: $mysql_root_password"

# Print Let's Encrypt certificate paths
echo "Let's Encrypt certificate paths:"
echo "Certificate: /etc/letsencrypt/live/$domain/fullchain.pem"
echo "Private Key: /etc/letsencrypt/live/$domain/privkey.pem"

# Print final setup instructions
echo "LAMP stack installation and Let's Encrypt setup completed."
echo "You can access your website at https://$domain"
