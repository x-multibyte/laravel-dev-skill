# Laravel Dev Skill

AI-powered Laravel development toolkit with Preset system, comprehensive documentation, and automation scripts for rapid development.

## 🎯 Overview

Laravel Dev Skill provides a comprehensive development toolkit for Laravel applications, featuring:

- **Multi-version Documentation**: Laravel 10.x, 11.x, and 12.x
- **Preset System**: Out-of-the-box project configurations
- **Development Tools**: Artisan command reference, ecosystem configuration guides
- **Automation Scripts**: Quick setup for common development tasks

## ✨ Features

### Preset System

The Preset system provides out-of-the-box Laravel project configurations, like "shopping lists" or "solution packages". Developers can directly select presets to quickly initialize projects.

**Available Presets**:
- `basic` - Basic Laravel project
- `fullstack-app` - Full-stack application with authentication and real-time communication
- `api-only` - API-only project with Sanctum authentication
- `realtime-app` - Real-time application with WebSocket
- `custom-template` - Custom template example

**Preset Features**:
- ✅ Out-of-the-box - All configurations predefined
- ✅ Dependency Management - Auto-install required Composer and NPM packages
- ✅ Environment Variables - Pre-configured .env files
- ✅ Hook Scripts - Support lifecycle hooks
- ✅ Template Injection - Support custom code templates
- ✅ Dependency Inheritance - Inherit from other presets
- ✅ Git Sync - Dynamically update from Git repositories

### Quick Start

#### List All Presets
```bash
bash skills/laravel-dev/scripts/preset_manager.sh --list
```

#### View Preset Summary
```bash
bash skills/laravel-dev/scripts/preset_manager.sh --summary fullstack-app
```

#### Check Dependency Compatibility
```bash
bash skills/laravel-dev/scripts/preset_manager.sh --check fullstack-app
```

### Documentation

Access Laravel documentation by topic:
```bash
# Database
read_file('skills/laravel-dev/references/current/database.md')

# Authentication
read_file('skills/laravel-dev/references/current/auth.md')

# Routing
read_file('skills/laravel-dev/references/current/routing.md')
```

### Version Management

```bash
# List available versions
python scripts/version_manager.py --list

# Switch to Laravel 11.x
python scripts/version_manager.py --set-current 11.x

# Compare versions
python scripts/version_manager.py --compare 11.x 12.x
```

### Ecosystem Configuration

Quick configuration for Laravel ecosystem packages:
```bash
# Configure all packages
bash scripts/setup-ecosystem.sh --all

# Configure Sail only
bash scripts/setup-ecosystem.sh --sail

# Configure Reverb and Echo
bash scripts/setup-ecosystem.sh --reverb --echo
```

## 📁 Structure

```
skills/laravel-dev/
├── SKILL.md                          # Skill main documentation
├── config/
│   ├── packages.json                 # Laravel ecosystem packages
│   ├── preset-schema.json             # Preset schema definition
│   └── settings.json                   # Skill configuration
├── scripts/
│   ├── preset_manager.sh              # Preset management tool
│   ├── setup-ecosystem.sh            # Ecosystem configuration
│   ├── fetch_laravel_docs.py         # Documentation fetcher
│   └── version_manager.py             # Version management
├── templates/
│   ├── INDEX.md                        # Quick index
│   ├── PRESETS.md                      # Preset usage guide
│   ├── artisan-quick-reference.md      # Artisan command reference
│   └── config/                         # Configuration templates
└── references/
    ├── current/                         # Current version (symlink)
    ├── v10/                            # Laravel 10.x docs
    ├── v11/                            # Laravel 11.x docs
    └── v12/                            # Laravel 12.x docs
```

## 🚀 Getting Started

### Prerequisites

- PHP >= 8.2
- Composer >= 2.0
- Node.js >= 18.0
- npm >= 9.0

### Installation

1. Clone the repository
2. Ensure all prerequisites are installed
3. Use the Preset Manager to list available presets
4. Select and apply a preset to your project

### Usage

See detailed usage guides in:
- [Quick Index](templates/INDEX.md)
- [Preset Usage Guide](templates/PRESETS.md)
- [Artisan Command Reference](templates/artisan-quick-reference.md)

## 🎓 Philosophy

### Command = Trigger
- User inputs `/laravel-new` to trigger
- AI Agent leads interactive consultation
- Environment self-check first, providing smart recommendations

### Preset = Solution
- Like a "shopping list" or "solution package"
- Developers get complete configuration after selection
- Out-of-the-box, no additional setup needed

## 🌟 Roadmap

### Completed ✅
- [x] Preset JSON Schema
- [x] 5 Standard Presets
- [x] Preset Manager script
- [x] Multi-version documentation
- [x] Ecosystem configuration guides

### In Progress 🚧
- [ ] Preset application script
- [ ] Git sync tool
- [ ] Enhanced environment check

### Planned 📋
- [ ] AI Agent integration
- [ ] More Presets (e-commerce, CMS, microservices)
- [ ] Community Preset repository
- [ ] Cross-platform support

## 💡 Value

### For Developers
- **Time Saving** - No manual configuration needed
- **Error Reduction** - Validated configurations
- **Consistency** - Standardized project structure
- **Extensibility** - Create and share custom Presets

### For AI Agents
- **Smart Recommendation** - Auto-recommend best Preset
- **Simplified Interaction** - Select Preset, no manual setup
- **Programmability** - Structured data for AI processing
- **Dynamic Updates** - Get latest Presets from Git

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📞 Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

**Note**: The Preset system represents an important milestone in Laravel Dev Skill's transition from a "documentation tool" to a "programmable tool", enabling developers to quickly create fully configured projects and AI Agents to provide intelligent development guidance.