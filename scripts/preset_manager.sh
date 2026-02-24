#!/bin/bash
###############################################################################
# Preset Manager - Laravel Dev Skill
#
# Features:
#
# - List all available presets (local and remote)
# - Validate preset validity
# - Parse preset configuration
# - Check dependency compatibility
# - Generate preset summary
# - Sync presets from remote repository
###############################################################################

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PRESETS_DIR="$PROJECT_ROOT/templates/presets"
SCHEMA_FILE="$PROJECT_ROOT/config/preset-schema.json"
CONFIG_FILE="$PROJECT_ROOT/config/settings.json"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    if command -v jq &> /dev/null; then
        PRESETS_REPO=$(jq -r '.presets.repository // empty' "$CONFIG_FILE")
    else
        PRESETS_REPO=$(grep -oP '(?<="repository": ")[^"]*' "$CONFIG_FILE" | head -1)
    fi
fi

# Default remote repository
PRESETS_REPO=${PRESETS_REPO:-"https://github.com/x-multibyte/laravel-dev-presets"}

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

# Check dependencies
check_dependencies() {
    local missing=()
    
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing[*]}"
        print_info "Install with:"
        print_info "  macOS: brew install ${missing[*]}"
        print_info "  Linux: sudo apt-get install ${missing[*]}"
        exit 1
    fi
}

# Resolve preset path (supports both old and new format)
resolve_preset_path() {
    local preset_input=$1
    
    # Check if it's already a file path
    if [ -f "$preset_input" ]; then
        echo "$preset_input"
        return
    fi
    
    # Check for category/version format (e.g., "api 12" or "api/12.json")
    if [[ "$preset_input" =~ ^[a-z-]+/[0-9]+\.json$ ]]; then
        # Already in category/version.json format
        local preset_file="$PRESETS_DIR/$preset_input"
        echo "$preset_file"
        return
    fi
    
    if [[ "$preset_input" =~ ^[a-z-]+[[:space:]]+[0-9]+$ ]]; then
        # category version format (e.g., "api 12")
        local category=$(echo "$preset_input" | awk '{print $1}')
        local version=$(echo "$preset_input" | awk '{print $2}')
        local preset_file="$PRESETS_DIR/${category}/${version}.json"
        echo "$preset_file"
        return
    fi
    
    # Check old format (e.g., "api-only.json")
    if [ -f "$PRESETS_DIR/${preset_input}.json" ]; then
        echo "$PRESETS_DIR/${preset_input}.json"
        return
    fi
    
    if [ -f "$PRESETS_DIR/$preset_input" ]; then
        echo "$PRESETS_DIR/$preset_input"
        return
    fi
    
    # Default: treat as name and look in any category
    echo "$PRESETS_DIR/$preset_input"
}

# List all available presets
list_presets() {
    print_info "Available Presets:"
    echo ""

    local count=0
    local local_count=0
    local remote_count=0
    
    # List local presets
    if [ -d "$PRESETS_DIR" ]; then
        for category_dir in "$PRESETS_DIR"/*; do
            if [ -d "$category_dir" ]; then
                local category=$(basename "$category_dir")
                for preset_file in "$category_dir"/*.json; do
                    if [ -f "$preset_file" ]; then
                        local version=$(basename "$preset_file" .json)
                        local preset_json=$(cat "$preset_file" 2>/dev/null || echo '{}')
                        
                        local name=$(echo "$preset_json" | jq -r '.name // "N/A"')
                        local description=$(echo "$preset_json" | jq -r '.description // "N/A"')
                        local difficulty=$(echo "$preset_json" | jq -r '.metadata.difficulty // "intermediate"')
                        local estimated_time=$(echo "$preset_json" | jq -r '.metadata.estimated_time // "N/A"')

                        count=$((count + 1))
                        local_count=$((local_count + 1))

                        echo "  ${count}. ${category}/${version}"
                        echo "     Name: $name"
                        echo "     Description: $description"
                        echo "     Difficulty: $difficulty | Estimated Time: $estimated_time"
                        echo ""
                    fi
                done
            fi
        done
    fi
    
    # Show remote repository info
    print_info "Remote repository: $PRESETS_REPO"
    print_info "Run 'bash preset_manager.sh --sync' to fetch latest presets"
    
    if [ $count -eq 0 ]; then
        print_warning "No local presets found"
        print_info "Run 'bash preset_manager.sh --sync' to download presets from remote repository"
    else
        print_success "Found $count local presets"
    fi
}

# Sync presets from remote repository
sync_presets() {
    local force=$1
    
    print_info "Syncing presets from remote repository..."
    print_info "Repository: $PRESETS_REPO"
    
    if [ ! -d "$PRESETS_DIR" ]; then
        mkdir -p "$PRESETS_DIR"
    fi
    
    # Check if local directory is a git repository
    if [ -d "$PRESETS_DIR/.git" ]; then
        print_info "Updating existing git repository..."
        cd "$PRESETS_DIR"
        
        if [ "$force" = "true" ]; then
            print_warning "Force mode: resetting to remote main branch"
            git fetch origin
            git reset --hard origin/main
        else
            git pull origin main
        fi
    else
        print_info "Cloning remote repository..."
        rm -rf "$PRESETS_DIR"
        git clone "$PRESETS_REPO" "$PRESETS_DIR"
    fi
    
    # Remove .git directory to keep it as a cache
    rm -rf "$PRESETS_DIR/.git"
    
    print_success "Presets synced successfully!"
    print_info "Local presets directory: $PRESETS_DIR"
}

# Validate preset validity
validate_preset() {
    local preset_input=$1
    local preset_file=$(resolve_preset_path "$preset_input")

    if [ ! -f "$preset_file" ]; then
        print_error "Preset '$preset_input' does not exist"
        print_info "Run 'bash preset_manager.sh --list' to see available presets"
        return 1
    fi

    print_info "Validating preset: $preset_input"
    
    # Check JSON format
    if ! jq empty "$preset_file" &> /dev/null; then
        print_error "Invalid JSON format"
        return 1
    fi

    # Check required fields
    local preset_json=$(cat "$preset_file")
    local required_fields=("name" "version" "description" "laravel")

    for field in "${required_fields[@]}"; do
        if [ "$(echo "$preset_json" | jq -r ".${field}")" == "null" ]; then
            print_error "Missing required field: $field"
            return 1
        fi
    done

    print_success "Preset validation passed"
    return 0
}

# Parse preset configuration
parse_preset() {
    local preset_input=$1
    local preset_file=$(resolve_preset_path "$preset_input")

    if [ ! -f "$preset_file" ]; then
        print_error "Preset '$preset_input' does not exist"
        print_info "Run 'bash preset_manager.sh --list' to see available presets"
        return 1
    fi

    print_info "Parsing preset: $preset_input"
    cat "$preset_file" | jq '.'
}

# Check dependency compatibility
check_dependencies_compatibility() {
    local preset_input=$1
    local preset_file=$(resolve_preset_path "$preset_input")

    if [ ! -f "$preset_file" ]; then
        print_error "Preset '$preset_input' does not exist"
        print_info "Run 'bash preset_manager.sh --list' to see available presets"
        return 1
    fi

    print_info "Checking dependency compatibility: $preset_input"

    local preset_json=$(cat "$preset_file")
    local requires=$(echo "$preset_json" | jq -r '.requires // {}')

    local php_required=$(echo "$requires" | jq -r '.php // null')
    local composer_required=$(echo "$requires" | jq -r '.composer // null')
    local node_required=$(echo "$requires" | jq -r '.node // null')
    local docker_required=$(echo "$requires" | jq -r '.docker // false')

    local issues=()

    # Check PHP
    if [ "$php_required" != "null" ]; then
        if command -v php &> /dev/null; then
            local php_version=$(php -r 'echo PHP_VERSION;')
            print_info "  PHP version: $php_version (required: $php_required)"
        else
            issues+=("PHP not installed")
        fi
    fi

    # Check Composer
    if [ "$composer_required" != "null" ]; then
        if command -v composer &> /dev/null; then
            local composer_version=$(composer --version | grep -oP '\d+\.\d+')
            print_info "  Composer version: $composer_version (required: $composer_required)"
        else
            issues+=("Composer not installed")
        fi
    fi

    # Check Node.js
    if [ "$node_required" != "null" ]; then
        if command -v node &> /dev/null; then
            local node_version=$(node --version)
            print_info "  Node.js version: $node_version (required: $node_required)"
        else
            issues+=("Node.js not installed")
        fi
    fi

    # Check Docker
    if [ "$docker_required" == "true" ]; then
        if command -v docker &> /dev/null; then
            print_info "  Docker: Installed"
        else
            issues+=("Docker not installed")
        fi
    fi

    if [ ${#issues[@]} -eq 0 ]; then
        print_success "All dependency checks passed"
        return 0
    else
        print_warning "Found compatibility issues:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
        return 1
    fi
}

# Generate preset summary
generate_summary() {
    local preset_input=$1
    local preset_file=$(resolve_preset_path "$preset_input")

    if [ ! -f "$preset_file" ]; then
        print_error "Preset '$preset_input' does not exist"
        print_info "Run 'bash preset_manager.sh --list' to see available presets"
        return 1
    fi

    print_info "Generating preset summary: $preset_input"
    echo ""

    local preset_json=$(cat "$preset_file")

    echo "=== Preset Summary ==="
    echo ""
    echo "Name: $(echo "$preset_json" | jq -r '.name')"
    echo "Version: $(echo "$preset_json" | jq -r '.version')"
    echo "Description: $(echo "$preset_json" | jq -r '.description')"
    echo "Author: $(echo "$preset_json" | jq -r '.author // "N/A"')"
    echo ""
    echo "=== Laravel Configuration ==="
    echo "Version: $(echo "$preset_json" | jq -r '.laravel.version')"
    echo "Strict version lock: $(echo "$preset_json" | jq -r '.laravel.strict')"
    echo ""
    echo "=== Dependencies ==="

    local composer_deps=$(echo "$preset_json" | jq -r '.dependencies.composer // {}')
    if [ "$(echo "$composer_deps" | jq 'length')" -gt 0 ]; then
        echo "Composer packages:"
        echo "$composer_deps" | jq -r 'to_entries[] | "  - \(.key): \(.value)"'
    fi

    local npm_deps=$(echo "$preset_json" | jq -r '.dependencies.npm // {}')
    if [ "$(echo "$npm_deps" | jq 'length')" -gt 0 ]; then
        echo "NPM packages:"
        echo "$npm_deps" | jq -r 'to_entries[] | "  - \(.key): \(.value)"'
    fi

    echo ""
    echo "=== Database ==="
    echo "Type: $(echo "$preset_json" | jq -r '.database.type // "N/A"')"
    echo "Version: $(echo "$preset_json" | jq -r '.database.version // "N/A"')"
    echo ""
    echo "=== Authentication ==="
    echo "Driver: $(echo "$preset_json" | jq -r '.auth.driver // "N/A"')"
    local features=$(echo "$preset_json" | jq -r '.auth.features[]' 2>/dev/null)
    if [ -n "$features" ]; then
        echo "Features: $features"
    fi
    echo ""
    echo "=== Metadata ==="
    echo "Category: $(echo "$preset_json" | jq -r '.metadata.category // "N/A"')"
    echo "Difficulty: $(echo "$preset_json" | jq -r '.metadata.difficulty // "N/A"')"
    echo "Estimated time: $(echo "$preset_json" | jq -r '.metadata.estimated_time // "N/A"')"
    echo ""
    echo "=== Tags ==="
    local tags=$(echo "$preset_json" | jq -r '.metadata.tags[]' 2>/dev/null)
    if [ -n "$tags" ]; then
        echo "$tags"
    else
        echo "None"
    fi
}

# Display help information
show_help() {
    cat << EOF
Preset Manager - Laravel Dev Skill

Usage: bash $0 [options] [parameters]

Options:
  --list              List all available presets (local cache)
  --sync              Sync presets from remote repository
  --force             Force sync (reset to remote main branch)
  --validate <preset> Validate specified preset
                      Format: <category> <version> or <category>/<version>.json
                      Examples: "api 12", "api/12.json"
  --parse <preset>    Parse specified preset configuration
  --check <preset>    Check dependency compatibility for specified preset
  --summary <preset>  Generate summary for specified preset
  --help              Display help information

Preset Formats:
  New format (recommended): <category> <version>
    Examples: "api 12", "filament v5", "framework 11"
    
  Alternative format: <category>/<version>.json
    Examples: "api/12.json", "filament/v5.json"

Examples:
  # List all presets
  bash $0 --list

  # Sync presets from remote
  bash $0 --sync

  # Force sync (reset to remote)
  bash $0 --force

  # Validate preset
  bash $0 --validate api 12
  bash $0 --validate filament/v5.json

  # Parse preset
  bash $0 --parse api 12

  # Check dependency compatibility
  bash $0 --check api 12

  # Generate summary
  bash $0 --summary api 12

Remote repository: $PRESETS_REPO
Local presets directory: $PRESETS_DIR

EOF
}

# Main function
main() {
    check_dependencies

    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    case $1 in
        --list)
            list_presets
            ;;
        --sync)
            sync_presets "false"
            ;;
        --force)
            sync_presets "true"
            ;;
        --validate)
            if [ -z "$2" ]; then
                print_error "Please specify preset"
                print_info "Format: --validate <category> <version>"
                print_info "Example: --validate api 12"
                exit 1
            fi
            validate_preset "$2"
            ;;
        --parse)
            if [ -z "$2" ]; then
                print_error "Please specify preset"
                print_info "Format: --parse <category> <version>"
                print_info "Example: --parse api 12"
                exit 1
            fi
            parse_preset "$2"
            ;;
        --check)
            if [ -z "$2" ]; then
                print_error "Please specify preset"
                print_info "Format: --check <category> <version>"
                print_info "Example: --check api 12"
                exit 1
            fi
            check_dependencies_compatibility "$2"
            ;;
        --summary)
            if [ -z "$2" ]; then
                print_error "Please specify preset"
                print_info "Format: --summary <category> <version>"
                print_info "Example: --summary api 12"
                exit 1
            fi
            generate_summary "$2"
            ;;
        --help)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"