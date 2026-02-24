# Laravel Dev Skill

AI-powered Laravel development toolkit designed to enhance AI assistants across multiple CLI tools. Provides intelligent Preset system, comprehensive documentation, and automation scripts for rapid Laravel development.

## 🎯 Core Philosophy

**This skill is NOT a replacement for Laravel's official tools.**

Laravel Dev Skill enhances AI assistants (Claude Code, Cursor, Windsurf, Continue, etc.) by providing:

- **Intelligent Context**: Understands development scenarios and recommends optimal solutions
- **Smart Presets**: Out-of-the-box project configurations for common use cases
- **Comprehensive Knowledge**: Multi-version Laravel documentation (10.x, 11.x, 12.x)
- **Developer-First**: Designed to help developers work faster, not replace their workflow

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  AI CLI Tools Layer                      │
│  Claude Code │ Cursor │ Windsurf │ Continue │ Others  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Laravel Dev Skill (AI Intelligence)         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Intent Understanding - Analyze requirements     │   │
│  │  Knowledge Retrieval - Search Laravel docs       │   │
│  │  Code Generation - Generate project code         │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌─────────────────────────────────────────────────┐   │
│  │  laravel-dev-presets (Remote Repository)        │   │
│  │  - api/10.json, api/11.json, api/12.json     │   │
│  │  - filament/v4.json, filament/v5.json         │   │
│  │  - framework/10.json, framework/11.json, etc. │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Laravel Documentation (Local Cache)           │   │
│  │  - references/v10/ (Laravel 10.x)              │   │
│  │  - references/v11/ (Laravel 11.x)              │   │
│  │  - references/v12/ (Laravel 12.x)              │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                Tool Layer (Official Tools)              │
│  Laravel Installer │ Composer │ Artisan │ npm/pnpm    │
└─────────────────────────────────────────────────────────┘
```

## 📦 Available Presets

Presets are fetched from the [laravel-dev-presets repository](https://github.com/x-multibyte/laravel-dev-presets).

### API Projects (`api/`)
- `10.json` - Laravel 10.x API project with Sanctum authentication
- `11.json` - Laravel 11.x API project with Sanctum authentication
- `12.json` - Laravel 12.x API project with Sanctum authentication

### Filament (`filament/`)
- `v4.json` - Filament v4 admin panel configuration
- `v5.json` - Filament v5 admin panel configuration

### Framework (`framework/`)
- `10.json` - Laravel 10.x base framework setup
- `11.json` - Laravel 11.x base framework setup
- `12.json` - Laravel 12.x base framework setup

### Laravel Packages (`laravel-package/`)
- `blade-component.json` - Blade component development preset
- `filament-plugin-skeleton.json` - Filament plugin skeleton
- `meta-package.json` - Meta package template
- `package-skeleton-laravel.json` - Laravel package skeleton
- `package.json` - Generic package template

### Starter Kits (`starter-kits/`)
- `livewire.json` - Livewire starter kit
- `react.json` - React starter kit
- `svelte.json` - Svelte starter kit
- `vue.json` - Vue starter kit

## 🚀 Installation

### For AI CLI Tools

This skill is designed to work with various AI CLI tools. Install it according to your tool's documentation:

**Claude Code:**
```bash
# Add to Claude Code project
# File: .claude/skills/laravel-dev/
```

**Cursor:**
```bash
# Add to Cursor's skills directory
# File: .cursor/skills/laravel-dev/
```

**Windsurf:**
```bash
# Add to Windsurf's skills directory
# File: .windsurf/skills/laravel-dev/
```

**Continue:**
```bash
# Add to Continue's skills directory
# File: ~/.continue/skills/laravel-dev/
```

### Manual Installation

1. Clone this repository:
```bash
git clone https://github.com/x-multibyte/laravel-dev-skill.git
```

2. Copy to your AI tool's skills directory:
```bash
cp -r laravel-dev-skill ~/.your-ai-tool/skills/
```

3. Verify installation:
```bash
bash laravel-dev-skill/scripts/preset_manager.sh --list
```

## ✨ Features

### Intelligent Preset System

The Preset system provides out-of-the-box Laravel project configurations. AI assistants can intelligently recommend the best preset based on your development scenario.

**Preset Features:**
- ✅ **Dual Version Control** - File name = Laravel version, JSON version = preset version
- ✅ **Smart Recommendation** - AI analyzes requirements and suggests optimal presets
- ✅ **Dependency Management** - Auto-install required Composer and NPM packages
- ✅ **Environment Configuration** - Pre-configured .env files
- ✅ **Lifecycle Hooks** - Support for custom scripts at different stages
- ✅ **Template Injection** - Support custom code templates
- ✅ **Git Sync** - Dynamically update from remote repository

### Quick Start with AI Assistant

Ask your AI assistant:

**"Create a Laravel 12 API project with Sanctum authentication"**
→ AI recommends `api/12.json` preset
→ Generates project with authentication, API resources, rate limiting

**"Build a full-stack app with Filament admin panel"**
→ AI recommends `filament/v5.json` + `fullstack` preset
→ Generates project with admin panel, authentication, real-time features

**"Create a Laravel package for blade components"**
→ AI recommends `laravel-package/blade-component.json`
→ Generates package skeleton with component templates

### Preset Management

```bash
# List all available presets
bash scripts/preset_manager.sh --list

# View preset summary
bash scripts/preset_manager.sh --summary api 12

# Check dependency compatibility
bash scripts/preset_manager.sh --check api 12

# Validate preset format
bash scripts/preset_manager.sh --validate api 12

# Parse preset configuration
bash scripts/preset_manager.sh --parse api 12
```

### Documentation Access

AI assistants can query Laravel documentation by topic:

```bash
# Database documentation
read_file('references/current/database.md')

# Authentication documentation
read_file('references/current/auth.md')

# Routing documentation
read_file('references/current/routing.md')

# Artisan commands
read_file('references/current/artisan.md')
```

### Version Management

```bash
# List available Laravel versions
python scripts/version_manager.py --list

# Switch to Laravel 11.x documentation
python scripts/version_manager.py --set-current 11.x

# Compare versions
python scripts/version_manager.py --compare 11.x 12.x
```

### Ecosystem Configuration

Quick configuration for Laravel ecosystem packages:

```bash
# Configure all packages (Sail, Reverb, Echo)
bash scripts/setup-ecosystem.sh --all

# Configure Sail only
bash scripts/setup-ecosystem.sh --sail

# Configure Reverb and Echo
bash scripts/setup-ecosystem.sh --reverb --echo
```

## 📁 Project Structure

```
laravel-dev-skill/
├── SKILL.md                          # Skill documentation for AI assistants
├── README.md                         # This file
├── config/
│   ├── packages.json                 # Laravel ecosystem package definitions
│   ├── preset-schema.json             # Preset JSON Schema for validation
│   └── settings.json                   # Skill configuration
├── scripts/
│   ├── preset_manager.sh              # Preset management tool
│   ├── setup-ecosystem.sh            # Ecosystem configuration scripts
│   ├── fetch_laravel_docs.py         # Documentation fetcher
│   └── version_manager.py             # Version management tool
├── templates/
│   ├── INDEX.md                        # Quick navigation index
│   ├── PRESETS.md                      # Preset usage guide
│   ├── artisan-quick-reference.md      # Artisan command reference
│   ├── ecosystem-config-guide.md       # Detailed ecosystem guide
│   ├── config/                         # Configuration templates
│   │   ├── broadcasting.reverb.php
│   │   ├── docker-compose.yml
│   │   ├── echo.bootstrap.js
│   │   └── supervisor-reverb.conf
│   └── presets/                        # Cache directory (empty)
│       └── .gitkeep                    # Presets fetched from remote repo
└── references/
    ├── current/                         # Symlink to current version
    ├── v10/                            # Laravel 10.x documentation
    ├── v11/                            # Laravel 11.x documentation
    └── v12/                            # Laravel 12.x documentation
```

## 🎯 Use Cases

### 1. Rapid API Development

**Developer:** "I need to build a REST API for a mobile app"

**AI Assistant:**
1. Analyzes requirement → Recommends `api/12.json`
2. Applies preset with Sanctum authentication
3. Configures API resources, rate limiting
4. Sets up testing infrastructure

### 2. Admin Panel Creation

**Developer:** "I need an admin panel for content management"

**AI Assistant:**
1. Analyzes requirement → Recommends `filament/v5.json`
2. Applies preset with Filament v5
3. Generates CRUD resources, forms, tables
4. Configures permissions and roles

### 3. Package Development

**Developer:** "I want to create a Laravel package"

**AI Assistant:**
1. Analyzes requirement → Recommends `laravel-package/package.json`
2. Generates package skeleton
3. Sets up service providers, facades
4. Configures testing and documentation

### 4. Full-stack Application

**Developer:** "I need a complete web application with real-time features"

**AI Assistant:**
1. Analyzes requirement → Recommends combination of presets
2. Applies `framework/12.json` + `realtime-app.json`
3. Configures Reverb for WebSocket
4. Sets up Laravel Echo client
5. Generates frontend and backend

## 🎓 AI Assistant Integration

### How AI Assistants Use This Skill

1. **Intent Understanding**: Parse developer's natural language requirements
2. **Preset Recommendation**: Match requirements to optimal presets
3. **Configuration Application**: Apply preset configurations
4. **Code Generation**: Generate project code based on preset
5. **Documentation Lookup**: Provide relevant Laravel documentation
6. **Best Practices**: Suggest improvements and optimizations

### Example Interaction

```
Developer: "Create a Laravel 12 project with Filament admin panel"
    
AI Assistant: "I'll create a Laravel 12 project with Filament v5 admin panel.
            
    Recommended preset: filament/v5.json
    Version: 2.0.0
    Features: Admin panel, authentication, resources, permissions
    
    Steps:
    1. Create Laravel project using official installer
    2. Apply filament/v5.json preset
    3. Install dependencies (Filament v5, Spatie Permission)
    4. Generate admin resources
    5. Configure authentication and permissions
    
    Shall I proceed?"
```

## 🔗 Related Projects

- [laravel-dev-presets](https://github.com/x-multibyte/laravel-dev-presets) - Preset repository with 6 preset categories
- [laravel-dev-cli](https://github.com/x-multibyte/laravel-dev-cli) - Composer CLI tool (coming soon)

## 🌟 Roadmap

### Completed ✅
- [x] Preset JSON Schema with validation
- [x] Remote Presets repository
- [x] 6 Preset categories (API, Filament, Framework, Laravel Package, Starter Kits)
- [x] Multi-version documentation (10.x, 11.x, 12.x)
- [x] Ecosystem configuration guides
- [x] AI assistant integration patterns

### In Progress 🚧
- [ ] Preset sync script (sync_presets.sh)
- [ ] Enhanced preset_manager.sh with remote fetching
- [ ] Environment compatibility checker

### Planned 📋
- [ ] More preset categories (e-commerce, CMS, microservices)
- [ ] Community preset contribution system
- [ ] Preset validation and testing automation
- [ ] AI-powered preset recommendation engine

## 💡 Value Proposition

### For Developers
- **Faster Development** - Start with pre-configured projects
- **Fewer Errors** - Validated configurations from experts
- **Consistency** - Standardized project structures
- **Flexibility** - Create and share custom presets
- **Learning** - Understand best practices through examples

### For AI Assistants
- **Intelligent Context** - Understand development scenarios deeply
- **Smart Recommendations** - Suggest optimal solutions automatically
- **Simplified Interaction** - Natural language → working project
- **Programmability** - Structured data for easy processing
- **Dynamic Updates** - Always access latest presets from remote

## 🤝 Contributing

Contributions are welcome! Please:

1. **For Presets**: Fork [laravel-dev-presets](https://github.com/x-multibyte/laravel-dev-presets) and add your preset
2. **For Documentation**: Improve this skill's documentation
3. **For Scripts**: Enhance automation scripts

### Adding a New Preset

1. Fork [laravel-dev-presets](https://github.com/x-multibyte/laravel-dev-presets)
2. Choose the appropriate category folder
3. Create a new JSON file following the schema
4. Validate against `preset-schema.json`
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check [laravel-dev-presets](https://github.com/x-multibyte/laravel-dev-presets) for preset-related issues
- Consult the documentation in `templates/` directory

---

**Important**: This skill enhances AI assistants' capabilities for Laravel development. It does NOT replace Laravel's official tools or documentation. Always refer to [laravel.com](https://laravel.com/docs) for official documentation and [github.com/laravel/laravel](https://github.com/laravel/laravel) for the framework source code.