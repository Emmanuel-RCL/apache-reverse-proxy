#!/bin/bash
# ==========================================================
# Author: SEYYED ALI HABIBPOUR
# Website: https://reycloud.ir
# Script: Reverse Proxy Setup with Apache (Interactive Menu, Fixed CookiePath)
# Description: Sets up an Apache reverse proxy from Server A to Server B
#              with interactive input menu and proper handling of ProxyPassReverseCookiePath.
# ==========================================================

# Function to display error and exit
error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
   error_exit "This script must be run as root. Use 'sudo'."
fi

# Automatically detect Server A IP
SERVER_A_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_A_IP" ]; then
    read -rp "Failed to detect Server A IP. Please enter it manually: " SERVER_A_IP
fi
echo "Detected/Set Server A IP: $SERVER_A_IP"

# Interactive menu to get Server B details
clear
echo "=========================================================="
echo "Author: SEYYED ALI HABIBPOUR"
echo "Website: https://reycloud.ir"
echo "Script: Reverse Proxy Setup with Apache (Interactive Menu)"
echo "=========================================================="
while true; do
    echo "Please enter the following details for Server B:"
    
    # Validate Server B IP
    while true; do
        read -rp "1) Server B IP: " SERVER_B_IP
        if [[ $SERVER_B_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        else
            echo "Error: Invalid IP format. Example: 192.168.1.100"
        fi
    done
    
    # Validate Server B Port
    while true; do
        read -rp "2) Server B Port: " SERVER_B_PORT
        if [[ $SERVER_B_PORT =~ ^[0-9]+$ ]] && [ "$SERVER_B_PORT" -ge 1 ] && [ "$SERVER_B_PORT" -le 65535 ]; then
            break
        else
            echo "Error: Port must be a number between 1 and 65535"
        fi
    done
    
    # Validate Server B Hostname/Domain
    while true; do
        read -rp "3) Server B Hostname/Domain: " SERVER_HOST
        if [[ $SERVER_HOST =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo "Error: Invalid domain format. Example: example.com"
        fi
    done
    
    # Validate Server B Path
    while true; do
        read -rp "4) Server B Path (e.g., / or /app): " SERVER_PATH
        # Trim whitespace
        SERVER_PATH=$(echo "$SERVER_PATH" | xargs)
        
        # Handle empty input
        if [ -z "$SERVER_PATH" ]; then
            SERVER_PATH="/"
            break
        fi
        
        # Validate path format
        if [[ "$SERVER_PATH" != /* ]]; then
            echo "Error: Path must start with '/' (e.g., /app)"
            continue
        fi
        
        # Check for invalid characters
        if [[ "$SERVER_PATH" =~ [[:space:]] ]]; then
            echo "Error: Path cannot contain spaces"
            continue
        fi
        
        break
    done
    
    echo "==========================="
    echo "You entered:"
    echo "Server B IP      : $SERVER_B_IP"
    echo "Server B Port    : $SERVER_B_PORT"
    echo "Server B Host    : $SERVER_HOST"
    echo "Server B Path    : $SERVER_PATH"
    echo "==========================="
    read -rp "Are these values correct? (y/n): " CONFIRM
    case $CONFIRM in
        [Yy]* ) break;;
        [Nn]* ) echo "Let's re-enter the values.";;
        * ) echo "Please answer y or n.";;
    esac
done

# Update system
echo "Updating system..."
apt-get update -y || error_exit "Failed to update system."

# Install Apache if not installed
if ! command -v apache2 &> /dev/null; then
    echo "Installing Apache..."
    apt-get install -y apache2 || error_exit "Failed to install Apache."
fi

# Enable required proxy modules
echo "Enabling proxy modules..."
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests rewrite headers

# Create backup of existing configuration
if [ -f /etc/apache2/sites-available/reverse_proxy.conf ]; then
    BACKUP_FILE="/etc/apache2/sites-available/reverse_proxy.conf.backup.$(date +%Y%m%d%H%M%S)"
    cp /etc/apache2/sites-available/reverse_proxy.conf "$BACKUP_FILE"
    echo "Backup of existing configuration saved to $BACKUP_FILE"
fi

# Escape domain for regex
ESCAPED_HOST=$(echo "$SERVER_HOST" | sed 's/\./\\./g')

# Prepare ProxyPassReverseCookiePath only if path is not "/"
if [ "$SERVER_PATH" = "/" ]; then
    PROXY_COOKIE_PATH="# ProxyPassReverseCookiePath disabled (root path)"
else
    PROXY_COOKIE_PATH="ProxyPassReverseCookiePath \"$SERVER_PATH\" \"/\""
fi

# Create Apache virtual host configuration
cat > /etc/apache2/sites-available/reverse_proxy.conf <<EOF
<VirtualHost *:80>
    ServerName $SERVER_A_IP
    ServerAdmin webmaster@localhost

    # Reverse proxy settings
    ProxyRequests Off
    ProxyPreserveHost Off

    <Proxy *>
        Require all granted
    </Proxy>

    # Set Host header to the specified domain
    RequestHeader set Host "$SERVER_HOST"

    # Proxy settings for the specified path
    ProxyPass / http://$SERVER_B_IP:$SERVER_B_PORT$SERVER_PATH
    ProxyPassReverse / http://$SERVER_B_IP:$SERVER_B_PORT$SERVER_PATH

    # Prevent redirects to default page and fix cookie domains
    ProxyPassReverseCookieDomain $SERVER_B_IP $SERVER_HOST
    $PROXY_COOKIE_PATH

    # Handle redirects properly
    RewriteEngine On
    RewriteCond %{HTTP_HOST} !^$ESCAPED_HOST$ [NC]
    RewriteRule ^(.*)$ http://$SERVER_HOST\$1 [R=301,L]

    # Logs
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Disable default site
a2dissite 000-default.conf || echo "Default site already disabled"

# Enable new reverse proxy site
a2ensite reverse_proxy.conf || echo "Reverse proxy site already enabled"

# Test Apache configuration
echo "Testing Apache configuration..."
if ! apache2ctl configtest; then
    echo "Generated configuration content:"
    cat /etc/apache2/sites-available/reverse_proxy.conf
    error_exit "Apache configuration test failed. The Apache error log may have more information."
fi

# Restart Apache service
systemctl restart apache2 || error_exit "Failed to restart Apache."

# Enable Apache on startup
systemctl enable apache2

echo "==================================================================="
echo "✅ Reverse proxy setup completed successfully!"
echo "Visit http://$SERVER_A_IP in your browser to see the proxied site."
echo "Host header is set to '$SERVER_HOST' and path is '$SERVER_PATH'."
echo "==================================================================="

