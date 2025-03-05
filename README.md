# Selendra RPC Node Setup Script

A comprehensive automation script for setting up a Selendra RPC node with HTTPS support across various Linux distributions.

## ⚠️ Important: DNS Configuration First

**Before running this script, make sure your domain's DNS A record points to your server's IP address!**

The SSL certificate setup will fail if your domain doesn't resolve to your server. The script includes verification and waiting options, but setting up DNS in advance will make the installation smoother.

1. Create an A record for your domain (e.g., `rpcx.selendra.org`)
2. Point it to your server's IP address
3. Wait for DNS propagation (can take up to 24-48 hours, but often just minutes)

## Features

- **Cross-Distribution Support**: Works on Arch Linux, Debian, Ubuntu, Fedora, RHEL, CentOS, and more
- **Automatic Installation**: Handles all dependencies including Nginx and Certbot
- **SSL/HTTPS Configuration**: Automatic HTTPS setup with Let's Encrypt certificates
- **Custom Domain Support**: Configure your own domain name for the RPC endpoint
- **Systemd Integration**: Creates and configures systemd service for automatic startup
- **Unified Management**: Simple command-line tool for managing all aspects of your node

## Prerequisites

- A Linux server with root/sudo access
- **A domain name with DNS A record already pointing to your server IP**
- Open ports 80 and 443 (for HTTP/HTTPS)
- Open port 40333 (default P2P port, configurable)

## Quick Installation

```bash
# Option 1: Download with wget
wget https://github.com/selendra/selendra-rpc/raw/main/selendra-rpc-setup.sh -O selendra-rpc-setup.sh

# Option 2: Download with curl
curl -L https://github.com/selendra/selendra-rpc/raw/main/selendra-rpc-setup.sh -o selendra-rpc-setup.sh

# Make it executable
chmod +x selendra-rpc-setup.sh

# Run with sudo
sudo ./selendra-rpc-setup.sh
```

## What the Script Does

1. **Detects your Linux distribution** and installs required dependencies
2. **Downloads the latest Selendra binary** from GitHub
3. **Sets up Nginx** as a reverse proxy with proper configurations
4. **Obtains SSL certificates** via Let's Encrypt (certbot)
5. **Creates a systemd service** for running the Selendra node
6. **Installs management tools** for easy administration

## Interactive Configuration

During installation, you'll be prompted for:

- **Domain name**: Your RPC endpoint domain (e.g., rpcx.selendra.org)
- **Node name**: How your node will appear on the network
- **Database path**: Where chain data will be stored
- **RPC port**: Default is 9933
- **P2P port**: Default is 40333
- **Email address**: For SSL certificate notifications

## Managing Your Node

After installation, you can use the `selendra-rpc` command to manage all aspects of your node:

```bash
# View available commands
selendra-rpc help

# Basic service management
selendra-rpc start     # Start the Selendra RPC service
selendra-rpc stop      # Stop the Selendra RPC service
selendra-rpc restart   # Restart the Selendra RPC service
selendra-rpc status    # Check service status
selendra-rpc logs      # View real-time logs

# Nginx management
selendra-rpc nginx-reload  # Reload Nginx configuration
selendra-rpc nginx-test    # Test Nginx configuration

# SSL certificate management
selendra-rpc ssl-test      # Test certificate renewal
selendra-rpc ssl-renew     # Force certificate renewal
```

## Service Configuration

The Selendra node runs with the following default parameters:

```
--chain selendra         # Selendra mainnet
--rpc-external           # Accept external RPC connections
--rpc-cors all           # Allow all origins for CORS
--pool-limit 1024        # Connection pool limit
--db-cache 1024          # Database cache size (MB)
--runtime-cache-size 2   # Runtime cache size
--max-runtime-instances 8 # Maximum runtime instances
```

## DNS Configuration

**🚨 CRITICAL: Configure your DNS BEFORE running the script!**

For the SSL setup to work correctly, your domain must point to your server:

1. Log in to your domain registrar or DNS provider
2. Create an A record for your domain (e.g., `rpcx.selendra.org`)
3. Enter your server's IP address as the value
4. Save the changes and wait for propagation

You can verify DNS propagation with:
```bash
dig +short your-domain.com
# or
nslookup your-domain.com
```

The output should show your server's IP address. If it doesn't, wait longer for propagation or check your DNS configuration.

The script includes DNS verification and will guide you through options if DNS isn't properly configured, but setting it up in advance will prevent certificate issuance failures.

## Troubleshooting

If you encounter issues:

1. Check the service status: `selendra-rpc status`
2. View the logs: `selendra-rpc logs`
3. Verify Nginx configuration: `selendra-rpc nginx-test`
4. Test SSL certificates: `selendra-rpc ssl-test`

## Customization

The script creates configuration files in the following locations:

- Nginx configuration: `/etc/nginx/sites-available/yourdomain.conf`
- Systemd service: `/etc/systemd/system/selendra.service`
- Selendra binary: `/usr/local/bin/selendra-node`
- SSL certificates: `/etc/letsencrypt/live/yourdomain/`

You can manually edit these files for advanced customization.

## Security Considerations

- The script sets up HTTPS with modern SSL parameters
- Automatic certificate renewal is configured
- Strict Transport Security headers are added
- The RPC endpoint is publicly accessible (be aware of potential abuse)

## Updating

To update the Selendra binary:

1. Stop the service: `selendra-rpc stop`
2. Download the new binary and replace the existing one
3. Start the service: `selendra-rpc start`

## License

This script is provided under the MIT License.

## Acknowledgments

- Selendra Network for developing the blockchain
- Let's Encrypt for providing free SSL certificates
- Nginx for the powerful reverse proxy capabilities

## Contributors

- Selendra Foundation
- Community Contributors

## Support

For assistance with this script, please [create an issue](https://github.com/selendra/selendra-rpc/issues) on GitHub.

For Selendra-specific questions, refer to the [Selendra documentation](https://docs.selendra.org).