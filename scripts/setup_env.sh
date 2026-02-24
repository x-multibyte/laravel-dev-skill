#!/usr/bin/env bash
# Environment configuration wizard for Laravel projects

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if in Laravel project
check_laravel_project() {
    if [[ ! -f "artisan" ]]; then
        log_error "Not in a Laravel project directory"
        exit 1
    fi
}

# Generate .env.example
generate_env_example() {
    log_info "Generating .env.example file..."
    
    cat > .env.example << 'EOF'
APP_NAME="Laravel"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_TIMEZONE=UTC
APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=mt1

VITE_PUSHER_APP_KEY="${PUSHER_APP_KEY}"
VITE_PUSHER_HOST="${PUSHER_HOST}"
VITE_PUSHER_PORT="${PUSHER_PORT}"
VITE_PUSHER_SCHEME="${PUSHER_SCHEME}"
VITE_PUSHER_APP_CLUSTER="${PUSHER_APP_CLUSTER}"
EOF
    
    log_info ".env.example generated successfully"
}

# Interactive environment configuration
interactive_setup() {
    log_info "Starting interactive environment configuration..."
    
    # Copy .env.example to .env if .env doesn't exist
    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            log_info "Created .env from .env.example"
        else
            generate_env_example
            cp .env.example .env
        fi
    fi
    
    # Read current values
    source .env
    
    # Ask for configuration
    read -p "App Name [$APP_NAME]: " input
    APP_NAME=${input:-$APP_NAME}
    
    read -p "App Environment [$APP_ENV] (local/production): " input
    APP_ENV=${input:-$APP_ENV}
    
    if [[ "$APP_ENV" == "production" ]]; then
        APP_DEBUG="false"
    else
        APP_DEBUG="true"
    fi
    
    read -p "App URL [$APP_URL]: " input
    APP_URL=${input:-$APP_URL}
    
    # Database configuration
    echo ""
    log_info "Database Configuration"
    read -p "Database Connection [$DB_CONNECTION]: " input
    DB_CONNECTION=${input:-$DB_CONNECTION}
    
    read -p "Database Host [$DB_HOST]: " input
    DB_HOST=${input:-$DB_HOST}
    
    read -p "Database Port [$DB_PORT]: " input
    DB_PORT=${input:-$DB_PORT}
    
    read -p "Database Name [$DB_DATABASE]: " input
    DB_DATABASE=${input:-$DB_DATABASE}
    
    read -p "Database Username [$DB_USERNAME]: " input
    DB_USERNAME=${input:-$DB_USERNAME}
    
    read -sp "Database Password: " input
    DB_PASSWORD=${input:-$DB_PASSWORD}
    echo ""
    
    # Update .env file
    sed -i.bak "s|^APP_NAME=.*|APP_NAME=\"$APP_NAME\"|" .env
    sed -i.bak "s|^APP_ENV=.*|APP_ENV=\"$APP_ENV\"|" .env
    sed -i.bak "s|^APP_DEBUG=.*|APP_DEBUG=$APP_DEBUG|" .env
    sed -i.bak "s|^APP_URL=.*|APP_URL=\"$APP_URL\"|" .env
    sed -i.bak "s|^DB_CONNECTION=.*|DB_CONNECTION=\"$DB_CONNECTION\"|" .env
    sed -i.bak "s|^DB_HOST=.*|DB_HOST=\"$DB_HOST\"|" .env
    sed -i.bak "s|^DB_PORT=.*|DB_PORT=$DB_PORT|" .env
    sed -i.bak "s|^DB_DATABASE=.*|DB_DATABASE=\"$DB_DATABASE\"|" .env
    sed -i.bak "s|^DB_USERNAME=.*|DB_USERNAME=\"$DB_USERNAME\"|" .env
    sed -i.bak "s|^DB_PASSWORD=.*|DB_PASSWORD=\"$DB_PASSWORD\"|" .env
    rm .env.bak
    
    log_info "Environment configuration updated successfully"
}

# Validate configuration
validate_config() {
    log_info "Validating environment configuration..."
    
    if [[ ! -f ".env" ]]; then
        log_error ".env file not found"
        return 1
    fi
    
    # Check for required variables
    local required_vars=("APP_NAME" "APP_ENV" "APP_KEY" "DB_CONNECTION" "DB_DATABASE")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" .env; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_warn "Missing required variables: ${missing_vars[*]}"
    fi
    
    # Check if APP_KEY is set
    if grep -q "^APP_KEY=$" .env; then
        log_warn "APP_KEY is not set. Running: php artisan key:generate"
        php artisan key:generate
    fi
    
    log_info "Configuration validation completed"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Environment configuration wizard for Laravel projects.

OPTIONS:
    -g, --generate      Generate .env.example file
    -i, --interactive   Interactive configuration
    -v, --validate      Validate .env configuration
    -h, --help          Show this help message

EXAMPLES:
    $0 --generate
    $0 --interactive
    $0 --validate

EOF
}

# Main function
main() {
    check_laravel_project
    
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -g|--generate)
                generate_env_example
                shift
                ;;
            -i|--interactive)
                interactive_setup
                shift
                ;;
            -v|--validate)
                validate_config
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log_info "Environment setup completed!"
}

main "$@"