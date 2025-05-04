#!/bin/bash
set -e

# Read all credentials from Docker secrets
echo "Reading credentials from Docker secrets..."

# Database credentials
if [ -f "/run/secrets/db_password" ]; then
    WORDPRESS_DB_PASSWORD=$(cat /run/secrets/db_password)
    echo "Retrieved database password from secret"
fi

# WordPress admin credentials
if [ -f "/run/secrets/wp_admin_user" ]; then
    WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
    echo "Retrieved admin username from secret"
fi

if [ -f "/run/secrets/wp_admin_password" ]; then
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
    echo "Retrieved admin password from secret"
fi

if [ -f "/run/secrets/wp_admin_email" ]; then
    WP_ADMIN_EMAIL=$(cat /run/secrets/wp_admin_email)
    echo "Retrieved admin email from secret"
fi

# WordPress regular user credentials
if [ -f "/run/secrets/wp_regular_user" ]; then
    WP_REGULAR_USER=$(cat /run/secrets/wp_regular_user)
    echo "Retrieved regular username from secret"
fi

if [ -f "/run/secrets/wp_regular_password" ]; then
    WP_REGULAR_PASSWORD=$(cat /run/secrets/wp_regular_password)
    echo "Retrieved regular user password from secret"
fi

if [ -f "/run/secrets/wp_regular_email" ]; then
    WP_REGULAR_EMAIL=$(cat /run/secrets/wp_regular_email)
    echo "Retrieved regular user email from secret"
fi

# WordPress authentication keys and salts
if [ -f "/run/secrets/wp_auth_key" ]; then
    WORDPRESS_AUTH_KEY=$(cat /run/secrets/wp_auth_key)
fi

if [ -f "/run/secrets/wp_secure_auth_key" ]; then
    WORDPRESS_SECURE_AUTH_KEY=$(cat /run/secrets/wp_secure_auth_key)
fi

if [ -f "/run/secrets/wp_logged_in_key" ]; then
    WORDPRESS_LOGGED_IN_KEY=$(cat /run/secrets/wp_logged_in_key)
fi

if [ -f "/run/secrets/wp_nonce_key" ]; then
    WORDPRESS_NONCE_KEY=$(cat /run/secrets/wp_nonce_key)
fi

if [ -f "/run/secrets/wp_auth_salt" ]; then
    WORDPRESS_AUTH_SALT=$(cat /run/secrets/wp_auth_salt)
fi

if [ -f "/run/secrets/wp_secure_auth_salt" ]; then
    WORDPRESS_SECURE_AUTH_SALT=$(cat /run/secrets/wp_secure_auth_salt)
fi

if [ -f "/run/secrets/wp_logged_in_salt" ]; then
    WORDPRESS_LOGGED_IN_SALT=$(cat /run/secrets/wp_logged_in_salt)
fi

if [ -f "/run/secrets/wp_nonce_salt" ]; then
    WORDPRESS_NONCE_SALT=$(cat /run/secrets/wp_nonce_salt)
fi

echo "All credentials loaded from secrets"

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