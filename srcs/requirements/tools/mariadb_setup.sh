#!/bin/bash

set -e

# Create directories if they don't exist
mkdir -p /var/lib/mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld
chmod 777 /run/mysqld

# Function to set up user permissions
setup_permissions() {
    echo "Setting up database users and permissions..."
    # Use -p flag to provide password for root user
    mysql --no-defaults -u root -p${MYSQL_ROOT_PASSWORD} << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Update the second command too
    mysql --no-defaults -u root -p${MYSQL_ROOT_PASSWORD} << EOF
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'wordpress' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'wordpress';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'wordpress.srcs_inception_network' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'wordpress.srcs_inception_network';
FLUSH PRIVILEGES;
EOF
}

# Check if database is initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    # Initialize MariaDB data directory
    mysql_install_db --datadir=/var/lib/mysql --user=mysql

    # Start MariaDB service temporarily
    mysqld_safe --datadir=/var/lib/mysql --user=mysql &
    
    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB to be ready..."
    for i in {1..30}; do
        if mysqladmin ping -h localhost --silent; then
            echo "MariaDB is ready!"
            break
        fi
        echo "Waiting for MariaDB to be ready... ($i/30)"
        sleep 2
        if [ $i -eq 30 ]; then
            echo "Timed out waiting for MariaDB, will try to continue anyway..."
        fi
    done

    # Call function to set up permissions for new installation
    setup_permissions

    # Shutdown temporary mysqld
    echo "Shutting down temporary MariaDB instance..."
    mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown

    echo "Database initialized successfully!"
else
    echo "Database already initialized"
    
    # For existing database, we still need to ensure permissions are set correctly
    # Start MariaDB service temporarily with only essential arguments
    mysqld_safe --user=mysql &
    
    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB to be ready..."
    for i in {1..30}; do
        if mysqladmin ping -h localhost --silent; then
            echo "MariaDB is ready!"
            break
        fi
        echo "Waiting for MariaDB to be ready... ($i/30)"
        sleep 2
        if [ $i -eq 30 ]; then
            echo "Timed out waiting for MariaDB, will try to continue anyway..."
        fi
    done
    
    # Set up permissions for existing database
    setup_permissions
    
    # Shutdown temporary mysqld
    echo "Shutting down temporary MariaDB instance..."
    mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown
fi

# Start MariaDB with proper configuration
echo "Starting MariaDB with proper permissions..."
exec mysqld_safe --user=mysql