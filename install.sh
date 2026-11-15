#!/usr/bin/env bash
# ==============================================================
# ForumREXAR - One-Click Server Installer
# Docker image: forumrexar/forumrexar
#
# Usage:
#   curl -sSL https://forum.rexar.net/cdn/2026/install.sh | sudo bash
#
# Unattended install with a domain:
#   curl -sSL .../install.sh | sudo REXAR_DOMAIN=forum.example.com REXAR_EMAIL=you@example.com bash
#
# All output is plain ASCII English so it displays correctly on any
# server locale or SSH client.
# ==============================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/forumrexar"
APP_PORT="38980"
IMAGE="forumrexar/forumrexar:latest"

HAS_TTY=false
SERVER_IP=""
DOMAIN_NAME=""
SSL_EMAIL=""
NGINX_READY=false
SSL_READY=false
EXISTING_INSTALL=false

line()  { echo -e "${BLUE}==============================================================${NC}"; }
step()  { echo -e "\n${YELLOW}>> $1${NC}"; }
ok()    { echo -e "${GREEN}[OK] $1${NC}"; }
warn()  { echo -e "${YELLOW}[WARNING] $1${NC}"; }
fail()  { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }

# Piped scripts have the script itself on stdin, so answers must come from the terminal.
detect_tty() {
    if { : < /dev/tty; } 2>/dev/null; then
        HAS_TTY=true
    fi
}

ask() {
    local __prompt="$1" __target="$2" __reply=""
    if [ "$HAS_TTY" = true ]; then
        printf "%s" "$__prompt" > /dev/tty
        IFS= read -r __reply < /dev/tty || __reply=""
    fi
    printf -v "$__target" '%s' "$__reply"
}

check_system() {
    if [ "$EUID" -ne 0 ]; then
        fail "Please run this installer as root, for example: sudo bash install.sh"
    fi

    local arch os_id=""
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64|aarch64|arm64) ;;
        *) fail "Unsupported CPU architecture: $arch (supported: amd64, arm64)" ;;
    esac

    if [ -r /etc/os-release ]; then
        os_id=$(. /etc/os-release && echo "${ID:-}")
    fi
    if [ "$os_id" = "amzn" ]; then
        fail "Amazon Linux is not supported. Please use an Ubuntu or Debian server image."
    fi
    ok "System check passed ($arch)"
}

detect_server_ip() {
    local url ip
    for url in https://ifconfig.me https://icanhazip.com https://api.ipify.org; do
        ip=$(curl -4 -fsS --max-time 6 "$url" 2>/dev/null | tr -d '[:space:]') || ip=""
        if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            SERVER_IP="$ip"
            return 0
        fi
    done
    SERVER_IP="YOUR_SERVER_IP"
}

normalize_domain() {
    local value="$1"
    value=$(printf '%s' "$value" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    value="${value#http://}"
    value="${value#https://}"
    value="${value%%/*}"
    value="${value%%:*}"
    value="${value%.}"
    printf '%s' "$value"
}

valid_domain() {
    [[ "$1" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]
}

valid_email() {
    [[ "$1" =~ ^[^[:space:]@\"\'\`\$\;\&\|\<\>\(\)\\]+@[^[:space:]@\"\'\`\$\;\&\|\<\>\(\)\\]+\.[^[:space:]@\"\'\`\$\;\&\|\<\>\(\)\\]+$ ]]
}

# Returns 0 when the domain points here, 1 when it points elsewhere, 2 when it has no record.
check_dns() {
    local records
    records=$(getent ahostsv4 "$1" 2>/dev/null | awk '{print $1}' | sort -u) || records=""
    if [ -z "$records" ]; then
        return 2
    fi
    if printf '%s\n' "$records" | grep -qx "$SERVER_IP"; then
        return 0
    fi
    return 1
}

confirm_dns() {
    local status choice records
    while true; do
        status=0
        check_dns "$DOMAIN_NAME" || status=$?
        if [ "$status" -eq 0 ]; then
            ok "$DOMAIN_NAME points to this server ($SERVER_IP)"
            return 0
        fi

        if [ "$status" -eq 1 ]; then
            records=$(getent ahostsv4 "$DOMAIN_NAME" | awk '{print $1}' | sort -u | tr '\n' ' ')
            warn "$DOMAIN_NAME points to ${records}instead of this server ($SERVER_IP)."
            warn "If you use Cloudflare, set the DNS record to DNS only (grey cloud)."
        else
            warn "$DOMAIN_NAME has no DNS record yet."
        fi
        echo "Add this record at your domain provider:"
        echo -e "  ${CYAN}Type: A    Name: $DOMAIN_NAME    Value: $SERVER_IP${NC}"
        echo ""
        echo "  1) Check again (DNS changes can take a few minutes)"
        echo "  2) Continue with this domain anyway"
        echo "  3) Install without a domain"
        ask ">> Your choice [1/2/3] (default 1): " choice
        case "$choice" in
            2) return 0 ;;
            3)
                DOMAIN_NAME=""
                SSL_EMAIL=""
                return 0
                ;;
            *) sleep 5 ;;
        esac
    done
}

ask_domain() {
    if [ -n "${REXAR_DOMAIN:-}" ]; then
        DOMAIN_NAME=$(normalize_domain "$REXAR_DOMAIN")
        SSL_EMAIL="${REXAR_EMAIL:-}"
        valid_domain "$DOMAIN_NAME" || fail "REXAR_DOMAIN is not a valid domain: $DOMAIN_NAME"
        valid_email "$SSL_EMAIL" || fail "REXAR_EMAIL must be a valid email address when REXAR_DOMAIN is set."
        return 0
    fi

    if [ "$HAS_TTY" != true ]; then
        warn "No terminal available, installing without a domain."
        echo "To add a domain, run the installer again with REXAR_DOMAIN and REXAR_EMAIL."
        return 0
    fi

    line
    echo -e "${CYAN}Domain and free SSL certificate (HTTPS)${NC}"
    line
    echo "With a domain or subdomain (example: forum.mysite.com) the installer"
    echo "configures Nginx and a free Let's Encrypt certificate for you."
    echo "Without one, your forum will run on the server IP and port $APP_PORT."
    echo "Using Cloudflare? Set the DNS record to DNS only (grey cloud), not Proxied."
    echo ""

    local answer domain email
    ask ">> Do you have a domain for this forum? (y/n) [n]: " answer
    if ! [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Continuing without a domain."
        return 0
    fi

    while true; do
        ask ">> Domain or subdomain (example: forum.mysite.com): " domain
        domain=$(normalize_domain "$domain")
        if valid_domain "$domain"; then
            DOMAIN_NAME="$domain"
            break
        fi
        warn "That does not look like a valid domain. Please try again."
    done

    while true; do
        ask ">> Email address for SSL renewal notices: " email
        email=$(printf '%s' "$email" | tr -d '[:space:]')
        if valid_email "$email"; then
            SSL_EMAIL="$email"
            break
        fi
        warn "That does not look like a valid email address. Please try again."
    done

    confirm_dns
}

install_docker() {
    if ! command -v docker > /dev/null 2>&1; then
        step "Docker not found, installing it now..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable --now docker
        ok "Docker installed"
    else
        ok "Docker is already installed"
    fi

    if ! docker info > /dev/null 2>&1; then
        systemctl start docker 2>/dev/null || true
        docker info > /dev/null 2>&1 || fail "Docker is installed but not running. Check: systemctl status docker"
    fi

    if ! docker compose version > /dev/null 2>&1; then
        step "Installing the Docker Compose plugin..."
        if command -v apt-get > /dev/null 2>&1; then
            apt-get update -qq
            apt-get install -y -qq docker-compose-plugin || apt-get install -y -qq docker-compose-v2 || true
        elif command -v dnf > /dev/null 2>&1; then
            dnf install -y -q docker-compose-plugin || true
        fi
        docker compose version > /dev/null 2>&1 || fail "Docker Compose is missing. Please install the docker compose plugin and run this installer again."
    fi
    ok "Docker Compose is ready"
}

write_compose() {
    mkdir -p "$INSTALL_DIR/data" "$INSTALL_DIR/uploads"
    chmod 755 "$INSTALL_DIR/data" "$INSTALL_DIR/uploads"
    cd "$INSTALL_DIR"

    # An existing forum keeps its own settings and data untouched.
    if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
        EXISTING_INSTALL=true
        local port
        port=$(sed -n 's/^[[:space:]]*-[[:space:]]*"\([0-9][0-9]*\):8080".*/\1/p' docker-compose.yml | head -n 1)
        if [ -n "$port" ]; then
            APP_PORT="$port"
        fi
        ok "Existing installation found, keeping docker-compose.yml"
        return 0
    fi

    cat > "$INSTALL_DIR/docker-compose.yml" << EOF
services:
  forumrexar:
    image: ${IMAGE}
    container_name: forumrexar
    restart: unless-stopped
    ports:
      - "${APP_PORT}:8080"
    volumes:
      - ./data:/app/data
      - ./uploads:/app/web/static/uploads
    environment:
      - PORT=8080
      - APP_ENV=production
      - APP_NAME=ForumREXAR
      - TZ=Asia/Riyadh
EOF
    ok "Created docker-compose.yml (port $APP_PORT)"
}

start_forum() {
    cd "$INSTALL_DIR"
    docker compose pull
    docker compose up -d

    local _ code
    for _ in $(seq 1 30); do
        code=$(curl -s -o /dev/null --max-time 3 -w '%{http_code}' "http://127.0.0.1:${APP_PORT}/install" 2>/dev/null) || code="000"
        if [ "$code" -ge 200 ] && [ "$code" -lt 500 ]; then
            ok "The forum is running"
            return 0
        fi
        sleep 2
    done

    docker compose logs --tail 20 || true
    fail "The forum did not start. Logs are shown above. Check them with: cd $INSTALL_DIR && docker compose logs -f"
}

open_firewall() {
    local ports="$APP_PORT"
    if [ -n "$DOMAIN_NAME" ]; then
        ports="$ports 80 443"
    fi

    local port
    if command -v ufw > /dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        for port in $ports; do
            ufw allow "$port/tcp" > /dev/null || true
        done
        ok "Opened ports in ufw: $ports"
    elif command -v firewall-cmd > /dev/null 2>&1 && firewall-cmd --state > /dev/null 2>&1; then
        for port in $ports; do
            firewall-cmd --permanent --add-port="$port/tcp" > /dev/null || true
        done
        firewall-cmd --reload > /dev/null || true
        ok "Opened ports in firewalld: $ports"
    fi
}

# Prints what is listening on a web port when it is anything other than Nginx.
web_port_blocker() {
    command -v ss > /dev/null 2>&1 || return 0
    local port listeners
    for port in 80 443; do
        listeners=$(ss -H -ltnp "sport = :$port" 2>/dev/null) || listeners=""
        if [ -n "$listeners" ] && ! printf '%s' "$listeners" | grep -q '"nginx"'; then
            printf '%s\n' "$listeners" | sed -n 's/.*users:(("\([^"]*\)".*/\1/p' | head -n 1
            printf 'port %s' "$port"
            return 0
        fi
    done
}

install_nginx_packages() {
    if command -v apt-get > /dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq || return 1
        apt-get install -y -qq nginx certbot python3-certbot-nginx || return 1
    elif command -v dnf > /dev/null 2>&1; then
        dnf install -y -q epel-release || true
        dnf install -y -q nginx certbot python3-certbot-nginx || return 1
    else
        warn "No supported package manager found (apt-get or dnf)."
        return 1
    fi
    systemctl enable --now nginx || return 1
}

nginx_conf_path() {
    if [ -d /etc/nginx/sites-enabled ] && grep -q "sites-enabled" /etc/nginx/nginx.conf 2>/dev/null; then
        echo "/etc/nginx/sites-available/forumrexar.conf"
    else
        echo "/etc/nginx/conf.d/forumrexar.conf"
    fi
}

write_nginx_conf() {
    local conf="$1" listen_v6=""
    if [ -f /proc/net/if_inet6 ]; then
        listen_v6="    listen [::]:80;"
    fi

    cat > "$conf" << EOF
# ForumREXAR reverse proxy. Chat needs the upgrade headers and live
# notifications need buffering off.
map \$http_upgrade \$forumrexar_connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen 80;
${listen_v6}
    server_name ${DOMAIN_NAME};

    client_max_body_size 25M;

    location / {
        proxy_pass http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$forumrexar_connection_upgrade;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_buffering off;
    }
}
EOF

    if [ "$conf" = "/etc/nginx/sites-available/forumrexar.conf" ]; then
        ln -sf "$conf" /etc/nginx/sites-enabled/forumrexar.conf
    fi
}

remove_nginx_conf() {
    rm -f /etc/nginx/sites-enabled/forumrexar.conf "$1"
}

setup_nginx() {
    local blocker conf
    blocker=$(web_port_blocker | tr '\n' ' ')
    if [ -n "$blocker" ]; then
        warn "Web ports are in use: $blocker"
        warn "Nginx was not configured, so your existing web server is not affected."
        echo "Point your web server at http://127.0.0.1:${APP_PORT} for $DOMAIN_NAME."
        return 1
    fi

    step "Installing Nginx and Certbot..."
    if ! install_nginx_packages; then
        warn "Could not install Nginx and Certbot."
        return 1
    fi

    conf=$(nginx_conf_path)
    mkdir -p "$(dirname "$conf")"
    if [ -f "$conf" ] && grep -q "managed by Certbot" "$conf"; then
        ok "Existing HTTPS configuration found, keeping it"
        NGINX_READY=true
        SSL_READY=true
        return 0
    fi

    write_nginx_conf "$conf"
    if ! nginx -t > /dev/null 2>&1; then
        nginx -t || true
        remove_nginx_conf "$conf"
        warn "The Nginx test failed, so the forum configuration was removed."
        return 1
    fi
    if ! systemctl reload nginx && ! systemctl restart nginx; then
        remove_nginx_conf "$conf"
        warn "Nginx could not be reloaded, so the forum configuration was removed."
        return 1
    fi
    NGINX_READY=true
    ok "Nginx is serving $DOMAIN_NAME"
}

setup_ssl() {
    step "Requesting a free SSL certificate from Let's Encrypt..."
    if certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$SSL_EMAIL" --redirect --keep-until-expiring; then
        SSL_READY=true
        systemctl enable --now certbot-renew.timer > /dev/null 2>&1 || true
        ok "HTTPS is active and will renew automatically"
    else
        warn "The SSL certificate could not be issued. The forum still works over HTTP."
        echo "Common causes:"
        echo "  - The A record of $DOMAIN_NAME does not point to $SERVER_IP yet."
        echo "  - Ports 80 and 443 are closed in your cloud provider firewall."
        echo "  - Let's Encrypt rejected the email address."
        echo "After fixing this, run:"
        echo -e "  ${CYAN}sudo certbot --nginx -d $DOMAIN_NAME${NC}"
    fi
}

print_summary() {
    local url="http://${SERVER_IP}:${APP_PORT}/install"
    local ip_url="$url"
    if [ "$SSL_READY" = true ]; then
        url="https://${DOMAIN_NAME}/install"
    elif [ "$NGINX_READY" = true ]; then
        url="http://${DOMAIN_NAME}/install"
    fi

    echo ""
    line
    echo -e "${GREEN}ForumREXAR is installed and running!${NC}"
    line
    if [ "$EXISTING_INSTALL" = true ]; then
        echo "Open your forum:"
    else
        echo "Open this link to finish setup and create your admin account:"
    fi
    echo -e "${CYAN}${url}${NC}"
    if [ "$url" != "$ip_url" ]; then
        echo "Direct access by IP: $ip_url"
    fi
    echo ""
    echo "If the link does not open, allow port $APP_PORT (and 80, 443 with a domain)"
    echo "in your cloud provider firewall or security group."
    line
    echo "Useful commands:"
    echo "  Stop:    cd $INSTALL_DIR && docker compose down"
    echo "  Restart: cd $INSTALL_DIR && docker compose restart"
    echo "  Update:  cd $INSTALL_DIR && docker compose pull && docker compose up -d"
    echo "  Logs:    cd $INSTALL_DIR && docker compose logs -f"
    line
    echo ""
}

main() {
    line
    echo -e "${GREEN}ForumREXAR Installer${NC}"
    line

    detect_tty
    check_system
    detect_server_ip
    ask_domain

    step "[1/4] Checking Docker..."
    install_docker

    step "[2/4] Preparing $INSTALL_DIR..."
    write_compose

    step "[3/4] Downloading and starting the forum..."
    start_forum

    step "[4/4] Finishing network setup..."
    open_firewall
    if [ -n "$DOMAIN_NAME" ]; then
        if setup_nginx && [ "$SSL_READY" != true ]; then
            setup_ssl
        fi
    else
        echo "No domain selected. To add one later, run this installer again."
    fi

    print_summary
}

# Running from a function means a partly downloaded script executes nothing.
main "$@"
