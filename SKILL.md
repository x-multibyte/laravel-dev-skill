---
name: laravel-dev
description: Laravel development toolkit providing documentation access, code generation, configuration management, and ecosystem integration for one-stop development support. Includes multi-version Laravel documentation (10.x, 11.x, 12.x), Artisan command quick reference, ecosystem configuration guides (Sail, Reverb, Echo), configuration templates, and automation scripts. Suitable for Laravel application development, feature implementation, environment configuration, and ecosystem integration. Triggered when users mention Laravel development tasks, need Laravel feature guidance, request implementation examples, or need to configure Laravel development environment.
---

# Laravel Dev

## Overview

Access topic-based Laravel documentation for rapid development guidance with support for multiple Laravel versions (10.x, 11.x, 12.x). Includes development scripts for project creation, package installation, and environment configuration.

## Quick Start

### 🚀 Quick Index
View **Quick Index**: `templates/INDEX.md` - Contains quick navigation to all resources

### 🎨 Preset System

The Preset system provides out-of-the-box Laravel project configuration solutions, like a "shopping list" or "solution package". Developers can directly select presets to quickly initialize projects.

**List all available Presets**:
```bash
bash skills/laravel-dev/scripts/preset_manager.sh --list
```

**View Preset summary**:
```bash
bash skills/laravel-dev/scripts/preset_manager.sh --summary fullstack-app
```

**Check dependency compatibility**:
```bash
bash skills/laravel-dev/scripts/preset_manager.sh --check fullstack-app
```

**Available Presets**:
- `basic` - Basic Laravel project with no additional dependencies
- `fullstack-app` - Full-stack application with authentication, real-time communication, and more
- `api-only` - API-only project with Sanctum authentication
- `realtime-app` - Real-time application with WebSocket server and client
- `custom-template` - Custom template example

**Preset Features**:
- ✅ Out-of-the-box - All configurations predefined, no manual setup needed
- ✅ Dependency Management - Automatically install all required Composer and NPM packages
- ✅ Environment Variables - Pre-configured .env files
- ✅ Hook Scripts - Support lifecycle hooks
- ✅ Template Injection - Support custom code templates
- ✅ Dependency Inheritance - Support inheriting configurations from other presets
- ✅ Git Sync - Support dynamically updating presets from Git repositories

### Access Documentation

Load topic-specific documentation for the current version:

```bash
# For database queries and Eloquent
read_file('.iflow/skills/laravel-dev/references/current/database.md')

# For authentication and authorization
read_file('.iflow/skills/laravel-dev/references/current/auth.md')

# For routing and controllers
read_file('.iflow/skills/laravel-dev/references/current/routing.md')

# For testing
read_file('.iflow/skills/laravel-dev/references/current/testing.md')
```

### Manage Versions

```bash
# List available versions
python .iflow/skills/laravel-dev/scripts/version_manager.py --list

# Show current version
python .iflow/skills/laravel-dev/scripts/version_manager.py --current

# Switch to a different version
python .iflow/skills/laravel-dev/scripts/version_manager.py --set-current 11.x

# Compare versions
python .iflow/skills/laravel-dev/scripts/version_manager.py --compare 11.x 12.x
```

### Fetch Documentation

```bash
# Fetch a specific version
python .iflow/skills/laravel-dev/scripts/fetch_laravel_docs.py --version 12.x --output .iflow/skills/laravel-dev/references

# Fetch multiple versions
python .iflow/skills/laravel-dev/scripts/fetch_laravel_docs.py --versions 10.x,11.x --output .iflow/skills/laravel-dev/references

# Fetch all supported versions
python .iflow/skills/laravel-dev/scripts/fetch_laravel_docs.py --all-versions --output .iflow/skills/laravel-dev/references
```

## Development Scripts

### Artisan Command Quick Reference

Laravel includes a powerful Artisan command-line tool with extensive scaffolding capabilities. Prioritize using these built-in commands over custom scripts.

**Quick Reference Guide**: `templates/artisan-quick-reference.md`

**Common commands**:
```bash
# Create model (includes all related files)
php artisan make:model Post -a

# Create resource controller
php artisan make:controller PostController --resource

# Create migration
php artisan make:migration create_posts_table

# Create test
php artisan make:test PostTest

# Create form request
php artisan make:request StorePostRequest

# Create Filament resource
php artisan make:filament-resource Post

# View all commands
php artisan list
```

### Project Creation

Create a new Laravel project:

```bash
# Using Composer
composer create-project laravel/laravel my-app

# Using Laravel Installer
laravel new my-app

# Using Laravel Herd
herd new my-app
```

### Environment Configuration

Environment configuration:

```bash
# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate

# Configure database (edit .env file)
```

### Valet Configuration

Laravel Valet configuration (macOS development environment):

```bash
# Install Valet
composer global require laravel/valet
valet install

# Configure project
cd my-app
valet link

# SSL support
valet secure
valet unsecure
```

## Available Reference Files

### Core Topics
- **installation.md** - Installation, setup, and configuration
- **configuration.md** - Application configuration and environment
- **structure.md** - Directory structure and organization

### Database
- **database.md** - Database queries, migrations, seeding, pagination

### Routing & Controllers
- **routing.md** - Routing, controllers, middleware

### Views & Frontend
- **views.md** - Blade templates, frontend, views

### Authentication & Authorization
- **auth.md** - Authentication, authorization

### Requests & Responses
- **requests.md** - Requests, responses, validation, HTTP client

### Other Topics
- **artisan.md** - Artisan CLI commands
- **cache.md** - Caching
- **collections.md** - Collections
- **contracts.md** - Service contracts
- **security.md** - CSRF, hashing, encryption
- **errors.md** - Error handling
- **helpers.md** - Helper functions
- **events.md** - Events and broadcasting
- **logging.md** - Logging
- **mail.md** - Mail
- **notifications.md** - Notifications
- **packages.md** - Package development
- **queues.md** - Queues and job scheduling
- **sessions.md** - Session management
- **testing.md** - Testing

### Additional Packages
- **misc.md** - Other Laravel ecosystem packages (Horizon, Telescope, Scout, etc.)

## Configuration Templates

### Environment Variables
Located in `templates/env/`:
- `env.example.mysql` - MySQL configuration template

### IDE Configuration
Located in `templates/ide/`:
- `vscode/settings.json` - VS Code settings
- `vscode/extensions.json` - Recommended VS Code extensions

## Official Laravel Packages

### Authentication
- **Fortify** - Headless authentication backend
- **Sanctum** - API authentication
- **Socialite** - OAuth social login

### Development Tools
- **Pint** - Code style formatter
- **Pail** - Log monitoring
- **Telescope** - Debugging assistant
- **Horizon** - Queue monitoring dashboard
- **Tinker** - Interactive REPL

### Performance
- **Octane** - High-performance application server
- **Reverb** - WebSocket real-time communication
- **Scout** - Full-text search
- **Echo** - Real-time events

### Development
- **Sail** - Docker development environment
- **Prompts** - Command-line interactive prompts

## Resources

### scripts/
- **fetch_laravel_docs.py** - Fetch Laravel documentation from GitHub (supports multiple versions)
- **version_manager.py** - Version management tool (switch Laravel versions)
- **setup-ecosystem.sh** - Ecosystem package quick configuration script (Sail, Reverb, Echo)

**Note**: Laravel includes extensive Artisan commands for code generation, no additional scripts needed. See `templates/artisan-quick-reference.md`

### templates/
- **artisan-quick-reference.md** - Artisan command quick reference
- **ecosystem-config-guide.md** - Ecosystem package configuration guide (Sail, Reverb, Echo)
- **INDEX.md** - Skill quick index
- **config/** - Configuration template files (docker-compose.yml, broadcasting.php, etc.)

### config/
- **packages.json** - Official Laravel packages list with installation commands
- **settings.json** - Skill configuration and version settings

### references/
- **current** - Symbolic link to current version (default: v12)
- **v10/** - Laravel 10.x documentation
- **v11/** - Laravel 11.x documentation
- **v12/** - Laravel 12.x documentation
- **VERSIONS.md** - Version comparison and information

### templates/
Configuration templates for environment variables and IDE settings.