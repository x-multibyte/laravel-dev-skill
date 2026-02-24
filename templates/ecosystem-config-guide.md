# Laravel Ecosystem Configuration Guide

This guide provides detailed configuration steps for Laravel ecosystem packages to help you quickly integrate complex third-party services.

## 📋 Table of Contents

- [Sail - Docker Containerization](#sail---docker-containerization)
- [Reverb - WebSocket Server](#reverb---websocket-server)
- [Laravel Echo + Pusher.js - WebSocket Client](#laravel-echo--pusherjs---websocket-client)

---

## Sail - Docker Containerization

### Prerequisites
- macOS or Linux
- Docker Desktop installed and running

### Quick Start

```bash
# 1. Install Sail
composer require laravel/sail --dev

# 2. Publish Sail configuration
php artisan sail:install

# 3. Select required services (can select multiple)
# MySQL, pgsql, mariadb, redis, memcached, meilisearch, minio, mailhog, selenium

# 4. Start Sail
./vendor/bin/sail up

# 5. Run migrations
./vendor/bin/sail artisan migrate
```

### Detailed Configuration

#### 1. Environment Variable Configuration

Edit `.env` file:

```bash
# Database configuration
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=sail
DB_PASSWORD=password

# Redis configuration
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

# Meilisearch configuration (if used)
SCOUT_DRIVER=meilisearch
MEILISEARCH_HOST=http://meilisearch:7700
MEILISEARCH_KEY=masterKey

# Mailhog configuration (if used)
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_ENCRYPTION=null
```

#### 2. Service Configuration Example

Edit `docker-compose.yml`:

```yaml
services:
    mysql:
        image: 'mysql/mysql-server:8.0'
        ports:
            - '${FORWARD_DB_PORT:-3306}:3306'
        environment:
            MYSQL_ROOT_PASSWORD: '${DB_PASSWORD}'
            MYSQL_DATABASE: '${DB_DATABASE}'
            MYSQL_USER: '${DB_USERNAME}'
            MYSQL_PASSWORD: '${DB_PASSWORD}'
            MYSQL_ALLOW_EMPTY_PASSWORD: 'yes'
        volumes:
            - 'sail-mysql:/var/lib/mysql'
        networks:
            - sail

    redis:
        image: 'redis:alpine'
        ports:
            - '${FORWARD_REDIS_PORT:-6379}:6379'
        volumes:
            - 'sail-redis:/data'
        networks:
            - sail

    meilisearch:
        image: 'getmeili/meilisearch:latest'
        ports:
            - '${FORWARD_MEILISEARCH_PORT:-7700}:7700'
        environment:
            MEILI_MASTER_KEY: '${MEILISEARCH_KEY}'
        volumes:
            - 'sail-meilisearch:/meili_data'
        networks:
            - sail

    mailhog:
        image: 'mailhog/mailhog:latest'
        ports:
            - '${FORWARD_MAILHOG_PORT:-1025}:1025'
            - '${FORWARD_MAILHOG_DASHBOARD_PORT:-8025}:8025'
        networks:
            - sail
```

#### 3. Common Commands

```bash
# Start services
./vendor/bin/sail up

# Start in background
./vendor/bin/sail up -d

# Stop services
./vendor/bin/sail stop

# Restart services
./vendor/bin/sail restart

# View logs
./vendor/bin/sail logs

# Run Artisan commands
./vendor/bin/sail artisan migrate

# Enter container
./vendor/bin/sail shell

# Run Composer
./vendor/bin/sail composer require laravel/sanctum

# Run NPM
./vendor/bin/sail npm install
./vendor/bin/sail npm run dev

# Build Docker images
./vendor/bin/sail build

# Rebuild all containers
./vendor/bin/sail down && ./vendor/bin/sail up
```

#### 4. Common Issues

**Permission Issues (Linux)**
```bash
# Fix storage directory permissions
./vendor/bin/sail exec app chown -R www-data:www-data storage
./vendor/bin/sail exec app chmod -R 775 storage
```

**Port Conflicts**
```bash
# Modify ports in .env
FORWARD_DB_PORT=3307
FORWARD_REDIS_PORT=6380
```

**Clean Up Containers**
```bash
# Stop and remove all containers
./vendor/bin/sail down

# Remove all volumes
./vendor/bin/sail down -v
```

---

## Reverb - WebSocket Server

### Prerequisites
- Laravel 10.x or higher
- Redis (for production environment)

### Quick Start

```bash
# 1. Install Reverb
composer require laravel/reverb

# 2. Publish configuration
php artisan reverb:install

# 3. Generate keys
php artisan reverb:generate-keys

# 4. Start Reverb server
php artisan reverb:start
```

### Detailed Configuration

#### 1. Environment Variable Configuration

Edit `.env` file:

```bash
# Reverb configuration
REVERB_APP_ID=my-app-id
REVERB_APP_KEY=my-app-key
REVERB_APP_SECRET=my-app-secret
REVERB_HOST=0.0.0.0
REVERB_PORT=8080
REVERB_SCHEME=http

# HTTPS recommended for production
# REVERB_SCHEME=https

# Enable CORS (development environment)
REVERB_ALLOWED_ORIGINS=*

# Redis configuration (production environment)
REVERB_REDIS_HOST=127.0.0.1
REVERB_REDIS_PORT=6379
REVERB_REDIS_PASSWORD=
REVERB_REDIS_DB=0

# Enable debug (development environment)
REVERB_DEBUG=true
```

#### 2. Broadcasting Configuration

Edit `config/broadcasting.php`:

```php
<?php

return [
    'default' => env('BROADCAST_CONNECTION', 'reverb'),

    'connections' => [
        'reverb' => [
            'driver' => 'reverb',
            'key' => env('REVERB_APP_KEY'),
            'secret' => env('REVERB_APP_SECRET'),
            'app_id' => env('REVERB_APP_ID'),
            'options' => [
                'host' => env('REVERB_HOST', '0.0.0.0'),
                'port' => env('REVERB_PORT', 8080),
                'scheme' => env('REVERB_SCHEME', 'http'),
                'useTLS' => env('REVERB_SCHEME', 'http') === 'https',
            ],
        ],

        'pusher' => [
            'driver' => 'pusher',
            'key' => env('PUSHER_APP_KEY'),
            'secret' => env('PUSHER_APP_SECRET'),
            'app_id' => env('PUSHER_APP_ID'),
            'options' => [
                'host' => env('PUSHER_HOST', '127.0.0.1'),
                'port' => env('PUSHER_PORT', 6001),
                'scheme' => env('PUSHER_SCHEME', 'http'),
                'encrypted' => true,
                'useTLS' => env('PUSHER_SCHEME', 'https') === 'https',
            ],
        ],
    ],
];
```

#### 3. Event Configuration

Create event `app/Events/MessageSent.php`:

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct($message)
    {
        $this->message = $message;
    }

    public function broadcastOn(): Channel
    {
        return new Channel('chat');
    }

    public function broadcastWith(): array
    {
        return [
            'message' => $this->message,
        ];
    }
}
```

#### 4. Channel Authorization

Edit `routes/channels.php`:

```php
<?php

use Illuminate\Support\Facades\Broadcast;

// Public channel (no authorization required)
Broadcast::channel('chat', function () {
    return true;
});

// Private channel (authentication required)
Broadcast::channel('chat.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

// Presence channel
Broadcast::channel('presence.chat', function ($user) {
    return [
        'id' => $user->id,
        'name' => $user->name,
    ];
});
```

#### 5. Start Server

```bash
# Development environment
php artisan reverb:start

# Production environment (using Supervisor)
# Edit /etc/supervisor/conf.d/reverb.conf
```

#### 6. Supervisor Configuration (Production Environment)

Create `/etc/supervisor/conf.d/reverb.conf`:

```ini
[program:reverb]
command=php /var/www/html/your-project/artisan reverb:start
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/html/your-project/storage/logs/reverb.log
```

Restart Supervisor:

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start reverb
```

---

## Laravel Echo + Pusher.js - WebSocket Client

### Prerequisites
- Reverb or Pusher server configured
- Laravel Echo client library

### Quick Start

```bash
# 1. Install Echo and Pusher.js
npm install --save-dev laravel-echo pusher-js

# 2. Copy example configuration
cp resources/js/bootstrap.example.js resources/js/bootstrap.js
```

### Detailed Configuration

#### 1. Echo Configuration

Edit `resources/js/bootstrap.js`:

```javascript
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

// Configure Echo
window.Echo = new Echo({
    broadcaster: 'reverb', // or 'pusher'
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST,
    wsPort: import.meta.env.VITE_REVERB_PORT ?? 8080,
    wssPort: import.meta.env.VITE_REVERB_PORT ?? 8080,
    forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'http') === 'https',
    enabledTransports: ['ws', 'wss'],
});

// If using Pusher
// window.Echo = new Echo({
//     broadcaster: 'pusher',
//     key: import.meta.env.VITE_PUSHER_APP_KEY,
//     cluster: import.meta.env.VITE_PUSHER_APP_CLUSTER ?? 'mt1',
//     wsHost: import.meta.env.VITE_PUSHER_HOST ?? `ws-${import.meta.env.VITE_PUSHER_APP_CLUSTER ?? 'mt1'}.pusher.com`,
//     wsPort: 80,
//     wssPort: 443,
//     forceTLS: true,
//     enabledTransports: ['ws', 'wss'],
// });
```

#### 2. Environment Variable Configuration

Edit `.env`:

```bash
# Reverb configuration (server side)
REVERB_APP_ID=my-app-id
REVERB_APP_KEY=my-app-key
REVERB_APP_SECRET=my-app-secret
REVERB_HOST=0.0.0.0
REVERB_PORT=8080
REVERB_SCHEME=http

# Vite configuration (client side)
VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST="${REVERB_HOST}"
VITE_REVERB_PORT="${REVERB_PORT}"
VITE_REVERB_SCHEME="${REVERB_SCHEME}"
```

#### 3. Listening to Events

##### Listen to Public Channel

```javascript
// Listen to public channel
window.Echo.channel('chat')
    .listen('MessageSent', (e) => {
        console.log('Message received:', e.message);
        // Update UI
        appendMessage(e.message);
    });

// Listen to all events (for debugging)
window.Echo.channel('chat')
    .listen('.*', (e) => {
        console.log('Event received:', e);
    });
```

##### Listen to Private Channel

```javascript
// Listen to private channel
window.Echo.private(`chat.${userId}`)
    .listen('MessageSent', (e) => {
        console.log('Private message received:', e.message);
    });
```

##### Listen to Presence Channel

```javascript
// Listen to presence channel
window.Echo.join(`presence.chat`)
    .here((users) => {
        // Currently online users
        console.log('Online users:', users);
    })
    .joining((user) => {
        // User joined
        console.log('User joined:', user);
        showNotification(`${user.name} joined the chat`);
    })
    .leaving((user) => {
        // User left
        console.log('User left:', user);
        showNotification(`${user.name} left the chat`);
    });
```

#### 4. Sending Events

Broadcast events in controller:

```php
<?php

namespace App\Http\Controllers;

use App\Events\MessageSent;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function sendMessage(Request $request)
    {
        $message = $request->input('message');

        // Broadcast event
        broadcast(new MessageSent($message));

        return response()->json(['status' => 'Message sent']);
    }
}
```

#### 5. Frontend Integration

Edit `resources/js/app.js`:

```javascript
import './bootstrap';

// Listen to channel
window.Echo.channel('chat')
    .listen('MessageSent', (e) => {
        appendMessageToChat(e.message);
    });

// Send message function
function sendMessage(message) {
    axios.post('/chat/send', { message })
        .then(response => {
            console.log('Message sent');
        })
        .catch(error => {
            console.error('Send failed:', error);
        });
}
```

#### 6. Common Issues

**Connection Failed**
```javascript
// Add error handling
window.Echo.connector.pusher.connection.bind('error', (err) => {
    console.error('WebSocket connection error:', err);
});

window.Echo.connector.pusher.connection.bind('disconnected', () => {
    console.log('WebSocket disconnected');
});
```

**Authentication Failed**
```php
// Check channel authorization
php artisan route:list --name=broadcasting
```

**CORS Issues**
```bash
# Configure allowed origins in .env
REVERB_ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com
```

---

## 🔗 Complete Example: Real-time Chat Application

### 1. Server Configuration

```bash
# Install dependencies
composer require laravel/reverb
php artisan reverb:install
php artisan reverb:generate-keys

# Start Reverb
php artisan reverb:start
```

### 2. Client Configuration

```bash
# Install Echo
npm install --save-dev laravel-echo pusher-js
```

```javascript
// resources/js/bootstrap.js
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST,
    wsPort: import.meta.env.VITE_REVERB_PORT ?? 8080,
    wssPort: import.meta.env.VITE_REVERB_PORT ?? 8080,
    forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'http') === 'https',
    enabledTransports: ['ws', 'wss'],
});
```

### 3. Create Event

```bash
php artisan make:event MessageSent
```

### 4. Create Controller

```bash
php artisan make:controller ChatController
```

### 5. Add Routes

Edit `routes/web.php`:

```php
use App\Http\Controllers\ChatController;

Route::post('/chat/send', [ChatController::class, 'sendMessage']);
```

### 6. Frontend Usage

```javascript
// Listen to messages
window.Echo.channel('chat')
    .listen('MessageSent', (e) => {
        console.log('Message received:', e.message);
    });

// Send message
function sendMessage(message) {
    axios.post('/chat/send', { message });
}
```

---

## 📚 Related Documentation

- [Sail Documentation](references/current/sail.md)
- [Reverb Documentation](references/current/reverb.md)
- [Broadcasting Documentation](references/current/broadcasting.md)
- [Events Documentation](references/current/events.md)

## 🆘 Troubleshooting

### Sail Issues
```bash
# View container logs
./vendor/bin/sail logs

# Rebuild containers
./vendor/bin/sail down && ./vendor/bin/sail up

# Check Docker status
docker ps
```

### Reverb Issues
```bash
# Check configuration
php artisan config:cache

# View logs
tail -f storage/logs/laravel.log

# Test connection
wscat -c ws://localhost:8080/app/my-app-key
```

### Echo Issues
```javascript
// Enable debug
window.Echo.connector.pusher.connection.bind('state_change', (states) => {
    console.log('Connection state:', states.current);
});
```

---

**Tip**: After configuration is complete, remember to run `php artisan config:cache` to clear configuration cache.