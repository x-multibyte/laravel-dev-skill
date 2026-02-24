# Laravel Preset System Usage Guide

## 🎯 What is a Preset?

A Preset is an out-of-the-box Laravel project configuration, like a "shopping list" or "solution". When a developer chooses a Preset, the system automatically creates a fully configured project without manual setup.

## 📦 Available Presets

### 1. basic - Basic Project
- **Description**: Simplest Laravel project with no extra dependencies
- **Use Case**: Quick start, learning Laravel
- **Estimated Time**: 2 minutes
- **Difficulty**: Beginner

### 2. fullstack-app - Full-stack Application
- **Description**: Includes frontend framework, authentication, real-time communication features
- **Use Case**: Complete web application development
- **Features**:
  - Laravel Fortify authentication
  - Laravel Sanctum API authentication
  - Laravel Reverb real-time communication
  - Spatie Laravel Permission authorization
  - Alpine.js + Tailwind CSS frontend
- **Estimated Time**: 5 minutes
- **Difficulty**: Intermediate

### 3. api-only - API-only Project
- **Description**: Pure API backend project, frontend-backend separation
- **Use Case**: Mobile app backend, SPA backend
- **Features**:
  - Laravel Sanctum authentication
  - API Resources
  - Query Builder
  - Rate limiting
- **Estimated Time**: 3 minutes
- **Difficulty**: Beginner

### 4. realtime-app - Real-time Application
- **Description**: Includes WebSocket server and client
- **Use Case**: Chat apps, real-time notifications, collaboration tools
- **Features**:
  - Laravel Reverb server
  - Laravel Echo client
  - Pusher.js WebSocket library
- **Estimated Time**: 4 minutes
- **Difficulty**: Intermediate

### 5. custom-template - Custom Template
- **Description**: Demonstrates how to create your own Preset
- **Use Case**: Learning Preset creation, custom project configuration
- **Estimated Time**: 3 minutes
- **Difficulty**: Beginner

## 🛠️ Using Preset Manager

### List All Presets

```bash
bash skills/laravel-dev/scripts/preset_manager.sh --list
```

Output:
```
[INFO] Available Presets:

  1. api-only
     Description: Pure API backend project with Sanctum auth, API resources, rate limiting
     Category: api | Difficulty: beginner | Estimated Time: 3 minutes

  2. basic
     Description: Basic Laravel project with no extra dependencies, quick start
     Category: basic | Difficulty: beginner | Estimated Time: 2 minutes

  ...
```

### View Preset Summary

```bash
bash skills/laravel-dev/scripts/preset_manager.sh --summary fullstack-app
```

Output:
```
=== Preset Summary ===

Name: fullstack-app
Version: 1.0.0
Description: Full-stack Laravel application with frontend framework, auth, real-time communication
Author: laravel-dev

=== Laravel Configuration ===
Version: ^12.0
Strict Locking: false

=== Dependencies ===
Composer Packages:
  - laravel/fortify: ^1.0
  - laravel/sanctum: ^4.0
  - laravel/reverb: ^1.0
  - spatie/laravel-permission: ^7.0
NPM Packages:
  - laravel-echo: ^1.0
  - pusher-js: ^8.0
  - alpinejs: ^3.0
  - @tailwindcss/forms: ^0.5

=== Database ===
Type: mysql
Version: 8.0

=== Authentication ===
Driver: fortify
Features: 2fa email-verification registration password-reset

=== Metadata ===
Category: fullstack
Difficulty: intermediate
Estimated Time: 5 minutes

=== Tags ===
fullstack auth realtime complete
```

### Check Dependency Compatibility

```bash
bash skills/laravel-dev/scripts/preset_manager.sh --check fullstack-app
```

Output:
```
[INFO] Checking dependency compatibility: fullstack-app
[INFO]   PHP Version: 8.3.27 (Required: >=8.2)
[INFO]   Composer Version: 2.8.1 (Required: >=2.0)
[INFO]   Node.js Version: v25.6.1 (Required: >=18.0)
[SUCCESS] All dependency checks passed
```

### Validate Preset

```bash
bash skills/laravel-dev/scripts/preset_manager.sh --validate fullstack-app
```

### Parse Preset Configuration

```bash
bash skills/laravel-dev/scripts/preset_manager.sh --parse fullstack-app
```

## 📝 Creating Custom Preset

### 1. Copy Template

```bash
cp skills/laravel-dev/templates/presets/custom-template.json skills/laravel-dev/templates/presets/my-preset.json
```

### 2. Edit Configuration

Edit `my-preset.json`, modify the following fields:

```json
{
  "name": "my-preset",
  "version": "1.0.0",
  "description": "My custom Preset",
  "author": "your-name",
  "laravel": {
    "version": "^12.0",
    "strict": false
  },
  "dependencies": {
    "composer": {
      "laravel/fortify": "^1.0"
    },
    "npm": {
      "alpinejs": "^3.0"
    }
  },
  "database": {
    "type": "mysql",
    "version": "8.0"
  },
  "env_template": {
    "APP_NAME": "My App",
    "DB_CONNECTION": "mysql"
  },
  "auth": {
    "driver": "fortify",
    "features": ["2fa", "email-verification"]
  },
  "commands": [
    "php artisan fortify:install",
    "php artisan migrate"
  ],
  "hooks": {
    "before_install": ["echo 'Starting installation...'"],
    "after_install": ["php artisan key:generate"]
  },
  "templates": [],
  "extends": null,
  "requires": {
    "php": ">=8.2",
    "composer": ">=2.0"
  },
  "metadata": {
    "tags": ["custom", "my-preset"],
    "category": "custom",
    "difficulty": "beginner",
    "estimated_time": "3 minutes"
  }
}
```

### 3. Validate Preset

```bash
bash skills/laravel-dev/scripts/preset_manager.sh --validate my-preset
```

### 4. Use Preset

```bash
bash skills/laravel-dev/scripts/preset_manager.sh --summary my-preset
```

## 🔧 Preset Advanced Features

### 1. Dependency Inheritance

A Preset can inherit configuration from another Preset:

```json
{
  "name": "extended-app",
  "extends": "basic",
  "dependencies": {
    "composer": {
      "laravel/fortify": "^1.0"
    }
  }
}
```

### 2. Lifecycle Hooks

Execute custom commands at different project lifecycle stages:

```json
{
  "hooks": {
    "before_install": ["echo 'Preparing to start installation...'"],
    "after_install": ["php artisan key:generate"],
    "before_migration": ["php artisan migrate:fresh"],
    "after_migration": ["php artisan db:seed"]
  }
}
```

### 3. Template Injection

Inject custom code templates:

```json
{
  "templates": [
    {
      "source": "templates/auth/fortify.php",
      "destination": "config/fortify.php",
      "overwrite": false
    }
  ]
}
```

### 4. Environment Variable Template

Pre-configure .env file:

```json
{
  "env_template": {
    "APP_NAME": "My App",
    "APP_ENV": "local",
    "DB_CONNECTION": "mysql",
    "BROADCAST_DRIVER": "reverb"
  }
}
```

## 🌍 Git Sync

### Sync Preset from Git Repository

```bash
bash skills/laravel-dev/scripts/sync_presets.sh --repo https://github.com/user/presets
```

### Auto Sync

Configure in `config/settings.json`:

```json
{
  "presets": {
    "auto_sync": true,
    "sync_interval": 86400,
    "repository": "https://github.com/laravel-dev/presets"
  }
}
```

## 📖 Preset Schema Reference

Complete Preset Schema definition in `config/preset-schema.json`, includes:

- **Required Fields**: `name`, `version`, `description`, `laravel`
- **Optional Fields**: `dependencies`, `database`, `env_template`, `auth`, `commands`, `hooks`, `templates`, `extends`, `requires`, `metadata`
- **Validation Rules**: Use JSON Schema for format validation

## 💡 Best Practices

1. **Naming Convention**: Use kebab-case (e.g., `fullstack-app`)
2. **Version Management**: Use semantic versioning (e.g., `1.0.0`)
3. **Clear Dependencies**: Explicitly specify all required dependencies and versions
4. **Environment Checks**: Define `requires` field to ensure environment compatibility
5. **Reasonable Hooks**: Use hooks appropriately, avoid over-complexity
6. **Complete Documentation**: Provide clear descriptions and tags

## 🔗 Related Resources

- [Preset Schema](skills/laravel-dev/config/preset-schema.json)
- [Preset Manager](skills/laravel-dev/scripts/preset_manager.sh)
- [Artisan Command Reference](skills/laravel-dev/templates/artisan-quick-reference.md)
- [Quick Index](skills/laravel-dev/templates/INDEX.md)

---

**Tip**: The core value of the Preset system is "out-of-the-box", choosing the right Preset can save a lot of configuration time!