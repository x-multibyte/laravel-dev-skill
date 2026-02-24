#!/usr/bin/env bash
# Laravel Valet development environment configuration

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

# Check if Valet is installed
check_valet() {
    if ! command_exists "valet"; then
        log_error "Laravel Valet is not installed"
        log_info "Install Valet with: composer global require laravel/valet"
        log_info "Then run: valet install"
        exit 1
    fi
}

# Check command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install Valet
install_valet() {
    log_info "Installing Laravel Valet..."
    
    # Check if composer is available
    if ! command_exists "composer"; then
        log_error "Composer is not installed"
        exit 1
    fi
    
    # Install Valet globally
    composer global require laravel/valet
    
    # Install Valet
    valet install
    
    log_info "Valet installed successfully"
}

# Configure Valet for a project
configure_project() {
    local project_name=${1:-""}
    
    if [[ -z "$project_name" ]]; then
        project_name=$(basename "$PWD")
    fi
    
    log_info "Configuring Valet for project: $project_name"
    
    # Link current directory to Valet
    valet link "$project_name"
    
    log_info "Project linked successfully"
    log_info "Access your app at: http://$project_name.test"
}

# Secure project with SSL
secure_project() {
    local project_name=${1:-""}
    
    if [[ -z "$project_name" ]]; then
        project_name=$(basename "$PWD")
    fi
    
    log_info "Securing project with SSL: $project_name"
    
    valet secure "$project_name"
    
    log_info "Project secured successfully"
    log_info "Access your app at: https://$project_name.test"
}

# Unsecure project
unsecure_project() {
    local project_name=${1:-""}
    
    if [[ -z "$project_name" ]]; then
        project_name=$(basename "$PWD")
    fi
    
    log_info "Removing SSL from project: $project_name"
    
    valet unsecure "$project_name"
    
    log_info "SSL removed successfully"
    log_info "Access your app at: http://$project_name.test"
}

# Show Valet status
show_status() {
    log_info "Valet Status:"
    echo ""
    valet status
    echo ""
    
    log_info "Valet Paths:"
    valet paths
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Laravel Valet development environment configuration.

OPTIONS:
    -i, --install          Install Laravel Valet
    -c, --configure [NAME] Configure Valet for current project
    -s, --secure [NAME]    Secure project with SSL
    -u, --unsecure [NAME]  Remove SSL from project
    -t, --status           Show Valet status
    -h, --help             Show this help message

EXAMPLES:
    $0 --install
    $0 --configure my-app
    $0 --secure my-app
    $0 --status

EOF
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--install)
                install_valet
                shift
                ;;
            -c|--configure)
                check_valet
                configure_project "${2:-}"
                shift 2
                ;;
            -s|--secure)
                check_valet
                secure_project "${2:-}"
                shift 2
                ;;
            -u|--unsecure)
                check_valet
                unsecure_project "${2:-}"
                shift 2
                ;;
            -t|--status)
                check_valet
                show_status
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
    
    log_info "Valet configuration completed!"
}

main "$@"