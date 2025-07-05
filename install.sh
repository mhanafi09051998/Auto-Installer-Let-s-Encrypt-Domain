#!/bin/bash

echo "Enter your domain (e.g., gaharinovasiteknologi.com):"
read DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ Domain cannot be empty."
    exit 1
fi

EMAIL="admin@$DOMAIN"
WEBROOT="/var/www/$DOMAIN"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

echo "🔧 Updating system & installing Nginx + Certbot..."
sudo apt update && sudo apt install nginx certbot python3-certbot-nginx -y

echo "🌐 Creating web root directory..."
sudo mkdir -p $WEBROOT
echo "<h1>Welcome to $DOMAIN</h1>" | sudo tee $WEBROOT/index.html > /dev/null

echo "🛠️ Setting up Nginx configuration..."
if [ ! -f "$NGINX_CONF" ]; then
sudo bash -c "cat > $NGINX_CONF" << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    root $WEBROOT;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
    sudo ln -s $NGINX_CONF /etc/nginx/sites-enabled/ 2>/dev/null || true
    sudo nginx -t && sudo systemctl reload nginx
else
    echo "⚠️ Nginx config already exists, skipping."
fi

echo "🔍 Checking if SSL certificate already exists..."
if sudo test -d "/etc/letsencrypt/live/$DOMAIN"; then
    echo "✅ SSL certificate for $DOMAIN already exists, skipping."
else
    echo "🔒 Obtaining HTTPS certificate with Let's Encrypt..."
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --agree-tos --email $EMAIL --redirect --non-interactive
fi

echo "🔁 Testing automatic renewal..."
sudo certbot renew --dry-run

echo "✅ Setup complete. HTTPS is now active for https://$DOMAIN 🎉"
