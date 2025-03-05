#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root (sudo)."
    exit 1
fi

# Check for critical commands
for cmd in curl grep sed mkdir; do
    if ! command_exists $cmd; then
        print_error "Required command '$cmd' not found. Please install it first."
        exit 1
    fi
done

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
        print_message "Detected distribution: $DISTRO $VERSION"
        return 0
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        VERSION=$(lsb_release -sr)
        print_message "Detected distribution: $DISTRO $VERSION"
        return 0
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
        VERSION=$DISTRIB_RELEASE
        print_message "Detected distribution: $DISTRO $VERSION"
        return 0
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
        VERSION="rolling"
        print_message "Detected distribution: Arch Linux (rolling)"
        return 0
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        VERSION=$(cat /etc/debian_version)
        print_message "Detected distribution: Debian $VERSION"
        return 0
    else
        print_warning "Could not detect Linux distribution."
        print_message "Assuming Debian-like system..."
        DISTRO="debian"
        VERSION="unknown"
        return 1
    fi
}

# Function to check and install dependencies
check_dependencies() {
    print_message "Checking and installing dependencies..."
    
    # Detect distribution
    detect_distro
    
    # Convert distro name to lowercase
    DISTRO=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')
    
    case "$DISTRO" in
        "arch"|"manjaro"|"endeavouros")
            # Arch-based systems
            print_message "Installing dependencies for Arch-based system..."
            
            # Update package database
            pacman -Sy --noconfirm
            
            # Install packages
            pacman -S --needed --noconfirm nginx certbot certbot-nginx wget curl
            ;;
            
        "debian"|"ubuntu"|"linuxmint"|"pop"|"elementary"|"zorin"|"kali"|"parrot")
            # Debian-based systems
            print_message "Installing dependencies for Debian-based system..."
            
            # Update package lists
            apt update -y
            
            # Install packages
            apt install -y nginx certbot python3-certbot-nginx wget curl
            ;;
            
        "fedora"|"rhel"|"centos"|"rocky"|"alma")
            # RHEL-based systems
            print_message "Installing dependencies for RHEL-based system..."
            
            # Install EPEL repository if needed
            if [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "rhel" ] || [ "$DISTRO" = "rocky" ] || [ "$DISTRO" = "alma" ]; then
                dnf install -y epel-release
            fi
            
            # Install packages
            dnf install -y nginx certbot python3-certbot-nginx wget curl
            ;;
            
        "opensuse"|"suse")
            # openSUSE
            print_message "Installing dependencies for openSUSE..."
            
            # Install packages
            zypper install -y nginx certbot python-certbot-nginx wget curl
            ;;
            
        *)
            # Unknown distribution, try apt, then dnf, then pacman
            print_warning "Unknown distribution. Trying common package managers..."
            
            if command -v apt >/dev/null 2>&1; then
                print_message "apt detected, using Debian-style installation..."
                apt update -y
                apt install -y nginx certbot python3-certbot-nginx wget curl
            elif command -v dnf >/dev/null 2>&1; then
                print_message "dnf detected, using RHEL-style installation..."
                dnf install -y nginx certbot python3-certbot-nginx wget curl
            elif command -v pacman >/dev/null 2>&1; then
                print_message "pacman detected, using Arch-style installation..."
                pacman -Sy --noconfirm
                pacman -S --needed --noconfirm nginx certbot certbot-nginx wget curl
            elif command -v zypper >/dev/null 2>&1; then
                print_message "zypper detected, using openSUSE-style installation..."
                zypper install -y nginx certbot python-certbot-nginx wget curl
            else
                print_error "No supported package manager found. Please install the following packages manually:"
                print_error "nginx certbot certbot-nginx wget curl"
                exit 1
            fi
            ;;
    esac
    
    # Verify nginx installation
    if ! command -v nginx >/dev/null 2>&1; then
        print_error "Nginx installation failed. Please install it manually."
        exit 1
    fi
    
    # Verify certbot installation
    if ! command -v certbot >/dev/null 2>&1; then
        print_error "Certbot installation failed. Please install it manually."
        exit 1
    fi
    
    print_message "All dependencies installed successfully."
}

# Function to prompt for domain name
get_domain_name() {
    read -p "Enter your RPC domain name (e.g., rpcx.selendra.org): " DOMAIN_NAME
    
    # Validate domain format
    if [[ ! $DOMAIN_NAME =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}(\.[a-zA-Z]{2,})?$ ]]; then
        print_error "Invalid domain format. Please enter a valid domain name."
        get_domain_name
    fi
    
    echo $DOMAIN_NAME
}

# Function to download latest Selendra binary
download_selendra() {
    print_message "Downloading latest Selendra binary..."
    
    # Get latest version from GitHub
    LATEST_VERSION=$(curl -s https://api.github.com/repos/selendra/selendra/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    
    if [ -z "$LATEST_VERSION" ]; then
        print_warning "Could not determine latest version. Using default v2.0.0."
        LATEST_VERSION="v2.0.0"
    else
        print_message "Latest version: $LATEST_VERSION"
    fi
    
    wget -O /tmp/selendra-node "https://github.com/selendra/selendra/releases/download/$LATEST_VERSION/selendra-node"
    chmod +x /tmp/selendra-node
    
    # Move binary to /usr/local/bin
    mv /tmp/selendra-node /usr/local/bin/
    print_message "Selendra binary installed to /usr/local/bin/selendra-node"
}

# Function to create nginx configuration
setup_nginx() {
    local domain=$1
    print_message "Setting up Nginx configuration for $domain..."
    
    # Create nginx configuration file
    cat > /etc/nginx/sites-available/$domain.conf << EOL
server {
    server_name $domain;
    access_log /var/log/nginx/access.log;
    
    location / {
        proxy_pass http://127.0.0.1:9933;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    listen 80;
}
EOL
    
    # Create the sites-available and sites-enabled directories if they don't exist (for non-Debian systems)
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    
    # Create symbolic link to enable the site
    ln -sf /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/
    
    # Test nginx configuration
    nginx -t
    
    if [ $? -eq 0 ]; then
        # Reload nginx to apply changes
        systemctl reload nginx
        print_message "Nginx configuration created and loaded successfully."
    else
        print_error "Nginx configuration test failed. Please check your configuration."
        exit 1
    fi
}

# Function to set up SSL with certbot
setup_ssl() {
    local domain=$1
    print_message "Setting up SSL certificate for $domain with Certbot..."
    
    # Prompt for email address
    read -p "Enter email address for SSL certificate notifications: " SSL_EMAIL
    if [ -z "$SSL_EMAIL" ]; then
        SSL_EMAIL="selendra@$domain"
        print_message "Using default email: $SSL_EMAIL"
    fi
    
    # Check for certbot plugins based on distribution
    CERTBOT_PLUGIN=""
    if certbot --help | grep -q "nginx"; then
        CERTBOT_PLUGIN="--nginx"
        print_message "Using Nginx plugin for Certbot"
    else
        print_warning "Nginx plugin for Certbot not found. Using standalone mode."
        print_message "Temporarily stopping Nginx..."
        systemctl stop nginx
        CERTBOT_PLUGIN="--standalone"
    fi
    
    # Run certbot
    certbot $CERTBOT_PLUGIN -d $domain --non-interactive --agree-tos --email $SSL_EMAIL
    CERTBOT_RESULT=$?
    
    # If using standalone mode, restart Nginx
    if [ "$CERTBOT_PLUGIN" = "--standalone" ]; then
        print_message "Restarting Nginx..."
        systemctl start nginx
    fi
    
    if [ $CERTBOT_RESULT -eq 0 ]; then
        print_message "SSL certificate installed successfully."
        
        # If using standalone mode, update Nginx config
        if [ "$CERTBOT_PLUGIN" = "--standalone" ]; then
            print_message "Updating Nginx configuration for SSL..."
            
            # Create SSL configuration
            cat > /etc/nginx/sites-available/$domain.conf << EOL
server {
    server_name $domain;
    access_log /var/log/nginx/access.log;
    
    location / {
        proxy_pass http://127.0.0.1:9933;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    
    # Strong SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # HTTP to HTTPS redirect
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}

server {
    listen 80;
    server_name $domain;
    
    # Redirect all HTTP to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOL
            
            # Reload Nginx
            nginx -t && systemctl reload nginx
        fi
    else
        print_error "Failed to install SSL certificate. Make sure your domain points to this server's IP address."
        print_warning "Continuing without SSL. You can run 'certbot --nginx' manually later."
    fi
}

# Function to prompt for node configuration
get_node_config() {
    # Default values
    local default_name="selendra-node-$(hostname)"
    local default_db_path="/var/lib/selendra"
    local default_rpc_port="9933"
    local default_p2p_port="40333"
    
    read -p "Enter node name [$default_name]: " NODE_NAME
    NODE_NAME=${NODE_NAME:-$default_name}
    
    read -p "Enter database path [$default_db_path]: " DB_PATH
    DB_PATH=${DB_PATH:-$default_db_path}
    
    read -p "Enter RPC port [$default_rpc_port]: " RPC_PORT
    RPC_PORT=${RPC_PORT:-$default_rpc_port}
    
    read -p "Enter P2P port [$default_p2p_port]: " P2P_PORT
    P2P_PORT=${P2P_PORT:-$default_p2p_port}
    
    # Create database directory if it doesn't exist
    mkdir -p $DB_PATH
    
    echo "NODE_NAME=$NODE_NAME"
    echo "DB_PATH=$DB_PATH"
    echo "RPC_PORT=$RPC_PORT"
    echo "P2P_PORT=$P2P_PORT"
}

# Function to create systemd service
create_systemd_service() {
    local domain=$1
    local node_name=$2
    local db_path=$3
    local rpc_port=$4
    local p2p_port=$5
    
    print_message "Creating systemd service for Selendra node..."
    
    # Create service file
    cat > /etc/systemd/system/selendra.service << EOL
[Unit]
Description=Selendra RPC Node Service
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/selendra-node --chain selendra --base-path $db_path --name $node_name --rpc-port $rpc_port --port $p2p_port --no-mdns --pool-limit 1024 --db-cache 1024 --runtime-cache-size 2 --max-runtime-instances 8 --rpc-external --rpc-cors all
Restart=always
RestartSec=5s
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOL
    
    # Reload systemd to apply changes
    systemctl daemon-reload
    
    # Enable and start the service
    systemctl enable selendra.service
    systemctl start selendra.service
    
    print_message "Selendra service created, enabled, and started."
    
    # Create helper scripts
    create_management_scripts
}

# Function to create management scripts
create_management_scripts() {
    print_message "Creating selendra-rpc management command..."
    
    # Create selendra-rpc script
    cat > /usr/local/bin/selendra-rpc << EOL
#!/bin/bash
# Selendra RPC Node management script

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "\${GREEN}[INFO]\${NC} \$1"
}

print_warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

print_error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
}

# Function to show usage help
show_help() {
    echo "Selendra RPC Node Management"
    echo "Usage: selendra-rpc COMMAND"
    echo ""
    echo "Commands:"
    echo "  start         Start the Selendra RPC service"
    echo "  stop          Stop the Selendra RPC service"
    echo "  restart       Restart the Selendra RPC service"
    echo "  status        Check the status of the Selendra RPC service"
    echo "  logs          View the Selendra RPC service logs in real-time"
    echo "  nginx-reload  Reload Nginx configuration"
    echo "  nginx-test    Test Nginx configuration"
    echo "  ssl-test      Test SSL certificate renewal"
    echo "  ssl-renew     Force SSL certificate renewal"
    echo "  help          Display this help message"
}

# Check if a command was provided
if [ \$# -eq 0 ]; then
    show_help
    exit 1
fi

# Process commands
case "\$1" in
    start)
        echo "Starting Selendra RPC service..."
        systemctl start selendra.service
        systemctl status selendra.service
        ;;
    stop)
        echo "Stopping Selendra RPC service..."
        systemctl stop selendra.service
        systemctl status selendra.service
        ;;
    restart)
        echo "Restarting Selendra RPC service..."
        systemctl restart selendra.service
        systemctl status selendra.service
        ;;
    status)
        echo "Selendra RPC service status:"
        systemctl status selendra.service
        ;;
    logs)
        echo "Showing Selendra RPC service logs:"
        journalctl -fu selendra.service
        ;;
    nginx-reload)
        echo "Reloading Nginx configuration:"
        systemctl reload nginx
        ;;
    nginx-test)
        echo "Testing Nginx configuration:"
        nginx -t
        ;;
    ssl-test)
        echo "Testing SSL certificate renewal:"
        certbot renew --dry-run
        ;;
    ssl-renew)
        echo "Forcing SSL certificate renewal:"
        certbot renew
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Unknown command: \$1"
        show_help
        exit 1
        ;;
esac
EOL
    
    # Make script executable
    chmod +x /usr/local/bin/selendra-rpc
    
    print_message "Management command created and made executable."
}

# Function to get server IP
get_server_ip() {
    SERVER_IP=$(curl -s ifconfig.me)
    echo $SERVER_IP
}

# Function to check if domain resolves to server IP
check_domain_dns() {
    local domain=$1
    local server_ip=$2
    
    print_message "Checking if $domain points to this server ($server_ip)..."
    
    # Check if we have dig command
    if command_exists dig; then
        # Try to resolve domain IP using dig
        DOMAIN_IP=$(dig +short $domain)
    elif command_exists nslookup; then
        # Try to resolve using nslookup
        DOMAIN_IP=$(nslookup $domain | grep -oP 'Address: \K(\d+\.){3}\d+' | tail -n1)
    elif command_exists host; then
        # Try to resolve using host
        DOMAIN_IP=$(host $domain | grep -oP 'has address \K(\d+\.){3}\d+')
    elif command_exists getent; then
        # Try to resolve using getent
        DOMAIN_IP=$(getent hosts $domain | awk '{ print $1 }')
    else
        print_warning "No DNS lookup tools found (dig, nslookup, host, getent). Installing dnsutils..."
        
        # Detect distribution and install dig
        if command_exists apt; then
            apt update -y && apt install -y dnsutils
        elif command_exists dnf; then
            dnf install -y bind-utils
        elif command_exists pacman; then
            pacman -Sy --noconfirm bind
        elif command_exists zypper; then
            zypper install -y bind-utils
        else
            print_warning "Unable to install DNS tools. DNS verification will be skipped."
            return 1
        fi
        
        # Try again with dig if installed
        if command_exists dig; then
            DOMAIN_IP=$(dig +short $domain)
        else
            print_warning "DNS tools installation failed. DNS verification will be skipped."
            return 1
        fi
    fi
    
    if [ -z "$DOMAIN_IP" ]; then
        print_warning "Domain $domain does not resolve to any IP address."
        return 1
    fi
    
    if [ "$DOMAIN_IP" = "$server_ip" ]; then
        print_message "Domain $domain correctly points to this server ($server_ip)."
        return 0
    else
        print_warning "Domain $domain points to $DOMAIN_IP, but this server's IP is $server_ip."
        return 1
    fi
}

# Main function
main() {
    print_message "Starting Selendra RPC setup with HTTPS..."
    
    # Check and install dependencies
    check_dependencies
    
    # Get domain name from user
    DOMAIN_NAME=$(get_domain_name)
    
    # Download Selendra binary
    download_selendra
    
    # Get node configuration
    IFS=$'\n'
    NODE_CONFIG=($(get_node_config))
    
    NODE_NAME=$(echo "${NODE_CONFIG[0]}" | cut -d= -f2)
    DB_PATH=$(echo "${NODE_CONFIG[1]}" | cut -d= -f2)
    RPC_PORT=$(echo "${NODE_CONFIG[2]}" | cut -d= -f2)
    P2P_PORT=$(echo "${NODE_CONFIG[3]}" | cut -d= -f2)
    
    # Ensure the base directory exists
    mkdir -p "$DB_PATH"
    
    # Set up Nginx
    setup_nginx $DOMAIN_NAME
    
    # Get server IP
    SERVER_IP=$(get_server_ip)
    
    # Check if domain points to this server
    if ! check_domain_dns $DOMAIN_NAME $SERVER_IP; then
        print_warning "Please update your DNS settings to point $DOMAIN_NAME to $SERVER_IP"
        
        # Ask if user wants to continue or wait
        echo ""
        echo "Options:"
        echo "1) Continue anyway (SSL setup might fail if DNS is not properly configured)"
        echo "2) Wait for DNS propagation (recommended)"
        echo "3) Add an entry to /etc/hosts for testing (not recommended for production)"
        echo ""
        read -p "Enter your choice (1-3): " DNS_CHOICE
        
        case $DNS_CHOICE in
            1)
                print_warning "Continuing without DNS verification. SSL setup might fail."
                ;;
            2)
                read -p "Press Enter to continue once you've updated your DNS settings..."
                
                # Wait for DNS propagation
                print_message "Waiting for DNS propagation (may take a few minutes)..."
                for i in {1..12}; do
                    if check_domain_dns $DOMAIN_NAME $SERVER_IP; then
                        print_message "DNS verification successful!"
                        break
                    fi
                    if [ $i -eq 12 ]; then
                        print_warning "DNS propagation timeout. Continuing anyway."
                    else
                        print_message "Waiting for DNS propagation (attempt $i/12)..."
                        sleep 10
                    fi
                done
                ;;
            3)
                # Add to /etc/hosts
                print_message "Adding $DOMAIN_NAME to /etc/hosts for testing..."
                if grep -q "$DOMAIN_NAME" /etc/hosts; then
                    # Update existing entry
                    sed -i "s/.*$DOMAIN_NAME/$SERVER_IP $DOMAIN_NAME/" /etc/hosts
                else
                    # Add new entry
                    echo "$SERVER_IP $DOMAIN_NAME" >> /etc/hosts
                fi
                print_warning "Added to /etc/hosts. This is only for testing and won't work for external access."
                ;;
            *)
                print_warning "Invalid choice. Continuing without DNS verification."
                ;;
        esac
    fi
    
    # Set up SSL with certbot
    setup_ssl $DOMAIN_NAME
    
    # Create systemd service
    create_systemd_service $DOMAIN_NAME "$NODE_NAME" "$DB_PATH" "$RPC_PORT" "$P2P_PORT"
    
    # Print completion message
    cat << EOL

${GREEN}==================================================${NC}
${GREEN}       Selendra RPC Setup Complete!              ${NC}
${GREEN}==================================================${NC}

Your Selendra RPC node has been set up with the following configuration:

Domain: ${YELLOW}$DOMAIN_NAME${NC}
Server IP: ${YELLOW}$SERVER_IP${NC}
Node Name: ${YELLOW}$NODE_NAME${NC}
RPC Endpoint: ${YELLOW}https://$DOMAIN_NAME${NC}
Database Path: ${YELLOW}$DB_PATH${NC}
RPC Port: ${YELLOW}$RPC_PORT${NC}
P2P Port: ${YELLOW}$P2P_PORT${NC}

A single command has been installed for easy service management:

  ${YELLOW}selendra-rpc${NC}

Usage:
  ${YELLOW}selendra-rpc start${NC}        - Start the Selendra RPC service
  ${YELLOW}selendra-rpc stop${NC}         - Stop the Selendra RPC service
  ${YELLOW}selendra-rpc restart${NC}      - Restart the Selendra RPC service
  ${YELLOW}selendra-rpc status${NC}       - Check the status of the Selendra RPC service
  ${YELLOW}selendra-rpc logs${NC}         - View the Selendra RPC service logs in real-time
  ${YELLOW}selendra-rpc nginx-reload${NC} - Reload Nginx configuration
  ${YELLOW}selendra-rpc nginx-test${NC}   - Test Nginx configuration
  ${YELLOW}selendra-rpc ssl-test${NC}     - Test SSL certificate renewal
  ${YELLOW}selendra-rpc ssl-renew${NC}    - Force SSL certificate renewal
  ${YELLOW}selendra-rpc help${NC}         - Display all available commands

This command is available system-wide and can be run from any directory.

SSL certificates will automatically renew via certbot's timer.

${GREEN}==================================================${NC}
EOL
}

# Run the main function
main