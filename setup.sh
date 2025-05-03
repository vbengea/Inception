#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to generate a secure random password
generate_password() {
  < /dev/urandom tr -dc 'A-Za-z0-9_+-.~=' | head -c 16
}

# Function to validate domain name format
validate_domain() {
  local domain=$1
  if [[ "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](\.[a-zA-Z0-9]{2,})+$ ]]; then
    return 0
  elif [[ "$domain" == "localhost" ]]; then
    return 0
  else
    return 1
  fi
}

# Function to add domain to hosts file if needed
add_to_hosts() {
  local domain=$1
  if [[ "$domain" != "localhost" ]]; then
    if ! grep -q "$domain" /etc/hosts; then
      echo -e "${YELLOW}Do you want to add $domain to your /etc/hosts file? (requires sudo) (y/n): ${NC}"
      read -r add_hosts
      if [[ "$add_hosts" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Adding domain to /etc/hosts...${NC}"
        echo "127.0.0.1 $domain" | sudo tee -a /etc/hosts > /dev/null
        echo -e "${GREEN}✓ Added $domain to /etc/hosts${NC}"
      else
        echo -e "${YELLOW}Skipping /etc/hosts modification. Make sure to manually add the domain.${NC}"
      fi
    else
      echo -e "${GREEN}✓ Domain already in /etc/hosts${NC}"
    fi
  fi
}

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}      Inception Project - Secure Setup Script       ${NC}"
echo -e "${BLUE}====================================================${NC}"

ENV_PATH="./srcs/.env"

# Check if .env file already exists
if [ -f "$ENV_PATH" ]; then
  echo -e "${YELLOW}Warning: $ENV_PATH already exists.${NC}"
  read -p "Do you want to regenerate it? This will overwrite your existing configuration. (y/n): " choice
  if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Setup cancelled. Using existing .env file.${NC}"
    exit 0
  fi
fi

# Copy template as a starting point
cp ./srcs/.env.template "$ENV_PATH"

# Collect or generate necessary information
echo -e "\n${BLUE}Collecting configuration information...${NC}"

# Domain name with validation
while true; do
  read -p "Enter your domain name [default: localhost]: " DOMAIN_NAME
  DOMAIN_NAME=${DOMAIN_NAME:-localhost}
  
  if validate_domain "$DOMAIN_NAME"; then
    break
  else
    echo -e "${RED}Invalid domain format. Please enter a valid domain (e.g., example.com, mysite.org).${NC}"
  fi
done

# Add domain to hosts file if it's not localhost
add_to_hosts "$DOMAIN_NAME"

# Database Credentials
MYSQL_ROOT_PASSWORD=$(generate_password)
MYSQL_USER="wp_user"
MYSQL_PASSWORD=$(generate_password)
MYSQL_DATABASE="wordpress"

# WordPress Credentials
WORDPRESS_DB_HOST="mariadb"
WORDPRESS_DB_USER="$MYSQL_USER"
WORDPRESS_DB_PASSWORD="$MYSQL_PASSWORD"
WORDPRESS_DB_NAME="$MYSQL_DATABASE"

# Generate WordPress authentication keys and salts
echo -e "\n${BLUE}Generating secure WordPress authentication keys and salts...${NC}"
WORDPRESS_AUTH_KEY=$(generate_password)
WORDPRESS_SECURE_AUTH_KEY=$(generate_password)
WORDPRESS_LOGGED_IN_KEY=$(generate_password)
WORDPRESS_NONCE_KEY=$(generate_password)
WORDPRESS_AUTH_SALT=$(generate_password)
WORDPRESS_SECURE_AUTH_SALT=$(generate_password)
WORDPRESS_LOGGED_IN_SALT=$(generate_password)
WORDPRESS_NONCE_SALT=$(generate_password)

# WordPress Admin
read -p "Enter WordPress admin username [default: admin]: " WP_ADMIN_USER
WP_ADMIN_USER=${WP_ADMIN_USER:-admin}
WP_ADMIN_PASSWORD=$(generate_password)
read -p "Enter WordPress admin email [default: admin@$DOMAIN_NAME]: " WP_ADMIN_EMAIL
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-admin@$DOMAIN_NAME}

# WordPress Regular User
read -p "Enter WordPress regular username [default: user]: " WP_REGULAR_USER
WP_REGULAR_USER=${WP_REGULAR_USER:-user}
WP_REGULAR_PASSWORD=$(generate_password)
read -p "Enter WordPress regular user email [default: user@$DOMAIN_NAME]: " WP_REGULAR_EMAIL
WP_REGULAR_EMAIL=${WP_REGULAR_EMAIL:-user@$DOMAIN_NAME}


# Create secrets directory
echo -e "\n${BLUE}Setting up Docker secrets...${NC}"
SECRETS_DIR="./secrets"
mkdir -p "$SECRETS_DIR"

# Save database passwords as Docker secrets
# echo -n "$MYSQL_ROOT_PASSWORD" > "$SECRETS_DIR/db_root_password.txt"
# echo -n "$MYSQL_PASSWORD" > "$SECRETS_DIR/db_password.txt"
echo -n "$MYSQL_ROOT_PASSWORD" > "$SECRETS_DIR/db_root_password.txt"
echo -n "$MYSQL_PASSWORD" > "$SECRETS_DIR/db_password.txt"

# Set proper permissions
chmod 600 "$SECRETS_DIR/db_root_password.txt"
chmod 600 "$SECRETS_DIR/db_password.txt"
echo -e "${GREEN}✓ Docker secrets created${NC}"

# Update the .env file
echo -e "\n${BLUE}Setting up environment file with secure credentials...${NC}"
sed -i "s/<MYSQL_USER>/$MYSQL_USER/g" "$ENV_PATH"
sed -i "s/<WORDPRESS_DB_USER>/$WORDPRESS_DB_USER/g" "$ENV_PATH"
sed -i "s/<WP_ADMIN_USER>/$WP_ADMIN_USER/g" "$ENV_PATH"
sed -i "s/<WP_ADMIN_PASSWORD>/$WP_ADMIN_PASSWORD/g" "$ENV_PATH"
sed -i "s/<WP_ADMIN_EMAIL>/$WP_ADMIN_EMAIL/g" "$ENV_PATH"
sed -i "s/<WP_REGULAR_USER>/$WP_REGULAR_USER/g" "$ENV_PATH"
sed -i "s/<WP_REGULAR_PASSWORD>/$WP_REGULAR_PASSWORD/g" "$ENV_PATH"
sed -i "s/<WP_REGULAR_EMAIL>/$WP_REGULAR_EMAIL/g" "$ENV_PATH"
sed -i "s/example.com/$DOMAIN_NAME/g" "$ENV_PATH"
sed -i "s/<WORDPRESS_AUTH_KEY>/$WORDPRESS_AUTH_KEY/g" "$ENV_PATH"
sed -i "s/<WORDPRESS_SECURE_AUTH_KEY>/$WORDPRESS_SECURE_AUTH_KEY/g" "$ENV_PATH"
sed -i "s/<WORDPRESS_LOGGED_IN_KEY>/$WORDPRESS_LOGGED_IN_KEY/g" "$ENV_PATH"
sed -i "s/<WORDPRESS_NONCE_KEY>/$WORDPRESS_NONCE_KEY/g" "$ENV_PATH"
sed -i "s/<WORDPRESS_AUTH_SALT>/$WORDPRESS_AUTH_SALT/g" "$ENV_PATH"
sed -i "s/<WORDPRESS_SECURE_AUTH_SALT>/$WORDPRESS_SECURE_AUTH_SALT/g" "$ENV_PATH"
sed -i "s/<WORDPRESS_LOGGED_IN_SALT>/$WORDPRESS_LOGGED_IN_SALT/g" "$ENV_PATH"
sed -i "s/<WORDPRESS_NONCE_SALT>/$WORDPRESS_NONCE_SALT/g" "$ENV_PATH"

# Create a backup of credentials for the user
CREDENTIALS_FILE="./credentials_backup.txt"
echo -e "\n${BLUE}Creating a backup of your credentials...${NC}"
echo "# INCEPTION PROJECT CREDENTIALS - KEEP THIS FILE SAFE" > "$CREDENTIALS_FILE"
echo "# Generated on: $(date)" >> "$CREDENTIALS_FILE"
echo "# Domain: $DOMAIN_NAME" >> "$CREDENTIALS_FILE"
echo "" >> "$CREDENTIALS_FILE"
echo "## Database Credentials" >> "$CREDENTIALS_FILE"
echo "MySQL Root Password: $MYSQL_ROOT_PASSWORD" >> "$CREDENTIALS_FILE"
echo "MySQL WordPress User: $MYSQL_USER" >> "$CREDENTIALS_FILE"
echo "MySQL WordPress Password: $MYSQL_PASSWORD" >> "$CREDENTIALS_FILE"
echo "" >> "$CREDENTIALS_FILE"
echo "## WordPress Credentials" >> "$CREDENTIALS_FILE"
echo "Admin Username: $WP_ADMIN_USER" >> "$CREDENTIALS_FILE"
echo "Admin Password: $WP_ADMIN_PASSWORD" >> "$CREDENTIALS_FILE"
echo "Admin Email: $WP_ADMIN_EMAIL" >> "$CREDENTIALS_FILE"
echo "" >> "$CREDENTIALS_FILE"
echo "Regular Username: $WP_REGULAR_USER" >> "$CREDENTIALS_FILE"
echo "Regular Password: $WP_REGULAR_PASSWORD" >> "$CREDENTIALS_FILE"
echo "Regular Email: $WP_REGULAR_EMAIL" >> "$CREDENTIALS_FILE"
echo "" >> "$CREDENTIALS_FILE"
echo "## Access Information" >> "$CREDENTIALS_FILE"
echo "WordPress URL: https://$DOMAIN_NAME" >> "$CREDENTIALS_FILE"
echo "WordPress Admin URL: https://$DOMAIN_NAME/wp-admin/" >> "$CREDENTIALS_FILE"
echo "" >> "$CREDENTIALS_FILE"
echo "## WordPress Authentication Keys and Salts" >> "$CREDENTIALS_FILE"
echo "AUTH_KEY: $WORDPRESS_AUTH_KEY" >> "$CREDENTIALS_FILE"
echo "SECURE_AUTH_KEY: $WORDPRESS_SECURE_AUTH_KEY" >> "$CREDENTIALS_FILE"
echo "LOGGED_IN_KEY: $WORDPRESS_LOGGED_IN_KEY" >> "$CREDENTIALS_FILE"
echo "NONCE_KEY: $WORDPRESS_NONCE_KEY" >> "$CREDENTIALS_FILE"
echo "AUTH_SALT: $WORDPRESS_AUTH_SALT" >> "$CREDENTIALS_FILE"
echo "SECURE_AUTH_SALT: $WORDPRESS_SECURE_AUTH_SALT" >> "$CREDENTIALS_FILE"
echo "LOGGED_IN_SALT: $WORDPRESS_LOGGED_IN_SALT" >> "$CREDENTIALS_FILE"
echo "NONCE_SALT: $WORDPRESS_NONCE_SALT" >> "$CREDENTIALS_FILE"

chmod 600 "$CREDENTIALS_FILE"

echo -e "\n${GREEN}✓ Setup complete!${NC}"
echo -e "${GREEN}✓ Environment file created at: $ENV_PATH${NC}"
echo -e "${GREEN}✓ Credentials backup created at: $CREDENTIALS_FILE${NC}"
echo -e "${YELLOW}!!! IMPORTANT: Make sure to keep your credentials backup secure and delete it after use !!!${NC}"

if [[ "$DOMAIN_NAME" != "localhost" ]]; then
  echo -e "\n${BLUE}Domain Configuration:${NC}"
  echo -e "You're using a custom domain: ${GREEN}$DOMAIN_NAME${NC}"
  echo -e "To access your site, make sure one of the following is true:"
  echo -e "  1. The domain ${GREEN}$DOMAIN_NAME${NC} resolves to your server's IP address"
  echo -e "  2. You've added ${GREEN}$DOMAIN_NAME${NC} to your local /etc/hosts file"
  echo -e "  3. You're accessing the site from a machine that can resolve ${GREEN}$DOMAIN_NAME${NC}"
fi

echo -e "\n${BLUE}You can now run 'make up' to start your containers.${NC}"