# Laravel Dev Presets

A comprehensive collection of Laravel project presets for rapid development. Used by [Laravel Dev Skill](https://github.com/x-multibyte/laravel-dev-skill) to provide out-of-the-box project configurations.

## 📦 Available Presets

### API Projects (`api/`)
- `10.json` - Laravel 10.x API project
- `11.json` - Laravel 11.x API project
- `12.json` - Laravel 12.x API project

### Filament (`filament/`)
- `v4.json` - Filament v4 configuration
- `v5.json` - Filament v5 configuration

### Framework (`framework/`)
- `10.json` - Laravel 10.x base framework
- `11.json` - Laravel 11.x base framework
- `12.json` - Laravel 12.x base framework

### Laravel Packages (`laravel-package/`)
- `blade-component.json` - Blade component development
- `filament-plugin-skeleton.json` - Filament plugin skeleton
- `meta-package.json` - Meta package template
- `package-skeleton-laravel.json` - Laravel package skeleton
- `package.json` - Generic package template

### Starter Kits (`starter-kits/`)
- `livewire.json` - Livewire starter kit
- `react.json` - React starter kit
- `svelte.json` - Svelte starter kit
- `vue.json` - Vue starter kit

## 📐 Preset Structure

Each preset follows this JSON schema:

```json
{
  "name": "preset-name",
  "version": "1.0.0",
  "description": "Preset description",
  "author": "laravel-dev",
  "laravel": {
    "version": "^12.0"
  },
  "dependencies": {
    "composer": {},
    "npm": {}
  },
  "commands": [],
  "metadata": {
    "category": "category",
    "difficulty": "beginner"
  }
}
```

## 🔄 Version Control

- **File name** = Laravel version (e.g., `12.json` for Laravel 12.x)
- **JSON version** = Preset feature version (e.g., `"version": "2.1.0"`)

## 🚀 Usage

### With Laravel Dev Skill

```bash
# List all presets
bash skills/laravel-dev/scripts/preset_manager.sh --list

# View preset summary
bash skills/laravel-dev/scripts/preset_manager.sh --summary api 12

# Apply preset
bash skills/laravel-dev/scripts/preset_manager.sh --apply api 12
```

### Direct Usage

1. Copy the preset JSON file to your project
2. Parse the configuration
3. Apply dependencies and commands

## 🤝 Contributing

1. Fork this repository
2. Create a new preset or improve existing ones
3. Submit a pull request

### Adding a New Preset

1. Choose the appropriate category folder
2. Create a new JSON file following the schema
3. Validate against `preset-schema.json`
4. Test with Laravel Dev Skill
5. Submit PR

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Related Projects

- [Laravel Dev Skill](https://github.com/x-multibyte/laravel-dev-skill) - AI-powered Laravel development toolkit
- [Laravel Dev CLI](https://github.com/x-multibyte/laravel-dev-cli) - Composer CLI tool (coming soon)

---

**Note**: This repository is designed to work seamlessly with Laravel Dev Skill. Each preset is validated and tested for compatibility with specific Laravel versions.