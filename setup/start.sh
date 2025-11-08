#!/bin/bash

# phpBB Startup Script
# This script sets up and runs the phpBB application in the dev container

set -e

echo "=========================================="
echo "  phpBB Development Environment Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Stop existing services
echo -e "${BLUE}[0/6]${NC} Stopping existing services..."
sudo service mysql stop 2>/dev/null || true
sudo apache2ctl stop 2>/dev/null || true
echo "   ✓ Existing services stopped"
echo ""

# Start MySQL
echo -e "${BLUE}[1/6]${NC} Starting MySQL..."
sudo service mysql start
echo ""

# Start Apache
echo -e "${BLUE}[2/6]${NC} Starting Apache web server..."
sudo apache2ctl start
echo ""

# Create MySQL database and user
echo -e "${BLUE}[3/6]${NC} Setting up MySQL database..."
sudo mysql -u root <<EOFMYSQL
    CREATE USER IF NOT EXISTS 'phpbb'@'localhost' IDENTIFIED BY 'phpbb';
    GRANT ALL PRIVILEGES ON *.* TO 'phpbb'@'localhost' WITH GRANT OPTION;
    CREATE DATABASE IF NOT EXISTS phpbb;
EOFMYSQL
echo "   ✓ Database 'phpbb' created"
echo "   ✓ User 'phpbb' created"
echo ""

# Fix webroot symlink
echo -e "${BLUE}[4/6]${NC} Configuring web server..."
sudo rm -rf /var/www/html
sudo ln -s /workspaces/phpbb-lab/phpBB /var/www/html
echo "   ✓ Web root configured"
echo ""

# Install Composer dependencies
echo -e "${BLUE}[5/6]${NC} Installing PHP dependencies..."
cd /workspaces/phpbb-lab/phpBB
php ../composer.phar install --no-interaction --quiet
echo "   ✓ Composer dependencies installed"
echo ""

# Check if phpBB is already installed
if [ -f "/workspaces/phpbb-lab/phpBB/config/config.php" ]; then
    echo -e "${BLUE}[6/6]${NC} phpBB is already installed"
    echo "   ✓ Skipping installation"
elif [ ! -d "/workspaces/phpbb-lab/phpBB/install" ]; then
    echo -e "${BLUE}[6/6]${NC} phpBB is already installed"
    echo "   ✓ Install directory already removed"
else
    echo -e "${BLUE}[6/6]${NC} Installing phpBB..."
    
    # Prepare config file
    cp /workspaces/phpbb-lab/.devcontainer/development-team/phpbb-config.yml /tmp/phpbb-config.yml
    
    # Update server name for Codespaces if needed
    if [ "$CODESPACES" = true ]; then
        CODESPACES_URL="${CODESPACE_NAME}-80.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
        sed -i "s/localhost/$CODESPACES_URL/g" /tmp/phpbb-config.yml
    fi
    
    # Run installation
    php /workspaces/phpbb-lab/phpBB/install/phpbbcli.php install /tmp/phpbb-config.yml
    
    # Remove install directory
    rm -rf /workspaces/phpbb-lab/phpBB/install
    
    echo "   ✓ phpBB installed successfully"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}  ✓ phpBB is ready!${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}Login Credentials:${NC}"
echo "  Username: admin"
echo "  Password: adminadmin"
echo ""
echo -e "${YELLOW}Database Access:${NC}"
echo "  Host:     127.0.0.1"
echo "  User:     phpbb"
echo "  Password: phpbb"
echo "  Database: phpbb"
echo ""
echo -e "${YELLOW}How to Access phpBB:${NC}"

# Test if the app is accessible
if curl -s http://localhost/ > /dev/null 2>&1; then
    echo "  ✓ phpBB is running on http://localhost"
    echo ""
    if [ "$CODESPACES" = true ]; then
        CODESPACES_URL="${CODESPACE_NAME}-80.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
        echo "  To access in Codespaces:"
        echo "  1. Run: gh codespace ports visibility 80:public -c \$CODESPACE_NAME"
        echo "  2. Or forward port 80 manually in VS Code"
        echo "  3. Then visit: https://${CODESPACES_URL}"
    fi
else
    echo "  ⚠ Warning: Could not connect to http://localhost"
    echo "  Apache may need to be restarted manually"
fi

echo ""
echo "  Alternative: Use VS Code Simple Browser"
echo "  Run in terminal: python3 -m http.server 8000 --directory /var/www/html"
echo "  Then open: http://localhost:8000"
echo ""
echo -e "${YELLOW}Run Tests:${NC}"
echo "  cd /workspaces/phpbb-lab"
echo "  vendor/bin/phpunit --configuration phpunit.xml.dist"
echo ""
echo "=========================================="
