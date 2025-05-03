#!/bin/bash
set -e

# Read password from Docker secret if available
if [ -f "/run/secrets/db_password" ]; then
    WORDPRESS_DB_PASSWORD=$(cat /run/secrets/db_password)
    echo "Retrieved database password from secret"
fi

# Copy WordPress files if they don't exist
if [ ! -f /var/www/html/index.php ]; then
    echo "Copying WordPress files to web root..."
    cp -r /var/www/wordpress/* /var/www/html/
    chown -R nobody:nobody /var/www/html
fi

cd /var/www/html

# Create wp-config.php using environment variables
if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php file..."
    cat > wp-config.php << EOF
<?php
define('DB_NAME', '${WORDPRESS_DB_NAME}');
define('DB_USER', '${WORDPRESS_DB_USER}');
define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');
define('DB_HOST', '${WORDPRESS_DB_HOST}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('AUTH_KEY',         '${WORDPRESS_AUTH_KEY}');
define('SECURE_AUTH_KEY',  '${WORDPRESS_SECURE_AUTH_KEY}');
define('LOGGED_IN_KEY',    '${WORDPRESS_LOGGED_IN_KEY}');
define('NONCE_KEY',        '${WORDPRESS_NONCE_KEY}');
define('AUTH_SALT',        '${WORDPRESS_AUTH_SALT}');
define('SECURE_AUTH_SALT', '${WORDPRESS_SECURE_AUTH_SALT}');
define('LOGGED_IN_SALT',   '${WORDPRESS_LOGGED_IN_SALT}');
define('NONCE_SALT',       '${WORDPRESS_NONCE_SALT}');

\$table_prefix = 'wp_';

define('WP_DEBUG', false);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF
    chown nobody:nobody wp-config.php
fi

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
max_tries=30
tries=0
while ! mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent && [ $tries -lt $max_tries ]; do
    tries=$((tries + 1))
    echo "Waiting for MariaDB... ($tries/$max_tries)"
    sleep 5
done

if [ $tries -eq $max_tries ]; then
    echo "Error: MariaDB did not become ready in time."
    exit 1
fi
echo "MariaDB is ready!"

# Check if WordPress is already installed
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."
    # Install WordPress core
    wp core install \
        --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception WordPress" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    # Create regular user if requested
    if [ ! -z "$WP_REGULAR_USER" ] && [ ! -z "$WP_REGULAR_PASSWORD" ] && [ ! -z "$WP_REGULAR_EMAIL" ]; then
        echo "Creating regular user..."
        wp user create \
            --allow-root \
            "${WP_REGULAR_USER}" \
            "${WP_REGULAR_EMAIL}" \
            --user_pass="${WP_REGULAR_PASSWORD}" \
            --role=author
    fi

    # Basic settings
    wp option update blogdescription "42 Inception Project" --allow-root
    wp theme activate twentytwentytwo --allow-root
    
    # Create sample content
    wp post create \
        --allow-root \
        --post_type=page \
        --post_title="Welcome to Inception" \
        --post_content="This is your WordPress site running in Docker containers!" \
        --post_status=publish

    echo "WordPress installation completed successfully!"
else
    echo "WordPress is already installed, skipping installation."
fi

# Fix permissions
echo "Setting correct permissions..."
chown -R nobody:nobody /var/www/html
chmod -R 755 /var/www/html

echo "Starting PHP-FPM..."
exec php-fpm8 -F