# Laravel Dev Skill Quick Index

## 📚 Documentation Resources

### Current Version Documentation (Laravel 12.x)
Path: `skills/laravel-dev/references/current/`

**Core Topics**:
- **installation.md** - Installation and setup
- **database.md** - Database, Eloquent, migrations
- **eloquent.md** - Eloquent ORM details
- **controllers.md** - Controllers
- **routing.md** - Routing
- **testing.md** - Testing
- **auth.md** - Authentication and authorization
- **artisan.md** - Artisan command-line tool

**Complete List**: 24 core topics + 84 extended topics

### Version Switching
```bash
# View available versions
python scripts/version_manager.py --list

# Switch to 11.x
python scripts/version_manager.py --set-current 11.x

# Compare version differences
python scripts/version_manager.py --compare 11.x 12.x
```

## 🛠️ Development Tools

### Artisan Command Quick Reference
📄 **File**: `skills/laravel-dev/templates/artisan-quick-reference.md`

Includes:
- Model generation commands
- Controller generation commands
- Database migration commands
- Test generation commands
- Filament resource generation commands
- Practical combination examples

### Ecosystem Package Configuration Guide
📄 **File**: `skills/laravel-dev/templates/ecosystem-config-guide.md`

Includes:
- **Sail** - Complete Docker containerization configuration
- **Reverb** - WebSocket server configuration
- **Laravel Echo + Pusher.js** - WebSocket client configuration
- Complete real-time chat application example
- Common issues troubleshooting

### Ecosystem Package Quick Configuration Script
📄 **File**: `skills/laravel-dev/scripts/setup-ecosystem.sh`

One-click configuration for Laravel ecosystem packages:

```bash
# Configure all ecosystem packages
bash scripts/setup-ecosystem.sh --all

# Configure Sail only
bash scripts/setup-ecosystem.sh --sail

# Configure Reverb and Echo
bash scripts/setup-ecosystem.sh --reverb --echo
```

### Configuration Templates
📁 **Directory**: `skills/laravel-dev/templates/config/`

Pre-configured template files:
- `docker-compose.yml` - Sail Docker service configuration
- `broadcasting.reverb.php` - Reverb broadcasting configuration
- `echo.bootstrap.js` - Echo client configuration
- `supervisor-reverb.conf` - Reverb production environment configuration

## 🎨 Preset System

The Preset system provides out-of-the-box Laravel project configuration solutions.

### Preset Usage Guide
📄 **File**: `skills/laravel-dev/templates/PRESETS.md`

Includes:
- **Preset Concept** - What is a Preset, why use Presets
- **Available Presets** - 5 standard Presets (basic, fullstack-app, api-only, realtime-app, custom-template)
- **Preset Manager** - Commands for managing and using Presets
- **Create Custom Preset** - How to create your own Preset
- **Advanced Features** - Dependency inheritance, hook scripts, template injection, etc.

### Available Presets

| Preset | Description | Difficulty | Estimated Time |
|--------|-------------|------------|----------------|
| `basic` | Basic Laravel project | Beginner | 2 minutes |
| `fullstack-app` | Full-stack application (authentication + real-time communication) | Intermediate | 5 minutes |
| `api-only` | API-only project | Beginner | 3 minutes |
| `realtime-app` | Real-time application (WebSocket) | Intermediate | 4 minutes |
| `custom-template` | Custom template example | Beginner | 3 minutes |

### Preset Manager Commands

```bash
# List all Presets
bash scripts/preset_manager.sh --list

# View Preset summary
bash scripts/preset_manager.sh --summary fullstack-app

# Check dependency compatibility
bash scripts/preset_manager.sh --check fullstack-app

# Validate Preset
bash scripts/preset_manager.sh --validate fullstack-app
```

### Preset Features

- ✅ **Out-of-the-box** - All configurations predefined, no manual setup needed
- ✅ **Dependency Management** - Automatically install all required Composer and NPM packages
- ✅ **Environment Variables** - Pre-configured .env files
- ✅ **Hook Scripts** - Support lifecycle hooks
- ✅ **Template Injection** - Support custom code templates
- ✅ **Dependency Inheritance** - Support inheriting configurations from other Presets
- ✅ **Git Sync** - Support dynamically updating Presets from Git repositories

**Common Quick Commands**:
```bash
# One-click CRUD creation
php artisan make:model Post -a

# View all commands
php artisan list

# View command help
php artisan help make:model
```

### Project Creation
```bash
# Create new project
composer create-project laravel/laravel my-app

# Install dependencies
composer install
npm install

# Configure environment
cp .env.example .env
php artisan key:generate

# Run migrations
php artisan migrate
```

## 📦 Laravel Ecosystem Packages

### Authentication
- **Fortify** - Headless authentication backend
- **Sanctum** - API authentication
- **Socialite** - OAuth social login

### Development Tools
- **Pint** - Code formatting
- **Pail** - Log monitoring
- **Telescope** - Debugging assistant
- **Tinker** - Interactive REPL

### Performance
- **Octane** - High-performance application server
- **Reverb** - WebSocket real-time communication
- **Scout** - Full-text search

**Detailed Configuration**: `config/packages.json`

## 🎨 Filament v5

Filament skill location: `skills/filament-v5/`

### Quick Start
```bash
# Create resource
php artisan make:filament-resource Post

# Create page
php artisan make:filament-page Settings

# Create widget
php artisan make:filament-widget StatsOverview
```

## 💡 Usage Recommendations

### 1. Prioritize Artisan Commands
Laravel includes powerful scaffolding capabilities. Most code generation can be completed through `php artisan make:*` commands.

### 2. Consult Documentation
When encountering issues, first consult relevant documentation in `references/current/`.

### 3. Reference Quick Guide
Use `templates/artisan-quick-reference.md` as a cheat sheet for common commands.

### 4. Version Management
To switch Laravel versions, use the `version_manager.py` tool.

## 🔗 Related Links

- Laravel Official Documentation: https://laravel.com/docs
- Filament Official Documentation: https://filamentphp.com/docs
- Artisan Command Reference: `references/current/artisan.md`
- Complete Command List: Run `php artisan list`