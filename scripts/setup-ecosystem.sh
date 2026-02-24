#!/bin/bash

###############################################################################
# Laravel Ecosystem Quick Configuration Script
#
# Purpose: Quickly configure Sail, Reverb, Echo and other Laravel ecosystem packages
# Usage: bash scripts/setup-ecosystem.sh [options]
#
# Options:
#   --sail           Configure Sail (Docker)
#   --reverb         Configure Reverb (WebSocket server)
#   --echo           Configure Echo (WebSocket client)
#   --all            Configure all ecosystem packages
#   --help           Display help information
###############################################################################

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if in Laravel project
check_laravel_project() {
    if [ ! -f "artisan" ]; then
        print_error "Current directory is not a Laravel project root"
        exit 1
    fi
    print_success "Laravel project detected"
}

# Configure Sail
setup_sail() {
    print_info "Starting Sail configuration..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker not installed, please install Docker Desktop first"
        return 1
    fi

    # Install Sail
    print_info "Installing Sail..."
    composer require laravel/sail --dev

    # Publish Sail configuration
    print_info "Publishing Sail configuration..."
    php artisan sail:install --with=mysql,redis,meilisearch,mailhog

    # Add execute permissions
    print_info "Adding execute permissions..."
    chmod +x vendor/bin/sail

    # Update .env
    print_info "Updating .env configuration..."
    sed -i.bak 's/DB_HOST=127.0.0.1/DB_HOST=mysql/' .env
    sed -i.bak 's/REDIS_HOST=127.0.0.1/REDIS_HOST=redis/' .env

    # Start Sail
    print_info "Starting Sail containers..."
    ./vendor/bin/sail up -d

    # Wait for services to start
    print_info "Waiting for services to start..."
    sleep 10

    # Run migrations
    print_info "Running database migrations..."
    ./vendor/bin/sail artisan migrate

    print_success "Sail configuration complete!"
    print_info "Access application: http://localhost"
    print_info "Access Mailhog: http://localhost:8025"
    print_info "Access Meilisearch: http://localhost:7700"
}

# Configure Reverb
setup_reverb() {
    print_info "Starting Reverb configuration..."

    # Install Reverb
    print_info "Installing Reverb..."
    composer require laravel/reverb

    # Publish configuration
    print_info "Publishing Reverb configuration..."
    php artisan reverb:install

    # Generate keys
    print_info "Generating Reverb keys..."
    php artisan reverb:generate-keys

    # Update .env
    print_info "Updating .env configuration..."
    if ! grep -q "REVERB_APP_ID" .env; then
        echo "" >> .env
        echo "# Reverb Configuration" >> .env
        echo "REVERB_APP_ID=laravel" >> .env
        echo "REVERB_APP_KEY=$(grep REVERB_APP_KEY .env | cut -d '=' -f2)" >> .env
        echo "REVERB_APP_SECRET=$(grep REVERB_APP_SECRET .env | cut -d '=' -f2)" >> .env
        echo "REVERB_HOST=0.0.0.0" >> .env
        echo "REVERB_PORT=8080" >> .env
        echo "REVERB_SCHEME=http" >> .env
        echo "VITE_REVERB_APP_KEY=\"\${REVERB_APP_KEY}\"" >> .env
        echo "VITE_REVERB_HOST=\"\${REVERB_HOST}\"" >> .env
        echo "VITE_REVERB_PORT=\"\${REVERB_PORT}\"" >> .env
        echo "VITE_REVERB_SCHEME=\"\${REVERB_SCHEME}\"" >> .env
    fi

    # Clear configuration cache
    print_info "Clearing configuration cache..."
    php artisan config:clear

    print_success "Reverb configuration complete!"
    print_info "Start Reverb: php artisan reverb:start"
    print_info "Test connection: wscat -c ws://localhost:8080/app/laravel"
}

# Configure Echo
setup_echo() {
    print_info "Starting Echo configuration..."

    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm not installed, please install Node.js first"
        return 1
    fi

    # Install Echo and Pusher.js
    print_info "Installing Echo and Pusher.js..."
    npm install --save-dev laravel-echo pusher-js

    # Check bootstrap.js
    if [ -f "resources/js/bootstrap.js" ]; then
        print_warning "resources/js/bootstrap.js already exists, please configure manually"
    else
        # Copy example configuration
        print_info "Creating bootstrap.js configuration..."
        cat > resources/js/bootstrap.js << 'EOF'
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST,
    wsPort: import.meta.env.VITE_REVERB_PORT ?? 8080,
    wssPort: import.meta.env.VITE_REVERB_PORT ?? 8080,
    forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'http') === 'https',
    enabledTransports: ['ws', 'wss'],
});
EOF
    fi

    # Check app.js
    if [ -f "resources/js/app.js" ]; then
        if ! grep -q "bootstrap" resources/js/app.js; then
            print_info "Importing bootstrap.js in app.js..."
            echo "" >> resources/js/app.js
            echo "import './bootstrap';" >> resources/js/app.js
        fi
    fi

    print_success "Echo configuration complete!"
    print_info "Run npm run dev to apply changes"
}

# Display help information
show_help() {
    cat << EOF
Laravel Ecosystem Quick Configuration Script

Usage: bash $0 [options]

Options:
  --sail           Configure Sail (Docker)
  --reverb         Configure Reverb (WebSocket server)
  --echo           Configure Echo (WebSocket client)
  --all            Configure all ecosystem packages
  --help           Display help information

Examples:
  # Configure all ecosystem packages
  bash $0 --all

  # Configure Sail only
  bash $0 --sail

  # Configure Reverb and Echo
  bash $0 --reverb --echo

Detailed configuration guide: templates/ecosystem-config-guide.md
EOF
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    check_laravel_project

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --sail)
                setup_sail
                shift
                ;;
            --reverb)
                setup_reverb
                shift
                ;;
            --echo)
                setup_echo
                shift
                ;;
            --all)
                setup_sail
                setup_reverb
                setup_echo
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    print_success "Configuration complete!"
}

# Run main function
main "$@"