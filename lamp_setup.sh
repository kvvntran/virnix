#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Update system
echo "Updating server (This may take some time)"
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1

# Install Apache, MySQL, PHP, and other dependencies
echo "Installing Apache, MySQL, PHP, and other dependencies (This may take some time)"
apt install -y apache2 mysql-server php libapache2-mod-php php-mysql certbot python3-certbot-apache > /dev/null 2>&1

# Enable required Apache modules
echo "Enable required Apache modules"
a2enmod rewrite ssl  > /dev/null 2>&1

# Restart Apache
systemctl restart apache2 > /dev/null 2>&1

# Prompt for domain name
read -p "Enter your domain or subdomain name (example.com): " domain
while [[ ! $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ && ! $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
  echo "Invalid domain or subdomain name. Please enter a valid domain or subdomain name."
  read -p "Enter your domain or subdomain name (example.com): " domain
done

# Prompt for email address
read -p "Enter your email address: " email
while [[ ! $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; do
  echo "Invalid email address. Please enter a valid email address."
  read -p "Enter your email address: " email
done

# Obtain SSL certificate using Let's Encrypt
certbot --apache -d "$domain" --non-interactive --agree-tos --email "$email" > /dev/null 2>&1

# Generate random password for MySQL root user
mysql_root_password=$(openssl rand -base64 12) > /dev/null 2>&1

echo "Setting up MySQL Server"

# Set password with `debconf-set-selections` You don't have to enter it in prompt
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${mysql_root_password}" # new password for the MySQL root user
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${mysql_root_password}" # repeat password for the MySQL root user

# Other Code.....
sudo mysql --user=root --password=${mysql_root_password} << EOFMYSQLSECURE
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOFMYSQLSECURE
> /dev/null 2>&1

# Print Let's Encrypt certificate paths
echo "Let's Encrypt certificate paths:"
echo "Certificate: /etc/letsencrypt/live/$domain/fullchain.pem"
echo "Private Key: /etc/letsencrypt/live/$domain/privkey.pem"

# Setting HTML
rm /var/www/html/index.html > /dev/null 2>&1
echo "<text>Hello world.</text>" > /var/www/html/index.html

echo "---------------------------------------------------------------"
# Print final setup instructions
echo "LAMP stack installation and Let's Encrypt setup completed."
echo ""
echo "You can access your website at https://$domain"
echo ""
echo "MySQL root user password: $mysql_root_password"
echo "MySQL root user password: $mysql_root_password" > /home/credentials
echo ""
echo "Your MySQL password was saved to /home/credentials"
echo ""
echo "You can upload your website to /var/www/html"
echo "---------------------------------------------------------------"

# Remove startup script from .bashrc
sed -i "/lamp_setup/d" ~/.bashrc > /dev/null 2>&1
# Self Destruct
rm -- "$0" > /dev/null 2>&1
