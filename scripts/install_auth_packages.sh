#!/usr/bin/env bash
# Install Laravel authentication packages

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

# Install Fortify
install_fortify() {
    log_info "Installing Laravel Fortify..."
    
    composer require laravel/fortify
    php artisan fortify:install
    
    # Publish config
    php artisan vendor:publish --provider="Laravel\Fortify\FortifyServiceProvider"
    
    log_info "Fortify installed successfully"
    log_info "Next steps:"
    log_info "  - Configure routes in routes/web.php"
    log_info "  - Configure Fortify features in config/fortify.php"
}

# Install Sanctum
install_sanctum() {
    log_info "Installing Laravel Sanctum..."
    
    composer require laravel/sanctum
    php artisan sanctum:install
    
    # Publish config
    php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
    
    log_info "Sanctum installed successfully"
    log_info "Next steps:"
    log_info "  - Configure API routes in routes/api.php"
    log_info "  - Use AuthenticateSession middleware"
}

# Install Socialite
install_socialite() {
    log_info "Installing Laravel Socialite..."
    
    composer require laravel/socialite
    
    log_info "Socialite installed successfully"
    log_info "Next steps:"
    log_info "  - Add OAuth credentials to .env file"
    log_info "  - Configure providers in config/services.php"
    log_info "  - Add routes for OAuth callbacks"
}

# Install Spatie Laravel Permission
install_spatie_permission() {
    log_info "Installing Spatie Laravel Permission..."
    
    composer require spatie/laravel-permission
    php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
    php artisan migrate
    
    log_info "Spatie Laravel Permission installed successfully"
    log_info "Next steps:"
    log_info "  - Add HasRoles trait to User model"
    log_info "  - Create roles and permissions using seeder"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [PACKAGE...]

Install Laravel authentication packages.

PACKAGES:
    all                    Install all authentication packages
    fortify                Install Laravel Fortify (headless authentication)
    sanctum                Install Laravel Sanctum (API authentication)
    socialite              Install Laravel Socialite (OAuth)
    spatie                 Install Spatie Laravel Permission (RBAC)

EXAMPLES:
    $0 all
    $0 fortify sanctum
    $0 socialite

EOF
}

# Main function
main() {
    check_laravel_project
    
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    log_info "Starting authentication package installation..."
    
    for package in "$@"; do
        case $package in
            all)
                install_fortify
                install_sanctum
                install_socialite
                install_spatie_permission
                ;;
            fortify)
                install_fortify
                ;;
            sanctum)
                install_sanctum
                ;;
            socialite)
                install_socialite
                ;;
            spatie)
                install_spatie_permission
                ;;
            *)
                log_warn "Unknown package: $package"
                ;;
        esac
    done
    
    log_info "Installation completed!"
    log_info "Remember to run: composer update"
}

main "$@"