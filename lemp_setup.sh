#!/bin/bash

certbot_crontab() {

echo -en "\n"
echo "Setting up Crontab for Let's Encrypt."
crontab -l > certbot
echo "30 2 * * 1 /usr/bin/certbot renew >> /var/log/le-renew.log" >> certbot
echo "35 2 * * 1 systemctl reload apache2" >> certbot
crontab certbot
rm certbot

}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Update system
echo "Updating server (This may take some time)"
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1

# Install Nginx, MySQL, PHP, and other dependencies
echo "Installing Nginx, MySQL, PHP, and other dependencies (This may take some time)"
apt install -y nginx mysql-server php-fpm php-mysql certbot python3-certbot-nginx > /dev/null 2>&1

# Prompt for domain name and validate input
read -p "Enter your domain name (example.com): " domain
while [[ ! $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
  echo "Invalid domain name. Please enter a valid domain name."
  read -p "Enter your domain name (example.com): " domain
done

# Prompt for email address and validate input
read -p "Enter your email address: " email
while [[ ! $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; do
  echo "Invalid email address. Please enter a valid email address."
  read -p "Enter your email address: " email
done

# Obtain SSL certificate using Let's Encrypt
certbot --nginx -d "$domain" --non-interactive --agree-tos --email "$email" || {
  echo "Let's Encrypt setup failed. Please check the domain and email address."
  exit 1
}


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
echo "LEMP stack installation and Let's Encrypt setup completed."
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