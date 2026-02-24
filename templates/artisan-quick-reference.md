# Artisan Command Quick Reference

Laravel's Artisan CLI provides powerful scaffolding capabilities for rapid code generation.

## 🔥 Core Generation Commands

### Model Related

```bash
# Create model (with Migration and Factory)
php artisan make:model Post

# Create model + Migration + Seeder + Controller + Policy
php artisan make:model Post -a

# Create model + Migration
php artisan make:model Post -m

# Create model + Factory
php artisan make:model Post -f

# Create model + Seeder
php artisan make:model Post -s

# Create model + Policy
php artisan make:model Post -p

# Create model + Controller
php artisan make:model Post -c

# Create model + Resource Controller
php artisan make:model Post -cr
```

### Controller Related

```bash
# Create plain controller
php artisan make:controller PostController

# Create resource controller (includes index, show, store, update, destroy methods)
php artisan make:controller PostController --resource

# Create API resource controller (excludes create and edit methods)
php artisan make:controller PostController --api

# Create singleton resource controller
php artisan make:controller ProfileController --singleton

# Create invokable controller (only __invoke method)
php artisan make:controller CheckoutController --invokable

# Create resource controller with model
php artisan make:controller PostController --model=Post
```

### Database Related

```bash
# Create migration file
php artisan make:migration create_posts_table

# Modify existing table
php artisan make:migration add_user_id_to_posts_table --table=posts

# Run migrations
php artisan migrate

# Rollback last migration
php artisan migrate:rollback

# Rollback all migrations
php artisan migrate:reset

# Rollback and re-run all migrations
php artisan migrate:refresh

# Rollback and re-run all migrations (with seeder)
php artisan migrate:refresh --seed

# Check migration status
php artisan migrate:status
```

### Model Factories and Seeders

```bash
# Create model factory
php artisan make:factory PostFactory

# Create data seeder
php artisan make:seeder PostSeeder

# Run all seeders
php artisan db:seed

# Run specific seeder
php artisan db:seed --class=PostSeeder

# Reset auto-increment IDs
php artisan db:wipe
```

### Request Validation

```bash
# Create form request class
php artisan make:request StorePostRequest

# Create form request class (with Update version)
php artisan make:request StorePostRequest --update
```

### Testing Related

```bash
# Create Feature test
php artisan make:test PostTest

# Create Unit test
php artisan make:test PostTest --unit

# Create Pest Feature test
php artisan make:test PostTest --pest

# Create Pest Unit test
php artisan make:test PostTest --pest --unit

# Create browser test (Dusk)
php artisan dusk:make LoginTest
```

### Middleware

```bash
# Create middleware
php artisan make:middleware CheckAge

# Create middleware with namespace
php artisan make:middleware Admin\Middleware\CheckRole
```

### Events and Listeners

```bash
# Create event
php artisan make:event UserRegistered

# Create listener
php artisan make:listener SendWelcomeEmail --event=UserRegistered

# Create event and listener simultaneously
php artisan make:event-and-listener UserRegistered --listener=SendWelcomeEmail
```

### Jobs and Queues

```bash
# Create Job
php artisan make:job ProcessPodcast

# Create Job with queue
php artisan make:job ProcessPodcast --queued

# Create mail class
php artisan make:mail OrderShipped

# Create notification class
php artisan make:notification InvoicePaid

# Create command
php artisan make:command SendEmails
```

### Resource Classes

```bash
# Create API resource
php artisan make:resource PostResource

# Create API resource collection
php artisan make:resource PostCollection --collection
```

### Policies and Gates

```bash
# Create policy
php artisan make:policy PostPolicy

# Create policy with model
php artisan make:policy PostPolicy --model=Post

# Create gate (defined in AuthServiceProvider)
php artisan make:gate UserIsAdmin
```

## 🎨 Filament Related

```bash
# Create Filament resource
php artisan make:filament-resource Post

# Create Filament resource without migration
php artisan make:filament-resource Post --generate=false

# Create Filament resource with soft deletes
php artisan make:filament-resource Post --soft-deletes

# Create Filament page
php artisan make:filament-page Settings

# Create Filament widget
php artisan make:filament-widget StatsOverview

# Create Filament layout
php artisan make:filament-layout BlogLayout
```

## 📦 Other Useful Commands

```bash
# Clear configuration cache
php artisan config:clear

# Clear route cache
php artisan route:clear

# Clear view cache
php artisan view:clear

# Clear application cache
php artisan cache:clear

# Optimize application (cache config, routes, etc.)
php artisan optimize

# Optimize for production (includes all optimizations)
php artisan optimize:clear

# List all routes
php artisan route:list

# List routes with middleware
php artisan route:list --except-vendor

# Generate application key
php artisan key:generate

# Create symbolic link (storage)
php artisan storage:link

# List all Artisan commands
php artisan list

# Show command help
php artisan help make:model
```

## 🛠️ Development Helpers

```bash
# Tinker - Interactive REPL
php artisan tinker

# Clear compiled view files
php artisan view:clear

# Clear compiled class files
php artisan clear-compiled

# Debug routes
php artisan route:list --columns=uri,method

# Show model relationships
php artisan model:show Post

# List scheduled tasks
php artisan schedule:list

# Run scheduled tasks
php artisan schedule:run
```

## 📝 Practical Combinations

### Quick CRUD Creation
```bash
# Create model + resource controller + migration + resource class + requests
php artisan make:model Post -a
php artisan make:controller PostController --resource
php artisan make:resource PostResource
php artisan make:request StorePostRequest
php artisan make:request UpdatePostRequest
```

### Quick API Endpoint Creation
```bash
# Create API resource controller + resource class
php artisan make:controller Api/PostController --api
php artisan make:resource PostResource
```

### Quick Filament Resource Creation
```bash
# Create model + Filament resource
php artisan make:model Post -m
php artisan make:filament-resource Post
```

## 🎯 Best Practices

1. **Use `-a` flag**: Use `php artisan make:model Post -a` during development to generate all related files at once
2. **Use `--no-interaction`**: Add `--no-interaction` in scripts to avoid interactive prompts
3. **Run migrations promptly**: After creating models and migrations, run `php artisan migrate` immediately
4. **Use model factories**: Create factories to generate test data instead of manually writing seeders
5. **Verify routes**: Use `php artisan route:list` to check if routes are registered correctly

## 📚 Related Documentation

- View complete Artisan command list: `php artisan list`
- View command help: `php artisan help <command>`
- Artisan docs: `references/current/artisan.md`
- Controllers docs: `references/current/controllers.md`
- Eloquent docs: `references/current/eloquent.md`
- Testing docs: `references/current/testing.md`