#!/bin/bash

###############################################################################
# Preset Manager - Laravel Dev Skill
#
# Features:
#
# - List all available presets
# - Validate preset validity
# - Parse preset configuration
# - Check dependency compatibility
# - Generate preset summary
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
PRESETS_DIR="$(dirname "$SCRIPT_DIR")/templates/presets"
SCHEMA_FILE="$(dirname "$SCRIPT_DIR")/config/preset-schema.json"

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

# Check if jq is installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        print_error "jq not installed, please install jq:"
        print_info "  macOS: brew install jq"
        print_info "  Linux: sudo apt-get install jq"
        exit 1
    fi
}

# List all available presets
list_presets() {
    print_info "Available Presets:"
    echo ""

    local count=0
    for preset_file in "$PRESETS_DIR"/*.json; do
        if [ -f "$preset_file" ]; then
            local preset_name=$(basename "$preset_file" .json)
            local preset_json=$(cat "$preset_file")

            local name=$(echo "$preset_json" | jq -r '.name')
            local description=$(echo "$preset_json" | jq -r '.description')
            local category=$(echo "$preset_json" | jq -r '.metadata.category // "custom"')
            local difficulty=$(echo "$preset_json" | jq -r '.metadata.difficulty // "intermediate"')
            local estimated_time=$(echo "$preset_json" | jq -r '.metadata.estimated_time // "N/A"')

            count=$((count + 1))

            echo "  ${count}. $name"
            echo "     Description: $description"
            echo "     Category: $category | Difficulty: $difficulty | Estimated Time: $estimated_time"
            echo ""
        fi
    done

    if [ $count -eq 0 ]; then
        print_warning "No presets found"
    else
        print_success "Found $count presets"
    fi
}

# Validate preset validity
validate_preset() {
    local preset_name=$1
    local preset_file="$PRESETS_DIR/${preset_name}.json"

    if [ ! -f "$preset_file" ]; then
        print_error "Preset '$preset_name' does not exist"
        return 1
    fi

    print_info "Validating preset: $preset_name"

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
    local preset_name=$1
    local preset_file="$PRESETS_DIR/${preset_name}.json"

    if [ ! -f "$preset_file" ]; then
        print_error "Preset '$preset_name' does not exist"
        return 1
    fi

    print_info "Parsing preset: $preset_name"
    cat "$preset_file" | jq '.'
}

# Check dependency compatibility
check_dependencies_compatibility() {
    local preset_name=$1
    local preset_file="$PRESETS_DIR/${preset_name}.json"

    if [ ! -f "$preset_file" ]; then
        print_error "Preset '$preset_name' does not exist"
        return 1
    fi

    print_info "Checking dependency compatibility: $preset_name"

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
    local preset_name=$1
    local preset_file="$PRESETS_DIR/${preset_name}.json"

    if [ ! -f "$preset_file" ]; then
        print_error "Preset '$preset_name' does not exist"
        return 1
    fi

    print_info "Generating preset summary: $preset_name"
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
  --list              List all available presets
  --validate <name>   Validate specified preset
  --parse <name>      Parse specified preset configuration
  --check <name>      Check dependency compatibility for specified preset
  --summary <name>    Generate summary for specified preset
  --help              Display help information

Examples:
  # List all presets
  bash $0 --list

  # Validate preset
  bash $0 --validate fullstack-app

  # Parse preset
  bash $0 --parse api-only

  # Check dependency compatibility
  bash $0 --check realtime-app

  # Generate summary
  bash $0 --summary basic

Preset directory: $PRESETS_DIR
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
        --validate)
            if [ -z "$2" ]; then
                print_error "Please specify preset name"
                exit 1
            fi
            validate_preset "$2"
            ;;
        --parse)
            if [ -z "$2" ]; then
                print_error "Please specify preset name"
                exit 1
            fi
            parse_preset "$2"
            ;;
        --check)
            if [ -z "$2" ]; then
                print_error "Please specify preset name"
                exit 1
            fi
            check_dependencies_compatibility "$2"
            ;;
        --summary)
            if [ -z "$2" ]; then
                print_error "Please specify preset name"
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