#!/bin/bash

set -e

# Create directories if they don't exist
mkdir -p /var/lib/mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql /run/mysqld
chmod 777 /run/mysqld

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

    # Create database and users with proper permissions from anywhere
    echo "Creating database and users..."
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Shutdown temporary mysqld
    echo "Shutting down temporary MariaDB instance..."
    mysqladmin shutdown

    echo "Database initialized successfully!"
else
    echo "Database already initialized"
fi

# Start MariaDB with proper configuration
echo "Starting MariaDB with proper permissions..."
exec mysqld_safe --user=mysql