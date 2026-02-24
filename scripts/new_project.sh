#!/usr/bin/env bash
# Create new Laravel project with various methods

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

# Check command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check dependencies
check_dependencies() {
    local deps=("php" "composer")
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            log_error "Required dependency '$dep' not found"
            exit 1
        fi
    done
    
    log_info "All dependencies satisfied"
}

# Create project with Composer
create_with_composer() {
    local name=$1
    local version=${2:-""}
    
    log_info "Creating Laravel project with Composer..."
    
    if [[ -n "$version" ]]; then
        composer create-project "laravel/laravel:${version}" "$name" --prefer-dist
    else
        composer create-project laravel/laravel "$name" --prefer-dist
    fi
}

# Create project with Laravel Installer
create_with_installer() {
    local name=$1
    local version=${2:-""}
    
    if ! command_exists "laravel"; then
        log_warn "Laravel Installer not found. Installing..."
        composer global require laravel/installer
    fi
    
    log_info "Creating Laravel project with Laravel Installer..."
    
    if [[ -n "$version" ]]; then
        laravel new "$name" --"$version"
    else
        laravel new "$name"
    fi
}

# Create project with Laravel Herd
create_with_herd() {
    local name=$1
    
    if ! command_exists "herd"; then
        log_error "Laravel Herd not found. Please install Herd first."
        log_info "Visit: https://herd.laravel.com"
        exit 1
    fi
    
    log_info "Creating Laravel project with Laravel Herd..."
    herd new "$name"
}

# Configure basic settings
configure_project() {
    local project_dir=$1
    
    log_info "Configuring basic settings..."
    
    cd "$project_dir"
    
    # Set timezone
    sed -i.bak "s/'timezone' => 'UTC'/'timezone' => 'Asia\/Shanghai'/" config/app.php
    rm config/app.php.bak
    
    # Set locale
    sed -i.bak "s/'locale' => 'en'/'locale' => 'zh_CN'/" config/app.php
    rm config/app.php.bak
    
    # Generate app key if not exists
    if [[ -z "$APP_KEY" ]]; then
        php artisan key:generate
    fi
    
    log_info "Project configured successfully"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] PROJECT_NAME

Create a new Laravel project with various methods.

OPTIONS:
    -m, --method METHOD    Creation method: composer, installer, herd (default: composer)
    -v, --version VERSION  Laravel version (e.g., 12.x, 11.x, 10.x)
    -h, --help             Show this help message

EXAMPLES:
    $0 my-app
    $0 --method installer my-app
    $0 --method composer --version 12.x my-app
    $0 --method herd my-app

EOF
}

# Main function
main() {
    local method="composer"
    local version=""
    local project_name=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--method)
                method="$2"
                shift 2
                ;;
            -v|--version)
                version="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                project_name="$1"
                shift
                ;;
        esac
    done
    
    # Validate project name
    if [[ -z "$project_name" ]]; then
        log_error "Project name is required"
        show_usage
        exit 1
    fi
    
    # Check if project directory already exists
    if [[ -d "$project_name" ]]; then
        log_error "Directory '$project_name' already exists"
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Create project based on method
    case $method in
        composer)
            create_with_composer "$project_name" "$version"
            ;;
        installer)
            create_with_installer "$project_name" "$version"
            ;;
        herd)
            create_with_herd "$project_name"
            ;;
        *)
            log_error "Unknown method: $method"
            log_info "Available methods: composer, installer, herd"
            exit 1
            ;;
    esac
    
    # Configure project
    configure_project "$project_name"
    
    log_info "Laravel project '$project_name' created successfully!"
    log_info "Next steps:"
    log_info "  cd $project_name"
    log_info "  php artisan serve"
}

main "$@"