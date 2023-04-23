#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run this as root user."
  exit
fi

echo "MADE BY OMEWILLEM OFC OFC"

read -p "Enter your domain name: " DOMAIN
PUBLIC_IP=$(curl -s https://api.ipify.org)
read -p "Enter the IP address of your VPS [$PUBLIC_IP]: " IP
IP=${IP:-$PUBLIC_IP}
read -p "Enter the port number: " PORT

CONFIG_FILE="/etc/nginx/sites-available/reverse_$DOMAIN.conf"
echo "Creating nginx config file at $CONFIG_FILE"
cat > $CONFIG_FILE <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/ssl/$DOMAIN/fullchain.pem;
    ssl_certificate_key etc/ssl/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://$IP:$PORT/;
    }
}
EOL

echo "Creating directory"
mkdir /etc/ssl/$DOMAIN

echo "Creating SSL certificate for $DOMAIN"
acme.sh --issue --dns dns_cf -d "$DOMAIN" --force \
--key-file /etc/ssl/$DOMAIN/privkey.pem \
--fullchain-file /etc/ssl/$DOMAIN/fullchain.pem

echo "Copying over to other directory"
ln -s $CONFIG_FILE /etc/nginx/sites-enabled/reverse_$DOMAIN.conf

echo "Restarting nginx"
service nginx restart

echo "Should be running now on: $DOMAIN"
