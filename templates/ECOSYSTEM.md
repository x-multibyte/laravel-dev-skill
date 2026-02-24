# Laravel Ecosystem Packages

Quick configuration guide for Laravel ecosystem packages (Sail, Reverb, Echo).

## 🚀 Quick Start

### Configure All Ecosystem Packages at Once

```bash
bash skills/laravel-dev/scripts/setup-ecosystem.sh --all
```

This will automatically configure:
- ✅ Sail (Docker containerization)
- ✅ Reverb (WebSocket server)
- ✅ Echo (WebSocket client)

### Configure Individually

```bash
# Configure Sail only
bash skills/laravel-dev/scripts/setup-ecosystem.sh --sail

# Configure Reverb only
bash skills/laravel-dev/scripts/setup-ecosystem.sh --reverb

# Configure Echo only
bash skills/laravel-dev/scripts/setup-ecosystem.sh --echo
```

## 📚 Configuration Guide

For detailed configuration steps and troubleshooting, please see:
📖 **[Complete Configuration Guide](skills/laravel-dev/templates/ecosystem-config-guide.md)**

## 📁 Configuration Templates

Pre-configured template files are located in `skills/laravel-dev/templates/config/` directory:

### 1. Sail Configuration
- `docker-compose.yml` - Docker service configuration
- Includes MySQL, Redis, Meilisearch, Mailhog services

### 2. Reverb Configuration
- `broadcasting.reverb.php` - Broadcasting configuration
- `supervisor-reverb.conf` - Production environment Supervisor configuration

### 3. Echo Configuration
- `echo.bootstrap.js` - Echo client configuration
- Supports both Reverb and Pusher servers

## 💡 Usage Examples

### Sail Quick Start

```bash
# 1. Configure Sail
bash skills/laravel-dev/scripts/setup-ecosystem.sh --sail

# 2. Start containers
./vendor/bin/sail up

# 3. Run migrations
./vendor/bin/sail artisan migrate

# 4. Access application
open http://localhost
```

### Reverb + Echo Real-time Communication

```bash
# 1. Configure Reverb
bash skills/laravel-dev/scripts/setup-ecosystem.sh --reverb

# 2. Configure Echo
bash skills/laravel-dev/scripts/setup-ecosystem.sh --echo

# 3. Start Reverb
php artisan reverb:start

# 4. Build frontend
npm run dev
```

## 🔍 Troubleshooting

### Sail Issues

```bash
# View container logs
./vendor/bin/sail logs

# Rebuild containers
./vendor/bin/sail down && ./vendor/bin/sail build --no-cache

# Check Docker status
docker ps -a
```

### Reverb Issues

```bash
# Check configuration
php artisan config:show broadcasting

# View logs
tail -f storage/logs/laravel.log

# Test connection
wscat -c ws://localhost:8080/app/laravel
```

### Echo Issues

```javascript
// Enable debugging
Echo.connector.options.debug = true;

console.log('Connection state:', states.current);
```

## 📖 Related Documentation

- [Complete Configuration Guide](skills/laravel-dev/templates/ecosystem-config-guide.md)
- [Artisan Command Reference](skills/laravel-dev/templates/artisan-quick-reference.md)
- [Skill Quick Index](skills/laravel-dev/templates/INDEX.md)

## 🆘 Common Questions

**Q: Sail startup failed?**
A: Check if Docker Desktop is running and ports are not occupied.

**Q: Reverb connection failed?**
A: Check if `REVERB_*` configuration in `.env` is correct and confirm ports are not occupied.

**Q: Echo cannot receive events?**
A: Check if channel configuration is correct and private channels are authorized.

**Q: How to configure for production?**
A: Refer to `supervisor-reverb.conf` template and use Supervisor to manage processes.

## 📝 Version History

- Added ecosystem package configuration guide
- Added configuration template files
- Added quick configuration scripts
- Added detailed troubleshooting guide

## 🤝 Contributing

For improvement suggestions, please submit Issue or Pull Request.

---

**Tip**: After configuration, remember to run `php artisan config:cache` to clear configuration cache.