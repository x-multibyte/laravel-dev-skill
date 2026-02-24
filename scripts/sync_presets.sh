#!/bin/bash
# Laravel Dev Presets Sync Script
# Syncs presets from remote repository to local cache

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/settings.json"

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Parse configuration using jq or grep
if command -v jq &> /dev/null; then
    PRESETS_REPO=$(jq -r '.presets.repository' "$CONFIG_FILE")
    PRESETS_LOCAL_DIR=$(jq -r '.presets.local_dir' "$CONFIG_FILE")
else
    # Fallback to grep
    PRESETS_REPO=$(grep -oP '(?<="repository": ")[^"]*' "$CONFIG_FILE" | head -1)
    PRESETS_LOCAL_DIR=$(grep -oP '(?<="local_dir": ")[^"]*' "$CONFIG_FILE" | head -1)
fi

# Default values if not found
PRESETS_REPO=${PRESETS_REPO:-"https://github.com/x-multibyte/laravel-dev-presets"}
PRESETS_LOCAL_DIR="$PROJECT_ROOT/$PRESETS_LOCAL_DIR"

# Create local directory if it doesn't exist
mkdir -p "$PRESETS_LOCAL_DIR"

# Functions
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

# Check if git is available
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install git to use this script."
    exit 1
fi

# Check if curl or wget is available
if command -v curl &> /dev/null; then
    DOWNLOADER="curl"
elif command -v wget &> /dev/null; then
    DOWNLOADER="wget"
else
    print_error "Neither curl nor wget is installed. Please install one of them."
    exit 1
fi

# Sync presets from remote repository
sync_presets() {
    local force=$1
    
    print_info "Syncing presets from: $PRESETS_REPO"
    print_info "Local directory: $PRESETS_LOCAL_DIR"
    
    # Check if local directory is a git repository
    if [ -d "$PRESETS_LOCAL_DIR/.git" ]; then
        print_info "Updating existing git repository..."
        cd "$PRESETS_LOCAL_DIR"
        
        if [ "$force" = "true" ]; then
            print_warning "Force mode: resetting to remote main branch"
            git fetch origin
            git reset --hard origin/main
        else
            git pull origin main
        fi
    else
        print_info "Cloning remote repository..."
        rm -rf "$PRESETS_LOCAL_DIR"
        git clone "$PRESETS_REPO" "$PRESETS_LOCAL_DIR"
    fi
    
    print_success "Presets synced successfully!"
}

# Download specific preset
download_preset() {
    local category=$1
    local version=$2
    
    print_info "Downloading preset: $category/$version"
    
    local url="$PRESETS_REPO/raw/main/$category/$version.json"
    local output="$PRESETS_LOCAL_DIR/$category/$version.json"
    
    # Create category directory if it doesn't exist
    mkdir -p "$PRESETS_LOCAL_DIR/$category"
    
    # Download the file
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$url" -o "$output"
    else
        wget -q "$url" -O "$output"
    fi
    
    print_success "Preset downloaded: $output"
}

# List available presets from remote
list_remote_presets() {
    print_info "Fetching available presets from remote..."
    
    local api_url="https://api.github.com/repos/x-multibyte/laravel-dev-presets/contents"
    
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$api_url" | grep -oP '(?<="name": ")[^"]*\.json' | sort -u
    else
        wget -qO- "$api_url" | grep -oP '(?<="name": ")[^"]*\.json' | sort -u
    fi
}

# Check for updates
check_updates() {
    print_info "Checking for preset updates..."
    
    if [ ! -d "$PRESETS_LOCAL_DIR/.git" ]; then
        print_warning "Local presets directory is not a git repository"
        print_info "Run 'sync_presets.sh --sync' to initialize"
        return 1
    fi
    
    cd "$PRESETS_LOCAL_DIR"
    git fetch origin > /dev/null 2>&1
    
    LOCAL_HASH=$(git rev-parse HEAD)
    REMOTE_HASH=$(git rev-parse origin/main)
    
    if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
        print_success "Presets are up to date"
        return 0
    else
        print_warning "Updates available"
        print_info "Local: $LOCAL_HASH"
        print_info "Remote: $REMOTE_HASH"
        print_info "Run 'sync_presets.sh --sync' to update"
        return 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
Laravel Dev Presets Sync Script

Usage: bash sync_presets.sh [OPTIONS]

Options:
  --sync              Sync presets from remote repository
  --force             Force sync (reset to remote main branch)
  --download <cat> <ver>  Download specific preset
  --list              List available presets from remote
  --check             Check for updates
  --help              Show this help message

Examples:
  bash sync_presets.sh --sync
  bash sync_presets.sh --force
  bash sync_presets.sh --download api 12
  bash sync_presets.sh --list
  bash sync_presets.sh --check

Repository: $PRESETS_REPO
Local Directory: $PRESETS_LOCAL_DIR

EOF
}

# Main script logic
main() {
    case "${1:-}" in
        --sync)
            sync_presets "${2:-false}"
            ;;
        --force)
            sync_presets "true"
            ;;
        --download)
            if [ -z "$2" ] || [ -z "$3" ]; then
                print_error "Usage: $0 --download <category> <version>"
                exit 1
            fi
            download_preset "$2" "$3"
            ;;
        --list)
            list_remote_presets
            ;;
        --check)
            check_updates
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            print_error "No option specified. Use --help for usage information."
            exit 1
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"