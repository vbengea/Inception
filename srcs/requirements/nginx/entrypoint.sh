#!/bin/bash

if [ -z "$DOMAIN_NAME" ]; then
    echo "Warning: DOMAIN_NAME not set, defaulting to localhost"
    export DOMAIN_NAME="localhost"
fi

echo "Configuring Nginx for domain: $DOMAIN_NAME"

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}"

    echo "SSL certificates generated for ${DOMAIN_NAME}"
fi

if [ ! -f /etc/nginx/sites-available/default.bak ]; then
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
    echo "Nginx configuration backed up"
fi

envsubst '${DOMAIN_NAME}' < /etc/nginx/sites-available/default > /etc/nginx/sites-available/default.temp
mv /etc/nginx/sites-available/default.temp /etc/nginx/sites-available/default
echo "Nginx configuration updated with domain: ${DOMAIN_NAME}"

echo "<html><body><h1>NGINX Test Page</h1><p>Domain: ${DOMAIN_NAME}</p><p>This is a test page to verify NGINX is working.</p><p><a href='/domaintest.php'>Check WordPress Domain Configuration</a></p></body></html>" > /var/www/html/test.html

mkdir -p /var/log/nginx
touch /var/log/nginx/error.log /var/log/nginx/access.log /var/log/nginx/test_error.log /var/log/nginx/php_error.log
chmod 666 /var/log/nginx/*.log

echo "Starting Nginx"
exec nginx -g "daemon off;"
