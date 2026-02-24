# Database


## Database

# Database: Getting Started

- [Introduction](#introduction)
    - [Configuration](#configuration)
    - [Read and Write Connections](#read-and-write-connections)
- [Running SQL Queries](#running-queries)
    - [Using Multiple Database Connections](#using-multiple-database-connections)
    - [Listening for Query Events](#listening-for-query-events)
    - [Monitoring Cumulative Query Time](#monitoring-cumulative-query-time)
- [Database Transactions](#database-transactions)
- [Connecting to the Database CLI](#connecting-to-the-database-cli)
- [Inspecting Your Databases](#inspecting-your-databases)
- [Monitoring Your Databases](#monitoring-your-databases)

<a name="introduction"></a>
## Introduction

Almost every modern web application interacts with a database. Laravel makes interacting with databases extremely simple across a variety of supported databases using raw SQL, a [fluent query builder](/docs/{{version}}/queries), and the [Eloquent ORM](/docs/{{version}}/eloquent). Currently, Laravel provides first-party support for five databases:

<div class="content-list" markdown="1">

- MariaDB 10.10+ ([Version Policy](https://mariadb.org/about/#maintenance-policy))
- MySQL 5.7+ ([Version Policy](https://en.wikipedia.org/wiki/MySQL#Release_history))
- PostgreSQL 11.0+ ([Version Policy](https://www.postgresql.org/support/versioning/))
- SQLite 3.8.8+
- SQL Server 2017+ ([Version Policy](https://docs.microsoft.com/en-us/lifecycle/products/?products=sql-server))

</div>

<a name="configuration"></a>
### Configuration

The configuration for Laravel's database services is located in your application's `config/database.php` configuration file. In this file, you may define all of your database connections, as well as specify which connection should be used by default. Most of the configuration options within this file are driven by the values of your application's environment variables. Examples for most of Laravel's supported database systems are provided in this file.

By default, Laravel's sample [environment configuration](/docs/{{version}}/configuration#environment-configuration) is ready to use with [Laravel Sail](/docs/{{version}}/sail), which is a Docker configuration for developing Laravel applications on your local machine. However, you are free to modify your database configuration as needed for your local database.

<a name="sqlite-configuration"></a>
#### SQLite Configuration

SQLite databases are contained within a single file on your filesystem. You can create a new SQLite database using the `touch` command in your terminal: `touch database/database.sqlite`. After the database has been created, you may easily configure your environment variables to point to this database by placing the absolute path to the database in the `DB_DATABASE` environment variable:

```ini
DB_CONNECTION=sqlite
DB_DATABASE=/absolute/path/to/database.sqlite
```

To enable foreign key constraints for SQLite connections, you should set the `DB_FOREIGN_KEYS` environment variable to `true`:

```ini
DB_FOREIGN_KEYS=true
```

<a name="mssql-configuration"></a>
#### Microsoft SQL Server Configuration

To use a Microsoft SQL Server database, you should ensure that you have the `sqlsrv` and `pdo_sqlsrv` PHP extensions installed as well as any dependencies they may require such as the Microsoft SQL ODBC driver.

<a name="configuration-using-urls"></a>
#### Configuration Using URLs

Typically, database connections are configured using multiple configuration values such as `host`, `database`, `username`, `password`, etc. Each of these configuration values has its own corresponding environment variable. This means that when configuring your database connection information on a production server, you need to manage several environment variables.

Some managed database providers such as AWS and Heroku provide a single database "URL" that contains all of the connection information for the database in a single string. An example database URL may look something like the following:

```html
mysql://root:password@127.0.0.1/forge?charset=UTF-8
```

These URLs typically follow a standard schema convention:

```html
driver://username:password@host:port/database?options
```

For convenience, Laravel supports these URLs as an alternative to configuring your database with multiple configuration options. If the `url` (or corresponding `DATABASE_URL` environment variable) configuration option is present, it will be used to extract the database connection and credential information.

<a name="read-and-write-connections"></a>
### Read and Write Connections

Sometimes you may wish to use one database connection for SELECT statements, and another for INSERT, UPDATE, and DELETE statements. Laravel makes this a breeze, and the proper connections will always be used whether you are using raw queries, the query builder, or the Eloquent ORM.

To see how read / write connections should be configured, let's look at this example:

    'mysql' => [
        'read' => [
            'host' => [
                '192.168.1.1',
                '196.168.1.2',
            ],
        ],
        'write' => [
            'host' => [
                '196.168.1.3',
            ],
        ],
        'sticky' => true,
        'driver' => 'mysql',
        'database' => 'database',
        'username' => 'root',
        'password' => '',
        'charset' => 'utf8mb4',
        'collation' => 'utf8mb4_unicode_ci',
        'prefix' => '',
    ],

Note that three keys have been added to the configuration array: `read`, `write` and `sticky`. The `read` and `write` keys have array values containing a single key: `host`. The rest of the database options for the `read` and `write` connections will be merged from the main `mysql` configuration array.

You only need to place items in the `read` and `write` arrays if you wish to override the values from the main `mysql` array. So, in this case, `192.168.1.1` will be used as the host for the "read" connection, while `192.168.1.3` will be used for the "write" connection. The database credentials, prefix, character set, and all other options in the main `mysql` array will be shared across both connections. When multiple values exist in the `host` configuration array, a database host will be randomly chosen for each request.

<a name="the-sticky-option"></a>
#### The `sticky` Option

The `sticky` option is an *optional* value that can be used to allow the immediate reading of records that have been written to the database during the current request cycle. If the `sticky` option is enabled and a "write" operation has been performed against the database during the current request cycle, any further "read" operations will use the "write" connection. This ensures that any data written during the request cycle can be immediately read back from the database during that same request. It is up to you to decide if this is the desired behavior for your application.

<a name="running-queries"></a>
## Running SQL Queries

Once you have configured your database connection, you may run queries using the `DB` facade. The `DB` facade provides methods for each type of query: `select`, `update`, `insert`, `delete`, and `statement`.

<a name="running-a-select-query"></a>
#### Running a Select Query

To run a basic SELECT query, you may use the `select` method on the `DB` facade:

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Support\Facades\DB;
    use Illuminate\View\View;

    class UserController extends Controller
    {
        /**
         * Show a list of all of the application's users.
         */
        public function index(): View
        {
            $users = DB::select('select * from users where active = ?', [1]);

            return view('user.index', ['users' => $users]);
        }
    }

The first argument passed to the `select` method is the SQL query, while the second argument is any parameter bindings that need to be bound to the query. Typically, these are the values of the `where` clause constraints. Parameter binding provides protection against SQL injection.

The `select` method will always return an `array` of results. Each result within the array will be a PHP `stdClass` object representing a record from the database:

    use Illuminate\Support\Facades\DB;

    $users = DB::select('select * from users');

    foreach ($users as $user) {
        echo $user->name;
    }

<a name="selecting-scalar-values"></a>
#### Selecting Scalar Values

Sometimes your database query may result in a single, scalar value. Instead of being required to retrieve the query's scalar result from a record object, Laravel allows you to retrieve this value directly using the `scalar` method:

    $burgers = DB::scalar(
        "select count(case when food = 'burger' then 1 end) as burgers from menu"
    );

<a name="selecting-multiple-result-sets"></a>
#### Selecting Multiple Result Sets

If your application calls stored procedures that return multiple result sets, you may use the `selectResultSets` method to retrieve all of the result sets returned by the stored procedure:

    [$options, $notifications] = DB::selectResultSets(
        "CALL get_user_options_and_notifications(?)", $request->user()->id
    );

<a name="using-named-bindings"></a>
#### Using Named Bindings

Instead of using `?` to represent your parameter bindings, you may execute a query using named bindings:

    $results = DB::select('select * from users where id = :id', ['id' => 1]);

<a name="running-an-insert-statement"></a>
#### Running an Insert Statement

To execute an `insert` statement, you may use the `insert` method on the `DB` facade. Like `select`, this method accepts the SQL query as its first argument and bindings as its second argument:

    use Illuminate\Support\Facades\DB;

    DB::insert('insert into users (id, name) values (?, ?)', [1, 'Marc']);

<a name="running-an-update-statement"></a>
#### Running an Update Statement

The `update` method should be used to update existing records in the database. The number of rows affected by the statement is returned by the method:

    use Illuminate\Support\Facades\DB;

    $affected = DB::update(
        'update users set votes = 100 where name = ?',
        ['Anita']
    );

<a name="running-a-delete-statement"></a>
#### Running a Delete Statement

The `delete` method should be used to delete records from the database. Like `update`, the number of rows affected will be returned by the method:

    use Illuminate\Support\Facades\DB;

    $deleted = DB::delete('delete from users');

<a name="running-a-general-statement"></a>
#### Running a General Statement

Some database statements do not return any value. For these types of operations, you may use the `statement` method on the `DB` facade:

    DB::statement('drop table users');

<a name="running-an-unprepared-statement"></a>
#### Running an Unprepared Statement

Sometimes you may want to execute an SQL statement without binding any values. You may use the `DB` facade's `unprepared` method to accomplish this:

    DB::unprepared('update users set votes = 100 where name = "Dries"');

> [!WARNING]  
> Since unprepared statements do not bind parameters, they may be vulnerable to SQL injection. You should never allow user controlled values within an unprepared statement.

<a name="implicit-commits-in-transactions"></a>
#### Implicit Commits

When using the `DB` facade's `statement` and `unprepared` methods within transactions you must be careful to avoid statements that cause [implicit commits](https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html). These statements will cause the database engine to indirectly commit the entire transaction, leaving Laravel unaware of the database's transaction level. An example of such a statement is creating a database table:

    DB::unprepared('create table a (col varchar(1) null)');

Please refer to the MySQL manual for [a list of all statements](https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html) that trigger implicit commits.

<a name="using-multiple-database-connections"></a>
### Using Multiple Database Connections

If your application defines multiple connections in your `config/database.php` configuration file, you may access each connection via the `connection` method provided by the `DB` facade. The connection name passed to the `connection` method should correspond to one of the connections listed in your `config/database.php` configuration file or configured at runtime using the `config` helper:

    use Illuminate\Support\Facades\DB;

    $users = DB::connection('sqlite')->select(/* ... */);

You may access the raw, underlying PDO instance of a connection using the `getPdo` method on a connection instance:

    $pdo = DB::connection()->getPdo();

<a name="listening-for-query-events"></a>
### Listening for Query Events

If you would like to specify a closure that is invoked for each SQL query executed by your application, you may use the `DB` facade's `listen` method. This method can be useful for logging queries or debugging. You may register your query listener closure in the `boot` method of a [service provider](/docs/{{version}}/providers):

    <?php

    namespace App\Providers;

    use Illuminate\Database\Events\QueryExecuted;
    use Illuminate\Support\Facades\DB;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * Register any application services.
         */
        public function register(): void
        {
            // ...
        }

        /**
         * Bootstrap any application services.
         */
        public function boot(): void
        {
            DB::listen(function (QueryExecuted $query) {
                // $query->sql;
                // $query->bindings;
                // $query->time;
            });
        }
    }

<a name="monitoring-cumulative-query-time"></a>
### Monitoring Cumulative Query Time

A common performance bottleneck of modern web applications is the amount of time they spend querying databases. Thankfully, Laravel can invoke a closure or callback of your choice when it spends too much time querying the database during a single request. To get started, provide a query time threshold (in milliseconds) and closure to the `whenQueryingForLongerThan` method. You may invoke this method in the `boot` method of a [service provider](/docs/{{version}}/providers):

    <?php

    namespace App\Providers;

    use Illuminate\Database\Connection;
    use Illuminate\Support\Facades\DB;
    use Illuminate\Support\ServiceProvider;
    use Illuminate\Database\Events\QueryExecuted;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * Register any application services.
         */
        public function register(): void
        {
            // ...
        }

        /**
         * Bootstrap any application services.
         */
        public function boot(): void
        {
            DB::whenQueryingForLongerThan(500, function (Connection $connection, QueryExecuted $event) {
                // Notify development team...
            });
        }
    }

<a name="database-transactions"></a>
## Database Transactions

You may use the `transaction` method provided by the `DB` facade to run a set of operations within a database transaction. If an exception is thrown within the transaction closure, the transaction will automatically be rolled back and the exception is re-thrown. If the closure executes successfully, the transaction will automatically be committed. You don't need to worry about manually rolling back or committing while using the `transaction` method:

    use Illuminate\Support\Facades\DB;

    DB::transaction(function () {
        DB::update('update users set votes = 1');

        DB::delete('delete from posts');
    });

<a name="handling-deadlocks"></a>
#### Handling Deadlocks

The `transaction` method accepts an optional second argument which defines the number of times a transaction should be retried when a deadlock occurs. Once these attempts have been exhausted, an exception will be thrown:

    use Illuminate\Support\Facades\DB;

    DB::transaction(function () {
        DB::update('update users set votes = 1');

        DB::delete('delete from posts');
    }, 5);

<a name="manually-using-transactions"></a>
#### Manually Using Transactions

If you would like to begin a transaction manually and have complete control over rollbacks and commits, you may use the `beginTransaction` method provided by the `DB` facade:

    use Illuminate\Support\Facades\DB;

    DB::beginTransaction();

You can rollback the transaction via the `rollBack` method:

    DB::rollBack();

Lastly, you can commit a transaction via the `commit` method:

    DB::commit();

> [!NOTE]  
> The `DB` facade's transaction methods control the transactions for both the [query builder](/docs/{{version}}/queries) and [Eloquent ORM](/docs/{{version}}/eloquent).

<a name="connecting-to-the-database-cli"></a>
## Connecting to the Database CLI

If you would like to connect to your database's CLI, you may use the `db` Artisan command:

```shell
php artisan db
```

If needed, you may specify a database connection name to connect to a database connection that is not the default connection:

```shell
php artisan db mysql
```

<a name="inspecting-your-databases"></a>
## Inspecting Your Databases

Using the `db:show` and `db:table` Artisan commands, you can get valuable insight into your database and its associated tables. To see an overview of your database, including its size, type, number of open connections, and a summary of its tables, you may use the `db:show` command:

```shell
php artisan db:show
```

You may specify which database connection should be inspected by providing the database connection name to the command via the `--database` option:

```shell
php artisan db:show --database=pgsql
```

If you would like to include table row counts and database view details within the output of the command, you may provide the `--counts` and `--views` options, respectively. On large databases, retrieving row counts and view details can be slow:

```shell
php artisan db:show --counts --views
```

<a name="table-overview"></a>
#### Table Overview

If you would like to get an overview of an individual table within your database, you may execute the `db:table` Artisan command. This command provides a general overview of a database table, including its columns, types, attributes, keys, and indexes:

```shell
php artisan db:table users
```

<a name="monitoring-your-databases"></a>
## Monitoring Your Databases

Using the `db:monitor` Artisan command, you can instruct Laravel to dispatch an `Illuminate\Database\Events\DatabaseBusy` event if your database is managing more than a specified number of open connections.

To get started, you should schedule the `db:monitor` command to [run every minute](/docs/{{version}}/scheduling). The command accepts the names of the database connection configurations that you wish to monitor as well as the maximum number of open connections that should be tolerated before dispatching an event:

```shell
php artisan db:monitor --databases=mysql,pgsql --max=100
```

Scheduling this command alone is not enough to trigger a notification alerting you of the number of open connections. When the command encounters a database that has an open connection count that exceeds your threshold, a `DatabaseBusy` event will be dispatched. You should listen for this event within your application's `EventServiceProvider` in order to send a notification to you or your development team:

```php
use App\Notifications\DatabaseApproachingMaxConnections;
use Illuminate\Database\Events\DatabaseBusy;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Notification;

/**
 * Register any other events for your application.
 */
public function boot(): void
{
    Event::listen(function (DatabaseBusy $event) {
        Notification::route('mail', 'dev@example.com')
                ->notify(new DatabaseApproachingMaxConnections(
                    $event->connectionName,
                    $event->connections
                ));
    });
}
```



## Eloquent

# Eloquent: Getting Started

- [Introduction](#introduction)
- [Generating Model Classes](#generating-model-classes)
- [Eloquent Model Conventions](#eloquent-model-conventions)
    - [Table Names](#table-names)
    - [Primary Keys](#primary-keys)
    - [UUID and ULID Keys](#uuid-and-ulid-keys)
    - [Timestamps](#timestamps)
    - [Database Connections](#database-connections)
    - [Default Attribute Values](#default-attribute-values)
    - [Configuring Eloquent Strictness](#configuring-eloquent-strictness)
- [Retrieving Models](#retrieving-models)
    - [Collections](#collections)
    - [Chunking Results](#chunking-results)
    - [Chunk Using Lazy Collections](#chunking-using-lazy-collections)
    - [Cursors](#cursors)
    - [Advanced Subqueries](#advanced-subqueries)
- [Retrieving Single Models / Aggregates](#retrieving-single-models)
    - [Retrieving or Creating Models](#retrieving-or-creating-models)
    - [Retrieving Aggregates](#retrieving-aggregates)
- [Inserting and Updating Models](#inserting-and-updating-models)
    - [Inserts](#inserts)
    - [Updates](#updates)
    - [Mass Assignment](#mass-assignment)
    - [Upserts](#upserts)
- [Deleting Models](#deleting-models)
    - [Soft Deleting](#soft-deleting)
    - [Querying Soft Deleted Models](#querying-soft-deleted-models)
- [Pruning Models](#pruning-models)
- [Replicating Models](#replicating-models)
- [Query Scopes](#query-scopes)
    - [Global Scopes](#global-scopes)
    - [Local Scopes](#local-scopes)
- [Comparing Models](#comparing-models)
- [Events](#events)
    - [Using Closures](#events-using-closures)
    - [Observers](#observers)
    - [Muting Events](#muting-events)

<a name="introduction"></a>
## Introduction

Laravel includes Eloquent, an object-relational mapper (ORM) that makes it enjoyable to interact with your database. When using Eloquent, each database table has a corresponding "Model" that is used to interact with that table. In addition to retrieving records from the database table, Eloquent models allow you to insert, update, and delete records from the table as well.

> [!NOTE]  
> Before getting started, be sure to configure a database connection in your application's `config/database.php` configuration file. For more information on configuring your database, check out [the database configuration documentation](/docs/{{version}}/database#configuration).

#### Laravel Bootcamp

If you're new to Laravel, feel free to jump into the [Laravel Bootcamp](https://bootcamp.laravel.com). The Laravel Bootcamp will walk you through building your first Laravel application using Eloquent. It's a great way to get a tour of everything that Laravel and Eloquent have to offer.

<a name="generating-model-classes"></a>
## Generating Model Classes

To get started, let's create an Eloquent model. Models typically live in the `app\Models` directory and extend the `Illuminate\Database\Eloquent\Model` class. You may use the `make:model` [Artisan command](/docs/{{version}}/artisan) to generate a new model:

```shell
php artisan make:model Flight
```

If you would like to generate a [database migration](/docs/{{version}}/migrations) when you generate the model, you may use the `--migration` or `-m` option:

```shell
php artisan make:model Flight --migration
```

You may generate various other types of classes when generating a model, such as factories, seeders, policies, controllers, and form requests. In addition, these options may be combined to create multiple classes at once:

```shell
# Generate a model and a FlightFactory class...
php artisan make:model Flight --factory
php artisan make:model Flight -f

# Generate a model and a FlightSeeder class...
php artisan make:model Flight --seed
php artisan make:model Flight -s

# Generate a model and a FlightController class...
php artisan make:model Flight --controller
php artisan make:model Flight -c

# Generate a model, FlightController resource class, and form request classes...
php artisan make:model Flight --controller --resource --requests
php artisan make:model Flight -crR

# Generate a model and a FlightPolicy class...
php artisan make:model Flight --policy

# Generate a model and a migration, factory, seeder, and controller...
php artisan make:model Flight -mfsc

# Shortcut to generate a model, migration, factory, seeder, policy, controller, and form requests...
php artisan make:model Flight --all

# Generate a pivot model...
php artisan make:model Member --pivot
php artisan make:model Member -p
```

<a name="inspecting-models"></a>
#### Inspecting Models

Sometimes it can be difficult to determine all of a model's available attributes and relationships just by skimming its code. Instead, try the `model:show` Artisan command, which provides a convenient overview of all the model's attributes and relations:

```shell
php artisan model:show Flight
```

<a name="eloquent-model-conventions"></a>
## Eloquent Model Conventions

Models generated by the `make:model` command will be placed in the `app/Models` directory. Let's examine a basic model class and discuss some of Eloquent's key conventions:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        // ...
    }

<a name="table-names"></a>
### Table Names

After glancing at the example above, you may have noticed that we did not tell Eloquent which database table corresponds to our `Flight` model. By convention, the "snake case", plural name of the class will be used as the table name unless another name is explicitly specified. So, in this case, Eloquent will assume the `Flight` model stores records in the `flights` table, while an `AirTrafficController` model would store records in an `air_traffic_controllers` table.

If your model's corresponding database table does not fit this convention, you may manually specify the model's table name by defining a `table` property on the model:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * The table associated with the model.
         *
         * @var string
         */
        protected $table = 'my_flights';
    }

<a name="primary-keys"></a>
### Primary Keys

Eloquent will also assume that each model's corresponding database table has a primary key column named `id`. If necessary, you may define a protected `$primaryKey` property on your model to specify a different column that serves as your model's primary key:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * The primary key associated with the table.
         *
         * @var string
         */
        protected $primaryKey = 'flight_id';
    }

In addition, Eloquent assumes that the primary key is an incrementing integer value, which means that Eloquent will automatically cast the primary key to an integer. If you wish to use a non-incrementing or a non-numeric primary key you must define a public `$incrementing` property on your model that is set to `false`:

    <?php

    class Flight extends Model
    {
        /**
         * Indicates if the model's ID is auto-incrementing.
         *
         * @var bool
         */
        public $incrementing = false;
    }

If your model's primary key is not an integer, you should define a protected `$keyType` property on your model. This property should have a value of `string`:

    <?php

    class Flight extends Model
    {
        /**
         * The data type of the primary key ID.
         *
         * @var string
         */
        protected $keyType = 'string';
    }

<a name="composite-primary-keys"></a>
#### "Composite" Primary Keys

Eloquent requires each model to have at least one uniquely identifying "ID" that can serve as its primary key. "Composite" primary keys are not supported by Eloquent models. However, you are free to add additional multi-column, unique indexes to your database tables in addition to the table's uniquely identifying primary key.

<a name="uuid-and-ulid-keys"></a>
### UUID and ULID Keys

Instead of using auto-incrementing integers as your Eloquent model's primary keys, you may choose to use UUIDs instead. UUIDs are universally unique alpha-numeric identifiers that are 36 characters long.

If you would like a model to use a UUID key instead of an auto-incrementing integer key, you may use the `Illuminate\Database\Eloquent\Concerns\HasUuids` trait on the model. Of course, you should ensure that the model has a [UUID equivalent primary key column](/docs/{{version}}/migrations#column-method-uuid):

    use Illuminate\Database\Eloquent\Concerns\HasUuids;
    use Illuminate\Database\Eloquent\Model;

    class Article extends Model
    {
        use HasUuids;

        // ...
    }

    $article = Article::create(['title' => 'Traveling to Europe']);

    $article->id; // "8f8e8478-9035-4d23-b9a7-62f4d2612ce5"

By default, The `HasUuids` trait will generate ["ordered" UUIDs](/docs/{{version}}/strings#method-str-ordered-uuid) for your models. These UUIDs are more efficient for indexed database storage because they can be sorted lexicographically.

You can override the UUID generation process for a given model by defining a `newUniqueId` method on the model. In addition, you may specify which columns should receive UUIDs by defining a `uniqueIds` method on the model:

    use Ramsey\Uuid\Uuid;

    /**
     * Generate a new UUID for the model.
     */
    public function newUniqueId(): string
    {
        return (string) Uuid::uuid4();
    }

    /**
     * Get the columns that should receive a unique identifier.
     *
     * @return array<int, string>
     */
    public function uniqueIds(): array
    {
        return ['id', 'discount_code'];
    }

If you wish, you may choose to utilize "ULIDs" instead of UUIDs. ULIDs are similar to UUIDs; however, they are only 26 characters in length. Like ordered UUIDs, ULIDs are lexicographically sortable for efficient database indexing. To utilize ULIDs, you should use the `Illuminate\Database\Eloquent\Concerns\HasUlids` trait on your model. You should also ensure that the model has a [ULID equivalent primary key column](/docs/{{version}}/migrations#column-method-ulid):

    use Illuminate\Database\Eloquent\Concerns\HasUlids;
    use Illuminate\Database\Eloquent\Model;

    class Article extends Model
    {
        use HasUlids;

        // ...
    }

    $article = Article::create(['title' => 'Traveling to Asia']);

    $article->id; // "01gd4d3tgrrfqeda94gdbtdk5c"

<a name="timestamps"></a>
### Timestamps

By default, Eloquent expects `created_at` and `updated_at` columns to exist on your model's corresponding database table.  Eloquent will automatically set these column's values when models are created or updated. If you do not want these columns to be automatically managed by Eloquent, you should define a `$timestamps` property on your model with a value of `false`:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * Indicates if the model should be timestamped.
         *
         * @var bool
         */
        public $timestamps = false;
    }

If you need to customize the format of your model's timestamps, set the `$dateFormat` property on your model. This property determines how date attributes are stored in the database as well as their format when the model is serialized to an array or JSON:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * The storage format of the model's date columns.
         *
         * @var string
         */
        protected $dateFormat = 'U';
    }

If you need to customize the names of the columns used to store the timestamps, you may define `CREATED_AT` and `UPDATED_AT` constants on your model:

    <?php

    class Flight extends Model
    {
        const CREATED_AT = 'creation_date';
        const UPDATED_AT = 'updated_date';
    }

If you would like to perform model operations without the model having its `updated_at` timestamp modified, you may operate on the model within a closure given to the `withoutTimestamps` method:

    Model::withoutTimestamps(fn () => $post->increment(['reads']));

<a name="database-connections"></a>
### Database Connections

By default, all Eloquent models will use the default database connection that is configured for your application. If you would like to specify a different connection that should be used when interacting with a particular model, you should define a `$connection` property on the model:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * The database connection that should be used by the model.
         *
         * @var string
         */
        protected $connection = 'sqlite';
    }

<a name="default-attribute-values"></a>
### Default Attribute Values

By default, a newly instantiated model instance will not contain any attribute values. If you would like to define the default values for some of your model's attributes, you may define an `$attributes` property on your model. Attribute values placed in the `$attributes` array should be in their raw, "storable" format as if they were just read from the database:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * The model's default values for attributes.
         *
         * @var array
         */
        protected $attributes = [
            'options' => '[]',
            'delayed' => false,
        ];
    }

<a name="configuring-eloquent-strictness"></a>
### Configuring Eloquent Strictness

Laravel offers several methods that allow you to configure Eloquent's behavior and "strictness" in a variety of situations.

First, the `preventLazyLoading` method accepts an optional boolean argument that indicates if lazy loading should be prevented. For example, you may wish to only disable lazy loading in non-production environments so that your production environment will continue to function normally even if a lazy loaded relationship is accidentally present in production code. Typically, this method should be invoked in the `boot` method of your application's `AppServiceProvider`:

```php
use Illuminate\Database\Eloquent\Model;

/**
 * Bootstrap any application services.
 */
public function boot(): void
{
    Model::preventLazyLoading(! $this->app->isProduction());
}
```

Also, you may instruct Laravel to throw an exception when attempting to fill an unfillable attribute by invoking the `preventSilentlyDiscardingAttributes` method. This can help prevent unexpected errors during local development when attempting to set an attribute that has not been added to the model's `fillable` array:

```php
Model::preventSilentlyDiscardingAttributes(! $this->app->isProduction());
```

<a name="retrieving-models"></a>
## Retrieving Models

Once you have created a model and [its associated database table](/docs/{{version}}/migrations#writing-migrations), you are ready to start retrieving data from your database. You can think of each Eloquent model as a powerful [query builder](/docs/{{version}}/queries) allowing you to fluently query the database table associated with the model. The model's `all` method will retrieve all of the records from the model's associated database table:

    use App\Models\Flight;

    foreach (Flight::all() as $flight) {
        echo $flight->name;
    }

<a name="building-queries"></a>
#### Building Queries

The Eloquent `all` method will return all of the results in the model's table. However, since each Eloquent model serves as a [query builder](/docs/{{version}}/queries), you may add additional constraints to queries and then invoke the `get` method to retrieve the results:

    $flights = Flight::where('active', 1)
                   ->orderBy('name')
                   ->take(10)
                   ->get();

> [!NOTE]  
> Since Eloquent models are query builders, you should review all of the methods provided by Laravel's [query builder](/docs/{{version}}/queries). You may use any of these methods when writing your Eloquent queries.

<a name="refreshing-models"></a>
#### Refreshing Models

If you already have an instance of an Eloquent model that was retrieved from the database, you can "refresh" the model using the `fresh` and `refresh` methods. The `fresh` method will re-retrieve the model from the database. The existing model instance will not be affected:

    $flight = Flight::where('number', 'FR 900')->first();

    $freshFlight = $flight->fresh();

The `refresh` method will re-hydrate the existing model using fresh data from the database. In addition, all of its loaded relationships will be refreshed as well:

    $flight = Flight::where('number', 'FR 900')->first();

    $flight->number = 'FR 456';

    $flight->refresh();

    $flight->number; // "FR 900"

<a name="collections"></a>
### Collections

As we have seen, Eloquent methods like `all` and `get` retrieve multiple records from the database. However, these methods don't return a plain PHP array. Instead, an instance of `Illuminate\Database\Eloquent\Collection` is returned.

The Eloquent `Collection` class extends Laravel's base `Illuminate\Support\Collection` class, which provides a [variety of helpful methods](/docs/{{version}}/collections#available-methods) for interacting with data collections. For example, the `reject` method may be used to remove models from a collection based on the results of an invoked closure:

```php
$flights = Flight::where('destination', 'Paris')->get();

$flights = $flights->reject(function (Flight $flight) {
    return $flight->cancelled;
});
```

In addition to the methods provided by Laravel's base collection class, the Eloquent collection class provides [a few extra methods](/docs/{{version}}/eloquent-collections#available-methods) that are specifically intended for interacting with collections of Eloquent models.

Since all of Laravel's collections implement PHP's iterable interfaces, you may loop over collections as if they were an array:

```php
foreach ($flights as $flight) {
    echo $flight->name;
}
```

<a name="chunking-results"></a>
### Chunking Results

Your application may run out of memory if you attempt to load tens of thousands of Eloquent records via the `all` or `get` methods. Instead of using these methods, the `chunk` method may be used to process large numbers of models more efficiently.

The `chunk` method will retrieve a subset of Eloquent models, passing them to a closure for processing. Since only the current chunk of Eloquent models is retrieved at a time, the `chunk` method will provide significantly reduced memory usage when working with a large number of models:

```php
use App\Models\Flight;
use Illuminate\Database\Eloquent\Collection;

Flight::chunk(200, function (Collection $flights) {
    foreach ($flights as $flight) {
        // ...
    }
});
```

The first argument passed to the `chunk` method is the number of records you wish to receive per "chunk". The closure passed as the second argument will be invoked for each chunk that is retrieved from the database. A database query will be executed to retrieve each chunk of records passed to the closure.

If you are filtering the results of the `chunk` method based on a column that you will also be updating while iterating over the results, you should use the `chunkById` method. Using the `chunk` method in these scenarios could lead to unexpected and inconsistent results. Internally, the `chunkById` method will always retrieve models with an `id` column greater than the last model in the previous chunk:

```php
Flight::where('departed', true)
    ->chunkById(200, function (Collection $flights) {
        $flights->each->update(['departed' => false]);
    }, $column = 'id');
```

<a name="chunking-using-lazy-collections"></a>
### Chunking Using Lazy Collections

The `lazy` method works similarly to [the `chunk` method](#chunking-results) in the sense that, behind the scenes, it executes the query in chunks. However, instead of passing each chunk directly into a callback as is, the `lazy` method returns a flattened [`LazyCollection`](/docs/{{version}}/collections#lazy-collections) of Eloquent models, which lets you interact with the results as a single stream:

```php
use App\Models\Flight;

foreach (Flight::lazy() as $flight) {
    // ...
}
```

If you are filtering the results of the `lazy` method based on a column that you will also be updating while iterating over the results, you should use the `lazyById` method. Internally, the `lazyById` method will always retrieve models with an `id` column greater than the last model in the previous chunk:

```php
Flight::where('departed', true)
    ->lazyById(200, $column = 'id')
    ->each->update(['departed' => false]);
```

You may filter the results based on the descending order of the `id` using the `lazyByIdDesc` method.

<a name="cursors"></a>
### Cursors

Similar to the `lazy` method, the `cursor` method may be used to significantly reduce your application's memory consumption when iterating through tens of thousands of Eloquent model records.

The `cursor` method will only execute a single database query; however, the individual Eloquent models will not be hydrated until they are actually iterated over. Therefore, only one Eloquent model is kept in memory at any given time while iterating over the cursor.

> [!WARNING]  
> Since the `cursor` method only ever holds a single Eloquent model in memory at a time, it cannot eager load relationships. If you need to eager load relationships, consider using [the `lazy` method](#chunking-using-lazy-collections) instead.

Internally, the `cursor` method uses PHP [generators](https://www.php.net/manual/en/language.generators.overview.php) to implement this functionality:

```php
use App\Models\Flight;

foreach (Flight::where('destination', 'Zurich')->cursor() as $flight) {
    // ...
}
```

The `cursor` returns an `Illuminate\Support\LazyCollection` instance. [Lazy collections](/docs/{{version}}/collections#lazy-collections) allow you to use many of the collection methods available on typical Laravel collections while only loading a single model into memory at a time:

```php
use App\Models\User;

$users = User::cursor()->filter(function (User $user) {
    return $user->id > 500;
});

foreach ($users as $user) {
    echo $user->id;
}
```

Although the `cursor` method uses far less memory than a regular query (by only holding a single Eloquent model in memory at a time), it will still eventually run out of memory. This is [due to PHP's PDO driver internally caching all raw query results in its buffer](https://www.php.net/manual/en/mysqlinfo.concepts.buffering.php). If you're dealing with a very large number of Eloquent records, consider using [the `lazy` method](#chunking-using-lazy-collections) instead.

<a name="advanced-subqueries"></a>
### Advanced Subqueries

<a name="subquery-selects"></a>
#### Subquery Selects

Eloquent also offers advanced subquery support, which allows you to pull information from related tables in a single query. For example, let's imagine that we have a table of flight `destinations` and a table of `flights` to destinations. The `flights` table contains an `arrived_at` column which indicates when the flight arrived at the destination.

Using the subquery functionality available to the query builder's `select` and `addSelect` methods, we can select all of the `destinations` and the name of the flight that most recently arrived at that destination using a single query:

    use App\Models\Destination;
    use App\Models\Flight;

    return Destination::addSelect(['last_flight' => Flight::select('name')
        ->whereColumn('destination_id', 'destinations.id')
        ->orderByDesc('arrived_at')
        ->limit(1)
    ])->get();

<a name="subquery-ordering"></a>
#### Subquery Ordering

In addition, the query builder's `orderBy` function supports subqueries. Continuing to use our flight example, we may use this functionality to sort all destinations based on when the last flight arrived at that destination. Again, this may be done while executing a single database query:

    return Destination::orderByDesc(
        Flight::select('arrived_at')
            ->whereColumn('destination_id', 'destinations.id')
            ->orderByDesc('arrived_at')
            ->limit(1)
    )->get();

<a name="retrieving-single-models"></a>
## Retrieving Single Models / Aggregates

In addition to retrieving all of the records matching a given query, you may also retrieve single records using the `find`, `first`, or `firstWhere` methods. Instead of returning a collection of models, these methods return a single model instance:

    use App\Models\Flight;

    // Retrieve a model by its primary key...
    $flight = Flight::find(1);

    // Retrieve the first model matching the query constraints...
    $flight = Flight::where('active', 1)->first();

    // Alternative to retrieving the first model matching the query constraints...
    $flight = Flight::firstWhere('active', 1);

Sometimes you may wish to perform some other action if no results are found. The `findOr` and `firstOr` methods will return a single model instance or, if no results are found, execute the given closure. The value returned by the closure will be considered the result of the method:

    $flight = Flight::findOr(1, function () {
        // ...
    });

    $flight = Flight::where('legs', '>', 3)->firstOr(function () {
        // ...
    });

<a name="not-found-exceptions"></a>
#### Not Found Exceptions

Sometimes you may wish to throw an exception if a model is not found. This is particularly useful in routes or controllers. The `findOrFail` and `firstOrFail` methods will retrieve the first result of the query; however, if no result is found, an `Illuminate\Database\Eloquent\ModelNotFoundException` will be thrown:

    $flight = Flight::findOrFail(1);

    $flight = Flight::where('legs', '>', 3)->firstOrFail();

If the `ModelNotFoundException` is not caught, a 404 HTTP response is automatically sent back to the client:

    use App\Models\Flight;

    Route::get('/api/flights/{id}', function (string $id) {
        return Flight::findOrFail($id);
    });

<a name="retrieving-or-creating-models"></a>
### Retrieving or Creating Models

The `firstOrCreate` method will attempt to locate a database record using the given column / value pairs. If the model can not be found in the database, a record will be inserted with the attributes resulting from merging the first array argument with the optional second array argument:

The `firstOrNew` method, like `firstOrCreate`, will attempt to locate a record in the database matching the given attributes. However, if a model is not found, a new model instance will be returned. Note that the model returned by `firstOrNew` has not yet been persisted to the database. You will need to manually call the `save` method to persist it:

    use App\Models\Flight;

    // Retrieve flight by name or create it if it doesn't exist...
    $flight = Flight::firstOrCreate([
        'name' => 'London to Paris'
    ]);

    // Retrieve flight by name or create it with the name, delayed, and arrival_time attributes...
    $flight = Flight::firstOrCreate(
        ['name' => 'London to Paris'],
        ['delayed' => 1, 'arrival_time' => '11:30']
    );

    // Retrieve flight by name or instantiate a new Flight instance...
    $flight = Flight::firstOrNew([
        'name' => 'London to Paris'
    ]);

    // Retrieve flight by name or instantiate with the name, delayed, and arrival_time attributes...
    $flight = Flight::firstOrNew(
        ['name' => 'Tokyo to Sydney'],
        ['delayed' => 1, 'arrival_time' => '11:30']
    );

<a name="retrieving-aggregates"></a>
### Retrieving Aggregates

When interacting with Eloquent models, you may also use the `count`, `sum`, `max`, and other [aggregate methods](/docs/{{version}}/queries#aggregates) provided by the Laravel [query builder](/docs/{{version}}/queries). As you might expect, these methods return a scalar value instead of an Eloquent model instance:

    $count = Flight::where('active', 1)->count();

    $max = Flight::where('active', 1)->max('price');

<a name="inserting-and-updating-models"></a>
## Inserting and Updating Models

<a name="inserts"></a>
### Inserts

Of course, when using Eloquent, we don't only need to retrieve models from the database. We also need to insert new records. Thankfully, Eloquent makes it simple. To insert a new record into the database, you should instantiate a new model instance and set attributes on the model. Then, call the `save` method on the model instance:

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Flight;
    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;

    class FlightController extends Controller
    {
        /**
         * Store a new flight in the database.
         */
        public function store(Request $request): RedirectResponse
        {
            // Validate the request...

            $flight = new Flight;

            $flight->name = $request->name;

            $flight->save();

            return redirect('/flights');
        }
    }

In this example, we assign the `name` field from the incoming HTTP request to the `name` attribute of the `App\Models\Flight` model instance. When we call the `save` method, a record will be inserted into the database. The model's `created_at` and `updated_at` timestamps will automatically be set when the `save` method is called, so there is no need to set them manually.

Alternatively, you may use the `create` method to "save" a new model using a single PHP statement. The inserted model instance will be returned to you by the `create` method:

    use App\Models\Flight;

    $flight = Flight::create([
        'name' => 'London to Paris',
    ]);

However, before using the `create` method, you will need to specify either a `fillable` or `guarded` property on your model class. These properties are required because all Eloquent models are protected against mass assignment vulnerabilities by default. To learn more about mass assignment, please consult the [mass assignment documentation](#mass-assignment).

<a name="updates"></a>
### Updates

The `save` method may also be used to update models that already exist in the database. To update a model, you should retrieve it and set any attributes you wish to update. Then, you should call the model's `save` method. Again, the `updated_at` timestamp will automatically be updated, so there is no need to manually set its value:

    use App\Models\Flight;

    $flight = Flight::find(1);

    $flight->name = 'Paris to London';

    $flight->save();

<a name="mass-updates"></a>
#### Mass Updates

Updates can also be performed against models that match a given query. In this example, all flights that are `active` and have a `destination` of `San Diego` will be marked as delayed:

    Flight::where('active', 1)
          ->where('destination', 'San Diego')
          ->update(['delayed' => 1]);

The `update` method expects an array of column and value pairs representing the columns that should be updated. The `update` method returns the number of affected rows.

> [!WARNING]  
> When issuing a mass update via Eloquent, the `saving`, `saved`, `updating`, and `updated` model events will not be fired for the updated models. This is because the models are never actually retrieved when issuing a mass update.

<a name="examining-attribute-changes"></a>
#### Examining Attribute Changes

Eloquent provides the `isDirty`, `isClean`, and `wasChanged` methods to examine the internal state of your model and determine how its attributes have changed from when the model was originally retrieved.

The `isDirty` method determines if any of the model's attributes have been changed since the model was retrieved. You may pass a specific attribute name or an array of attributes to the `isDirty` method to determine if any of the attributes are "dirty". The `isClean` method will determine if an attribute has remained unchanged since the model was retrieved. This method also accepts an optional attribute argument:

    use App\Models\User;

    $user = User::create([
        'first_name' => 'Taylor',
        'last_name' => 'Otwell',
        'title' => 'Developer',
    ]);

    $user->title = 'Painter';

    $user->isDirty(); // true
    $user->isDirty('title'); // true
    $user->isDirty('first_name'); // false
    $user->isDirty(['first_name', 'title']); // true

    $user->isClean(); // false
    $user->isClean('title'); // false
    $user->isClean('first_name'); // true
    $user->isClean(['first_name', 'title']); // false

    $user->save();

    $user->isDirty(); // false
    $user->isClean(); // true

The `wasChanged` method determines if any attributes were changed when the model was last saved within the current request cycle. If needed, you may pass an attribute name to see if a particular attribute was changed:

    $user = User::create([
        'first_name' => 'Taylor',
        'last_name' => 'Otwell',
        'title' => 'Developer',
    ]);

    $user->title = 'Painter';

    $user->save();

    $user->wasChanged(); // true
    $user->wasChanged('title'); // true
    $user->wasChanged(['title', 'slug']); // true
    $user->wasChanged('first_name'); // false
    $user->wasChanged(['first_name', 'title']); // true

The `getOriginal` method returns an array containing the original attributes of the model regardless of any changes to the model since it was retrieved. If needed, you may pass a specific attribute name to get the original value of a particular attribute:

    $user = User::find(1);

    $user->name; // John
    $user->email; // john@example.com

    $user->name = "Jack";
    $user->name; // Jack

    $user->getOriginal('name'); // John
    $user->getOriginal(); // Array of original attributes...

<a name="mass-assignment"></a>
### Mass Assignment

You may use the `create` method to "save" a new model using a single PHP statement. The inserted model instance will be returned to you by the method:

    use App\Models\Flight;

    $flight = Flight::create([
        'name' => 'London to Paris',
    ]);

However, before using the `create` method, you will need to specify either a `fillable` or `guarded` property on your model class. These properties are required because all Eloquent models are protected against mass assignment vulnerabilities by default.

A mass assignment vulnerability occurs when a user passes an unexpected HTTP request field and that field changes a column in your database that you did not expect. For example, a malicious user might send an `is_admin` parameter through an HTTP request, which is then passed to your model's `create` method, allowing the user to escalate themselves to an administrator.

So, to get started, you should define which model attributes you want to make mass assignable. You may do this using the `$fillable` property on the model. For example, let's make the `name` attribute of our `Flight` model mass assignable:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * The attributes that are mass assignable.
         *
         * @var array
         */
        protected $fillable = ['name'];
    }

Once you have specified which attributes are mass assignable, you may use the `create` method to insert a new record in the database. The `create` method returns the newly created model instance:

    $flight = Flight::create(['name' => 'London to Paris']);

If you already have a model instance, you may use the `fill` method to populate it with an array of attributes:

    $flight->fill(['name' => 'Amsterdam to Frankfurt']);

<a name="mass-assignment-json-columns"></a>
#### Mass Assignment and JSON Columns

When assigning JSON columns, each column's mass assignable key must be specified in your model's `$fillable` array. For security, Laravel does not support updating nested JSON attributes when using the `guarded` property:

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'options->enabled',
    ];

<a name="allowing-mass-assignment"></a>
#### Allowing Mass Assignment

If you would like to make all of your attributes mass assignable, you may define your model's `$guarded` property as an empty array. If you choose to unguard your model, you should take special care to always hand-craft the arrays passed to Eloquent's `fill`, `create`, and `update` methods:

    /**
     * The attributes that aren't mass assignable.
     *
     * @var array
     */
    protected $guarded = [];

<a name="mass-assignment-exceptions"></a>
#### Mass Assignment Exceptions

By default, attributes that are not included in the `$fillable` array are silently discarded when performing mass-assignment operations. In production, this is expected behavior; however, during local development it can lead to confusion as to why model changes are not taking effect.

If you wish, you may instruct Laravel to throw an exception when attempting to fill an unfillable attribute by invoking the `preventSilentlyDiscardingAttributes` method. Typically, this method should be invoked within the `boot` method of one of your application's service providers:

    use Illuminate\Database\Eloquent\Model;

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Model::preventSilentlyDiscardingAttributes($this->app->isLocal());
    }

<a name="upserts"></a>
### Upserts

Occasionally, you may need to update an existing model or create a new model if no matching model exists. Like the `firstOrCreate` method, the `updateOrCreate` method persists the model, so there's no need to manually call the `save` method.

In the example below, if a flight exists with a `departure` location of `Oakland` and a `destination` location of `San Diego`, its `price` and `discounted` columns will be updated. If no such flight exists, a new flight will be created which has the attributes resulting from merging the first argument array with the second argument array:

    $flight = Flight::updateOrCreate(
        ['departure' => 'Oakland', 'destination' => 'San Diego'],
        ['price' => 99, 'discounted' => 1]
    );

If you would like to perform multiple "upserts" in a single query, then you should use the `upsert` method instead. The method's first argument consists of the values to insert or update, while the second argument lists the column(s) that uniquely identify records within the associated table. The method's third and final argument is an array of the columns that should be updated if a matching record already exists in the database. The `upsert` method will automatically set the `created_at` and `updated_at` timestamps if timestamps are enabled on the model:

    Flight::upsert([
        ['departure' => 'Oakland', 'destination' => 'San Diego', 'price' => 99],
        ['departure' => 'Chicago', 'destination' => 'New York', 'price' => 150]
    ], ['departure', 'destination'], ['price']);
    
> [!WARNING]  
> All databases except SQL Server require the columns in the second argument of the `upsert` method to have a "primary" or "unique" index. In addition, the MySQL database driver ignores the second argument of the `upsert` method and always uses the "primary" and "unique" indexes of the table to detect existing records.

<a name="deleting-models"></a>
## Deleting Models

To delete a model, you may call the `delete` method on the model instance:

    use App\Models\Flight;

    $flight = Flight::find(1);

    $flight->delete();

You may call the `truncate` method to delete all of the model's associated database records. The `truncate` operation will also reset any auto-incrementing IDs on the model's associated table:

    Flight::truncate();

<a name="deleting-an-existing-model-by-its-primary-key"></a>
#### Deleting an Existing Model by its Primary Key

In the example above, we are retrieving the model from the database before calling the `delete` method. However, if you know the primary key of the model, you may delete the model without explicitly retrieving it by calling the `destroy` method.  In addition to accepting the single primary key, the `destroy` method will accept multiple primary keys, an array of primary keys, or a [collection](/docs/{{version}}/collections) of primary keys:

    Flight::destroy(1);

    Flight::destroy(1, 2, 3);

    Flight::destroy([1, 2, 3]);

    Flight::destroy(collect([1, 2, 3]));

> [!WARNING]  
> The `destroy` method loads each model individually and calls the `delete` method so that the `deleting` and `deleted` events are properly dispatched for each model.

<a name="deleting-models-using-queries"></a>
#### Deleting Models Using Queries

Of course, you may build an Eloquent query to delete all models matching your query's criteria. In this example, we will delete all flights that are marked as inactive. Like mass updates, mass deletes will not dispatch model events for the models that are deleted:

    $deleted = Flight::where('active', 0)->delete();

> [!WARNING]  
> When executing a mass delete statement via Eloquent, the `deleting` and `deleted` model events will not be dispatched for the deleted models. This is because the models are never actually retrieved when executing the delete statement.

<a name="soft-deleting"></a>
### Soft Deleting

In addition to actually removing records from your database, Eloquent can also "soft delete" models. When models are soft deleted, they are not actually removed from your database. Instead, a `deleted_at` attribute is set on the model indicating the date and time at which the model was "deleted". To enable soft deletes for a model, add the `Illuminate\Database\Eloquent\SoftDeletes` trait to the model:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;
    use Illuminate\Database\Eloquent\SoftDeletes;

    class Flight extends Model
    {
        use SoftDeletes;
    }

> [!NOTE]  
> The `SoftDeletes` trait will automatically cast the `deleted_at` attribute to a `DateTime` / `Carbon` instance for you.

You should also add the `deleted_at` column to your database table. The Laravel [schema builder](/docs/{{version}}/migrations) contains a helper method to create this column:

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('flights', function (Blueprint $table) {
        $table->softDeletes();
    });

    Schema::table('flights', function (Blueprint $table) {
        $table->dropSoftDeletes();
    });

Now, when you call the `delete` method on the model, the `deleted_at` column will be set to the current date and time. However, the model's database record will be left in the table. When querying a model that uses soft deletes, the soft deleted models will automatically be excluded from all query results.

To determine if a given model instance has been soft deleted, you may use the `trashed` method:

    if ($flight->trashed()) {
        // ...
    }

<a name="restoring-soft-deleted-models"></a>
#### Restoring Soft Deleted Models

Sometimes you may wish to "un-delete" a soft deleted model. To restore a soft deleted model, you may call the `restore` method on a model instance. The `restore` method will set the model's `deleted_at` column to `null`:

    $flight->restore();

You may also use the `restore` method in a query to restore multiple models. Again, like other "mass" operations, this will not dispatch any model events for the models that are restored:

    Flight::withTrashed()
            ->where('airline_id', 1)
            ->restore();

The `restore` method may also be used when building [relationship](/docs/{{version}}/eloquent-relationships) queries:

    $flight->history()->restore();

<a name="permanently-deleting-models"></a>
#### Permanently Deleting Models

Sometimes you may need to truly remove a model from your database. You may use the `forceDelete` method to permanently remove a soft deleted model from the database table:

    $flight->forceDelete();

You may also use the `forceDelete` method when building Eloquent relationship queries:

    $flight->history()->forceDelete();

<a name="querying-soft-deleted-models"></a>
### Querying Soft Deleted Models

<a name="including-soft-deleted-models"></a>
#### Including Soft Deleted Models

As noted above, soft deleted models will automatically be excluded from query results. However, you may force soft deleted models to be included in a query's results by calling the `withTrashed` method on the query:

    use App\Models\Flight;

    $flights = Flight::withTrashed()
                    ->where('account_id', 1)
                    ->get();

The `withTrashed` method may also be called when building a [relationship](/docs/{{version}}/eloquent-relationships) query:

    $flight->history()->withTrashed()->get();

<a name="retrieving-only-soft-deleted-models"></a>
#### Retrieving Only Soft Deleted Models

The `onlyTrashed` method will retrieve **only** soft deleted models:

    $flights = Flight::onlyTrashed()
                    ->where('airline_id', 1)
                    ->get();

<a name="pruning-models"></a>
## Pruning Models

Sometimes you may want to periodically delete models that are no longer needed. To accomplish this, you may add the `Illuminate\Database\Eloquent\Prunable` or `Illuminate\Database\Eloquent\MassPrunable` trait to the models you would like to periodically prune. After adding one of the traits to the model, implement a `prunable` method which returns an Eloquent query builder that resolves the models that are no longer needed:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;
    use Illuminate\Database\Eloquent\Prunable;

    class Flight extends Model
    {
        use Prunable;

        /**
         * Get the prunable model query.
         */
        public function prunable(): Builder
        {
            return static::where('created_at', '<=', now()->subMonth());
        }
    }

When marking models as `Prunable`, you may also define a `pruning` method on the model. This method will be called before the model is deleted. This method can be useful for deleting any additional resources associated with the model, such as stored files, before the model is permanently removed from the database:

    /**
     * Prepare the model for pruning.
     */
    protected function pruning(): void
    {
        // ...
    }

After configuring your prunable model, you should schedule the `model:prune` Artisan command in your application's `App\Console\Kernel` class. You are free to choose the appropriate interval at which this command should be run:

    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        $schedule->command('model:prune')->daily();
    }

Behind the scenes, the `model:prune` command will automatically detect "Prunable" models within your application's `app/Models` directory. If your models are in a different location, you may use the `--model` option to specify the model class names:

    $schedule->command('model:prune', [
        '--model' => [Address::class, Flight::class],
    ])->daily();

If you wish to exclude certain models from being pruned while pruning all other detected models, you may use the `--except` option:

    $schedule->command('model:prune', [
        '--except' => [Address::class, Flight::class],
    ])->daily();

You may test your `prunable` query by executing the `model:prune` command with the `--pretend` option. When pretending, the `model:prune` command will simply report how many records would be pruned if the command were to actually run:

```shell
php artisan model:prune --pretend
```

> [!WARNING]  
> Soft deleting models will be permanently deleted (`forceDelete`) if they match the prunable query.

<a name="mass-pruning"></a>
#### Mass Pruning

When models are marked with the `Illuminate\Database\Eloquent\MassPrunable` trait, models are deleted from the database using mass-deletion queries. Therefore, the `pruning` method will not be invoked, nor will the `deleting` and `deleted` model events be dispatched. This is because the models are never actually retrieved before deletion, thus making the pruning process much more efficient:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;
    use Illuminate\Database\Eloquent\MassPrunable;

    class Flight extends Model
    {
        use MassPrunable;

        /**
         * Get the prunable model query.
         */
        public function prunable(): Builder
        {
            return static::where('created_at', '<=', now()->subMonth());
        }
    }

<a name="replicating-models"></a>
## Replicating Models

You may create an unsaved copy of an existing model instance using the `replicate` method. This method is particularly useful when you have model instances that share many of the same attributes:

    use App\Models\Address;

    $shipping = Address::create([
        'type' => 'shipping',
        'line_1' => '123 Example Street',
        'city' => 'Victorville',
        'state' => 'CA',
        'postcode' => '90001',
    ]);

    $billing = $shipping->replicate()->fill([
        'type' => 'billing'
    ]);

    $billing->save();

To exclude one or more attributes from being replicated to the new model, you may pass an array to the `replicate` method:

    $flight = Flight::create([
        'destination' => 'LAX',
        'origin' => 'LHR',
        'last_flown' => '2020-03-04 11:00:00',
        'last_pilot_id' => 747,
    ]);

    $flight = $flight->replicate([
        'last_flown',
        'last_pilot_id'
    ]);

<a name="query-scopes"></a>
## Query Scopes

<a name="global-scopes"></a>
### Global Scopes

Global scopes allow you to add constraints to all queries for a given model. Laravel's own [soft delete](#soft-deleting) functionality utilizes global scopes to only retrieve "non-deleted" models from the database. Writing your own global scopes can provide a convenient, easy way to make sure every query for a given model receives certain constraints.

<a name="generating-scopes"></a>
#### Generating Scopes

To generate a new global scope, you may invoke the `make:scope` Artisan command, which will place the generated scope in your application's `app/Models/Scopes` directory:

```shell
php artisan make:scope AncientScope
```

<a name="writing-global-scopes"></a>
#### Writing Global Scopes

Writing a global scope is simple. First, use the `make:scope` command to generate a class that implements the `Illuminate\Database\Eloquent\Scope` interface. The `Scope` interface requires you to implement one method: `apply`. The `apply` method may add `where` constraints or other types of clauses to the query as needed:

    <?php

    namespace App\Models\Scopes;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;
    use Illuminate\Database\Eloquent\Scope;

    class AncientScope implements Scope
    {
        /**
         * Apply the scope to a given Eloquent query builder.
         */
        public function apply(Builder $builder, Model $model): void
        {
            $builder->where('created_at', '<', now()->subYears(2000));
        }
    }

> [!NOTE]  
> If your global scope is adding columns to the select clause of the query, you should use the `addSelect` method instead of `select`. This will prevent the unintentional replacement of the query's existing select clause.

<a name="applying-global-scopes"></a>
#### Applying Global Scopes

To assign a global scope to a model, you may simply place the `ScopedBy` attribute on the model:

    <?php

    namespace App\Models;

    use App\Models\Scopes\AncientScope;
    use Illuminate\Database\Eloquent\Attributes\ScopedBy;

    #[ScopedBy([AncientScope::class])]
    class User extends Model
    {
        //
    }

Or, you may manually register the global scope by overriding the model's `booted` method and invoke the model's `addGlobalScope` method. The `addGlobalScope` method accepts an instance of your scope as its only argument:

    <?php

    namespace App\Models;

    use App\Models\Scopes\AncientScope;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * The "booted" method of the model.
         */
        protected static function booted(): void
        {
            static::addGlobalScope(new AncientScope);
        }
    }

After adding the scope in the example above to the `App\Models\User` model, a call to the `User::all()` method will execute the following SQL query:

```sql
select * from `users` where `created_at` < 0021-02-18 00:00:00
```

<a name="anonymous-global-scopes"></a>
#### Anonymous Global Scopes

Eloquent also allows you to define global scopes using closures, which is particularly useful for simple scopes that do not warrant a separate class of their own. When defining a global scope using a closure, you should provide a scope name of your own choosing as the first argument to the `addGlobalScope` method:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * The "booted" method of the model.
         */
        protected static function booted(): void
        {
            static::addGlobalScope('ancient', function (Builder $builder) {
                $builder->where('created_at', '<', now()->subYears(2000));
            });
        }
    }

<a name="removing-global-scopes"></a>
#### Removing Global Scopes

If you would like to remove a global scope for a given query, you may use the `withoutGlobalScope` method. This method accepts the class name of the global scope as its only argument:

    User::withoutGlobalScope(AncientScope::class)->get();

Or, if you defined the global scope using a closure, you should pass the string name that you assigned to the global scope:

    User::withoutGlobalScope('ancient')->get();

If you would like to remove several or even all of the query's global scopes, you may use the `withoutGlobalScopes` method:

    // Remove all of the global scopes...
    User::withoutGlobalScopes()->get();

    // Remove some of the global scopes...
    User::withoutGlobalScopes([
        FirstScope::class, SecondScope::class
    ])->get();

<a name="local-scopes"></a>
### Local Scopes

Local scopes allow you to define common sets of query constraints that you may easily re-use throughout your application. For example, you may need to frequently retrieve all users that are considered "popular". To define a scope, prefix an Eloquent model method with `scope`.

Scopes should always return the same query builder instance or `void`:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * Scope a query to only include popular users.
         */
        public function scopePopular(Builder $query): void
        {
            $query->where('votes', '>', 100);
        }

        /**
         * Scope a query to only include active users.
         */
        public function scopeActive(Builder $query): void
        {
            $query->where('active', 1);
        }
    }

<a name="utilizing-a-local-scope"></a>
#### Utilizing a Local Scope

Once the scope has been defined, you may call the scope methods when querying the model. However, you should not include the `scope` prefix when calling the method. You can even chain calls to various scopes:

    use App\Models\User;

    $users = User::popular()->active()->orderBy('created_at')->get();

Combining multiple Eloquent model scopes via an `or` query operator may require the use of closures to achieve the correct [logical grouping](/docs/{{version}}/queries#logical-grouping):

    $users = User::popular()->orWhere(function (Builder $query) {
        $query->active();
    })->get();

However, since this can be cumbersome, Laravel provides a "higher order" `orWhere` method that allows you to fluently chain scopes together without the use of closures:

    $users = User::popular()->orWhere->active()->get();

<a name="dynamic-scopes"></a>
#### Dynamic Scopes

Sometimes you may wish to define a scope that accepts parameters. To get started, just add your additional parameters to your scope method's signature. Scope parameters should be defined after the `$query` parameter:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * Scope a query to only include users of a given type.
         */
        public function scopeOfType(Builder $query, string $type): void
        {
            $query->where('type', $type);
        }
    }

Once the expected arguments have been added to your scope method's signature, you may pass the arguments when calling the scope:

    $users = User::ofType('admin')->get();

<a name="comparing-models"></a>
## Comparing Models

Sometimes you may need to determine if two models are the "same" or not. The `is` and `isNot` methods may be used to quickly verify two models have the same primary key, table, and database connection or not:

    if ($post->is($anotherPost)) {
        // ...
    }

    if ($post->isNot($anotherPost)) {
        // ...
    }

The `is` and `isNot` methods are also available when using the `belongsTo`, `hasOne`, `morphTo`, and `morphOne` [relationships](/docs/{{version}}/eloquent-relationships). This method is particularly helpful when you would like to compare a related model without issuing a query to retrieve that model:

    if ($post->author()->is($user)) {
        // ...
    }

<a name="events"></a>
## Events

> [!NOTE]  
> Want to broadcast your Eloquent events directly to your client-side application? Check out Laravel's [model event broadcasting](/docs/{{version}}/broadcasting#model-broadcasting).

Eloquent models dispatch several events, allowing you to hook into the following moments in a model's lifecycle: `retrieved`, `creating`, `created`, `updating`, `updated`, `saving`, `saved`, `deleting`, `deleted`, `trashed`, `forceDeleting`, `forceDeleted`, `restoring`, `restored`, and `replicating`.

The `retrieved` event will dispatch when an existing model is retrieved from the database. When a new model is saved for the first time, the `creating` and `created` events will dispatch. The `updating` / `updated` events will dispatch when an existing model is modified and the `save` method is called. The `saving` / `saved` events will dispatch when a model is created or updated - even if the model's attributes have not been changed. Event names ending with `-ing` are dispatched before any changes to the model are persisted, while events ending with `-ed` are dispatched after the changes to the model are persisted.

To start listening to model events, define a `$dispatchesEvents` property on your Eloquent model. This property maps various points of the Eloquent model's lifecycle to your own [event classes](/docs/{{version}}/events). Each model event class should expect to receive an instance of the affected model via its constructor:

    <?php

    namespace App\Models;

    use App\Events\UserDeleted;
    use App\Events\UserSaved;
    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;

    class User extends Authenticatable
    {
        use Notifiable;

        /**
         * The event map for the model.
         *
         * @var array
         */
        protected $dispatchesEvents = [
            'saved' => UserSaved::class,
            'deleted' => UserDeleted::class,
        ];
    }

After defining and mapping your Eloquent events, you may use [event listeners](/docs/{{version}}/events#defining-listeners) to handle the events.

> [!WARNING]  
> When issuing a mass update or delete query via Eloquent, the `saved`, `updated`, `deleting`, and `deleted` model events will not be dispatched for the affected models. This is because the models are never actually retrieved when performing mass updates or deletes.

<a name="events-using-closures"></a>
### Using Closures

Instead of using custom event classes, you may register closures that execute when various model events are dispatched. Typically, you should register these closures in the `booted` method of your model:

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * The "booted" method of the model.
         */
        protected static function booted(): void
        {
            static::created(function (User $user) {
                // ...
            });
        }
    }

If needed, you may utilize [queueable anonymous event listeners](/docs/{{version}}/events#queuable-anonymous-event-listeners) when registering model events. This will instruct Laravel to execute the model event listener in the background using your application's [queue](/docs/{{version}}/queues):

    use function Illuminate\Events\queueable;

    static::created(queueable(function (User $user) {
        // ...
    }));

<a name="observers"></a>
### Observers

<a name="defining-observers"></a>
#### Defining Observers

If you are listening for many events on a given model, you may use observers to group all of your listeners into a single class. Observer classes have method names which reflect the Eloquent events you wish to listen for. Each of these methods receives the affected model as their only argument. The `make:observer` Artisan command is the easiest way to create a new observer class:

```shell
php artisan make:observer UserObserver --model=User
```

This command will place the new observer in your `app/Observers` directory. If this directory does not exist, Artisan will create it for you. Your fresh observer will look like the following:

    <?php

    namespace App\Observers;

    use App\Models\User;

    class UserObserver
    {
        /**
         * Handle the User "created" event.
         */
        public function created(User $user): void
        {
            // ...
        }

        /**
         * Handle the User "updated" event.
         */
        public function updated(User $user): void
        {
            // ...
        }

        /**
         * Handle the User "deleted" event.
         */
        public function deleted(User $user): void
        {
            // ...
        }
        
        /**
         * Handle the User "restored" event.
         */
        public function restored(User $user): void
        {
            // ...
        }

        /**
         * Handle the User "forceDeleted" event.
         */
        public function forceDeleted(User $user): void
        {
            // ...
        }
    }

To register an observer, you may place the `ObservedBy` attribute on the corresponding model:

    use App\Observers\UserObserver;
    use Illuminate\Database\Eloquent\Attributes\ObservedBy;

    #[ObservedBy([UserObserver::class])]
    class User extends Authenticatable
    {
        //
    }

Or, you may manually register an observer by calling the `observe` method on the model you wish to observe. You may register observers in the `boot` method of your application's `App\Providers\EventServiceProvider` service provider:

    use App\Models\User;
    use App\Observers\UserObserver;

    /**
     * Register any events for your application.
     */
    public function boot(): void
    {
        User::observe(UserObserver::class);
    }

> [!NOTE]  
> There are additional events an observer can listen to, such as `saving` and `retrieved`. These events are described within the [events](#events) documentation.

<a name="observers-and-database-transactions"></a>
#### Observers and Database Transactions

When models are being created within a database transaction, you may want to instruct an observer to only execute its event handlers after the database transaction is committed. You may accomplish this by implementing the `ShouldHandleEventsAfterCommit` interface on your observer. If a database transaction is not in progress, the event handlers will execute immediately:

    <?php

    namespace App\Observers;

    use App\Models\User;
    use Illuminate\Contracts\Events\ShouldHandleEventsAfterCommit;

    class UserObserver implements ShouldHandleEventsAfterCommit
    {
        /**
         * Handle the User "created" event.
         */
        public function created(User $user): void
        {
            // ...
        }
    }

<a name="muting-events"></a>
### Muting Events

You may occasionally need to temporarily "mute" all events fired by a model. You may achieve this using the `withoutEvents` method. The `withoutEvents` method accepts a closure as its only argument. Any code executed within this closure will not dispatch model events, and any value returned by the closure will be returned by the `withoutEvents` method:

    use App\Models\User;

    $user = User::withoutEvents(function () {
        User::findOrFail(1)->delete();

        return User::find(2);
    });

<a name="saving-a-single-model-without-events"></a>
#### Saving a Single Model Without Events

Sometimes you may wish to "save" a given model without dispatching any events. You may accomplish this using the `saveQuietly` method:

    $user = User::findOrFail(1);

    $user->name = 'Victoria Faith';

    $user->saveQuietly();

You may also "update", "delete", "soft delete", "restore", and "replicate" a given model without dispatching any events:

    $user->deleteQuietly();
    $user->forceDeleteQuietly();
    $user->restoreQuietly();



## Migrations

# Database: Migrations

- [Introduction](#introduction)
- [Generating Migrations](#generating-migrations)
    - [Squashing Migrations](#squashing-migrations)
- [Migration Structure](#migration-structure)
- [Running Migrations](#running-migrations)
    - [Rolling Back Migrations](#rolling-back-migrations)
- [Tables](#tables)
    - [Creating Tables](#creating-tables)
    - [Updating Tables](#updating-tables)
    - [Renaming / Dropping Tables](#renaming-and-dropping-tables)
- [Columns](#columns)
    - [Creating Columns](#creating-columns)
    - [Available Column Types](#available-column-types)
    - [Column Modifiers](#column-modifiers)
    - [Modifying Columns](#modifying-columns)
    - [Renaming Columns](#renaming-columns)
    - [Dropping Columns](#dropping-columns)
- [Indexes](#indexes)
    - [Creating Indexes](#creating-indexes)
    - [Renaming Indexes](#renaming-indexes)
    - [Dropping Indexes](#dropping-indexes)
    - [Foreign Key Constraints](#foreign-key-constraints)
- [Events](#events)

<a name="introduction"></a>
## Introduction

Migrations are like version control for your database, allowing your team to define and share the application's database schema definition. If you have ever had to tell a teammate to manually add a column to their local database schema after pulling in your changes from source control, you've faced the problem that database migrations solve.

The Laravel `Schema` [facade](/docs/{{version}}/facades) provides database agnostic support for creating and manipulating tables across all of Laravel's supported database systems. Typically, migrations will use this facade to create and modify database tables and columns.

<a name="generating-migrations"></a>
## Generating Migrations

You may use the `make:migration` [Artisan command](/docs/{{version}}/artisan) to generate a database migration. The new migration will be placed in your `database/migrations` directory. Each migration filename contains a timestamp that allows Laravel to determine the order of the migrations:

```shell
php artisan make:migration create_flights_table
```

Laravel will use the name of the migration to attempt to guess the name of the table and whether or not the migration will be creating a new table. If Laravel is able to determine the table name from the migration name, Laravel will pre-fill the generated migration file with the specified table. Otherwise, you may simply specify the table in the migration file manually.

If you would like to specify a custom path for the generated migration, you may use the `--path` option when executing the `make:migration` command. The given path should be relative to your application's base path.

> [!NOTE]  
> Migration stubs may be customized using [stub publishing](/docs/{{version}}/artisan#stub-customization).

<a name="squashing-migrations"></a>
### Squashing Migrations

As you build your application, you may accumulate more and more migrations over time. This can lead to your `database/migrations` directory becoming bloated with potentially hundreds of migrations. If you would like, you may "squash" your migrations into a single SQL file. To get started, execute the `schema:dump` command:

```shell
php artisan schema:dump

# Dump the current database schema and prune all existing migrations...
php artisan schema:dump --prune
```

When you execute this command, Laravel will write a "schema" file to your application's `database/schema` directory. The schema file's name will correspond to the database connection. Now, when you attempt to migrate your database and no other migrations have been executed, Laravel will first execute the SQL statements in the schema file of the database connection you are using. After executing the schema file's SQL statements, Laravel will execute any remaining migrations that were not part of the schema dump.

If your application's tests use a different database connection than the one you typically use during local development, you should ensure you have dumped a schema file using that database connection so that your tests are able to build your database. You may wish to do this after dumping the database connection you typically use during local development:

```shell
php artisan schema:dump
php artisan schema:dump --database=testing --prune
```

You should commit your database schema file to source control so that other new developers on your team may quickly create your application's initial database structure.

> [!WARNING]  
> Migration squashing is only available for the MySQL, PostgreSQL, and SQLite databases and utilizes the database's command-line client.

<a name="migration-structure"></a>
## Migration Structure

A migration class contains two methods: `up` and `down`. The `up` method is used to add new tables, columns, or indexes to your database, while the `down` method should reverse the operations performed by the `up` method.

Within both of these methods, you may use the Laravel schema builder to expressively create and modify tables. To learn about all of the methods available on the `Schema` builder, [check out its documentation](#creating-tables). For example, the following migration creates a `flights` table:

    <?php

    use Illuminate\Database\Migrations\Migration;
    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    return new class extends Migration
    {
        /**
         * Run the migrations.
         */
        public function up(): void
        {
            Schema::create('flights', function (Blueprint $table) {
                $table->id();
                $table->string('name');
                $table->string('airline');
                $table->timestamps();
            });
        }

        /**
         * Reverse the migrations.
         */
        public function down(): void
        {
            Schema::drop('flights');
        }
    };

<a name="setting-the-migration-connection"></a>
#### Setting the Migration Connection

If your migration will be interacting with a database connection other than your application's default database connection, you should set the `$connection` property of your migration:

    /**
     * The database connection that should be used by the migration.
     *
     * @var string
     */
    protected $connection = 'pgsql';

    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // ...
    }

<a name="running-migrations"></a>
## Running Migrations

To run all of your outstanding migrations, execute the `migrate` Artisan command:

```shell
php artisan migrate
```

If you would like to see which migrations have run thus far, you may use the `migrate:status` Artisan command:

```shell
php artisan migrate:status
```

If you would like to see the SQL statements that will be executed by the migrations without actually running them, you may provide the `--pretend` flag to the `migrate` command:

```shell
php artisan migrate --pretend
```

#### Isolating Migration Execution

If you are deploying your application across multiple servers and running migrations as part of your deployment process, you likely do not want two servers attempting to migrate the database at the same time. To avoid this, you may use the `isolated` option when invoking the `migrate` command.

When the `isolated` option is provided, Laravel will acquire an atomic lock using your application's cache driver before attempting to run your migrations. All other attempts to run the `migrate` command while that lock is held will not execute; however, the command will still exit with a successful exit status code:

```shell
php artisan migrate --isolated
```

> [!WARNING]  
> To utilize this feature, your application must be using the `memcached`, `redis`, `dynamodb`, `database`, `file`, or `array` cache driver as your application's default cache driver. In addition, all servers must be communicating with the same central cache server.

<a name="forcing-migrations-to-run-in-production"></a>
#### Forcing Migrations to Run in Production

Some migration operations are destructive, which means they may cause you to lose data. In order to protect you from running these commands against your production database, you will be prompted for confirmation before the commands are executed. To force the commands to run without a prompt, use the `--force` flag:

```shell
php artisan migrate --force
```

<a name="rolling-back-migrations"></a>
### Rolling Back Migrations

To roll back the latest migration operation, you may use the `rollback` Artisan command. This command rolls back the last "batch" of migrations, which may include multiple migration files:

```shell
php artisan migrate:rollback
```

You may roll back a limited number of migrations by providing the `step` option to the `rollback` command. For example, the following command will roll back the last five migrations:

```shell
php artisan migrate:rollback --step=5
```

You may roll back a specific "batch" of migrations by providing the `batch` option to the `rollback` command, where the `batch` option corresponds to a batch value within your application's `migrations` database table. For example, the following command will roll back all migrations in batch three:

 ```shell
 php artisan migrate:rollback --batch=3
 ```

If you would like to see the SQL statements that will be executed by the migrations without actually running them, you may provide the `--pretend` flag to the `migrate:rollback` command:

```shell
php artisan migrate:rollback --pretend
```

The `migrate:reset` command will roll back all of your application's migrations:

```shell
php artisan migrate:reset
```

<a name="roll-back-migrate-using-a-single-command"></a>
#### Roll Back and Migrate Using a Single Command

The `migrate:refresh` command will roll back all of your migrations and then execute the `migrate` command. This command effectively re-creates your entire database:

```shell
php artisan migrate:refresh

# Refresh the database and run all database seeds...
php artisan migrate:refresh --seed
```

You may roll back and re-migrate a limited number of migrations by providing the `step` option to the `refresh` command. For example, the following command will roll back and re-migrate the last five migrations:

```shell
php artisan migrate:refresh --step=5
```

<a name="drop-all-tables-migrate"></a>
#### Drop All Tables and Migrate

The `migrate:fresh` command will drop all tables from the database and then execute the `migrate` command:

```shell
php artisan migrate:fresh

php artisan migrate:fresh --seed
```

By default, the `migrate:fresh` command only drops tables from the default database connection. However, you may use the `--database` option to specify the database connection that should be migrated. The database connection name should correspond to a connection defined in your application's `database` [configuration file](/docs/{{version}}/configuration):

```shell
php artisan migrate:fresh --database=admin
```

> [!WARNING]  
> The `migrate:fresh` command will drop all database tables regardless of their prefix. This command should be used with caution when developing on a database that is shared with other applications.

<a name="tables"></a>
## Tables

<a name="creating-tables"></a>
### Creating Tables

To create a new database table, use the `create` method on the `Schema` facade. The `create` method accepts two arguments: the first is the name of the table, while the second is a closure which receives a `Blueprint` object that may be used to define the new table:

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::create('users', function (Blueprint $table) {
        $table->id();
        $table->string('name');
        $table->string('email');
        $table->timestamps();
    });

When creating the table, you may use any of the schema builder's [column methods](#creating-columns) to define the table's columns.

<a name="determining-table-column-existence"></a>
#### Determining Table / Column Existence

You may determine the existence of a table or column using the `hasTable` and `hasColumn` methods:

    if (Schema::hasTable('users')) {
        // The "users" table exists...
    }

    if (Schema::hasColumn('users', 'email')) {
        // The "users" table exists and has an "email" column...
    }

<a name="database-connection-table-options"></a>
#### Database Connection and Table Options

If you want to perform a schema operation on a database connection that is not your application's default connection, use the `connection` method:

    Schema::connection('sqlite')->create('users', function (Blueprint $table) {
        $table->id();
    });

In addition, a few other properties and methods may be used to define other aspects of the table's creation. The `engine` property may be used to specify the table's storage engine when using MySQL:

    Schema::create('users', function (Blueprint $table) {
        $table->engine = 'InnoDB';

        // ...
    });

The `charset` and `collation` properties may be used to specify the character set and collation for the created table when using MySQL:

    Schema::create('users', function (Blueprint $table) {
        $table->charset = 'utf8mb4';
        $table->collation = 'utf8mb4_unicode_ci';

        // ...
    });

The `temporary` method may be used to indicate that the table should be "temporary". Temporary tables are only visible to the current connection's database session and are dropped automatically when the connection is closed:

    Schema::create('calculations', function (Blueprint $table) {
        $table->temporary();

        // ...
    });

If you would like to add a "comment" to a database table, you may invoke the `comment` method on the table instance. Table comments are currently only supported by MySQL and Postgres:

    Schema::create('calculations', function (Blueprint $table) {
        $table->comment('Business calculations');

        // ...
    });

<a name="updating-tables"></a>
### Updating Tables

The `table` method on the `Schema` facade may be used to update existing tables. Like the `create` method, the `table` method accepts two arguments: the name of the table and a closure that receives a `Blueprint` instance you may use to add columns or indexes to the table:

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('users', function (Blueprint $table) {
        $table->integer('votes');
    });

<a name="renaming-and-dropping-tables"></a>
### Renaming / Dropping Tables

To rename an existing database table, use the `rename` method:

    use Illuminate\Support\Facades\Schema;

    Schema::rename($from, $to);

To drop an existing table, you may use the `drop` or `dropIfExists` methods:

    Schema::drop('users');

    Schema::dropIfExists('users');

<a name="renaming-tables-with-foreign-keys"></a>
#### Renaming Tables With Foreign Keys

Before renaming a table, you should verify that any foreign key constraints on the table have an explicit name in your migration files instead of letting Laravel assign a convention based name. Otherwise, the foreign key constraint name will refer to the old table name.

<a name="columns"></a>
## Columns

<a name="creating-columns"></a>
### Creating Columns

The `table` method on the `Schema` facade may be used to update existing tables. Like the `create` method, the `table` method accepts two arguments: the name of the table and a closure that receives an `Illuminate\Database\Schema\Blueprint` instance you may use to add columns to the table:

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('users', function (Blueprint $table) {
        $table->integer('votes');
    });

<a name="available-column-types"></a>
### Available Column Types

The schema builder blueprint offers a variety of methods that correspond to the different types of columns you can add to your database tables. Each of the available methods are listed in the table below:

<style>
    .collection-method-list > p {
        columns: 10.8em 3; -moz-columns: 10.8em 3; -webkit-columns: 10.8em 3;
    }

    .collection-method-list a {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    .collection-method code {
        font-size: 14px;
    }

    .collection-method:not(.first-collection-method) {
        margin-top: 50px;
    }
</style>

<div class="collection-method-list" markdown="1">

[bigIncrements](#column-method-bigIncrements)
[bigInteger](#column-method-bigInteger)
[binary](#column-method-binary)
[boolean](#column-method-boolean)
[char](#column-method-char)
[dateTimeTz](#column-method-dateTimeTz)
[dateTime](#column-method-dateTime)
[date](#column-method-date)
[decimal](#column-method-decimal)
[double](#column-method-double)
[enum](#column-method-enum)
[float](#column-method-float)
[foreignId](#column-method-foreignId)
[foreignIdFor](#column-method-foreignIdFor)
[foreignUlid](#column-method-foreignUlid)
[foreignUuid](#column-method-foreignUuid)
[geometryCollection](#column-method-geometryCollection)
[geometry](#column-method-geometry)
[id](#column-method-id)
[increments](#column-method-increments)
[integer](#column-method-integer)
[ipAddress](#column-method-ipAddress)
[json](#column-method-json)
[jsonb](#column-method-jsonb)
[lineString](#column-method-lineString)
[longText](#column-method-longText)
[macAddress](#column-method-macAddress)
[mediumIncrements](#column-method-mediumIncrements)
[mediumInteger](#column-method-mediumInteger)
[mediumText](#column-method-mediumText)
[morphs](#column-method-morphs)
[multiLineString](#column-method-multiLineString)
[multiPoint](#column-method-multiPoint)
[multiPolygon](#column-method-multiPolygon)
[nullableMorphs](#column-method-nullableMorphs)
[nullableTimestamps](#column-method-nullableTimestamps)
[nullableUlidMorphs](#column-method-nullableUlidMorphs)
[nullableUuidMorphs](#column-method-nullableUuidMorphs)
[point](#column-method-point)
[polygon](#column-method-polygon)
[rememberToken](#column-method-rememberToken)
[set](#column-method-set)
[smallIncrements](#column-method-smallIncrements)
[smallInteger](#column-method-smallInteger)
[softDeletesTz](#column-method-softDeletesTz)
[softDeletes](#column-method-softDeletes)
[string](#column-method-string)
[text](#column-method-text)
[timeTz](#column-method-timeTz)
[time](#column-method-time)
[timestampTz](#column-method-timestampTz)
[timestamp](#column-method-timestamp)
[timestampsTz](#column-method-timestampsTz)
[timestamps](#column-method-timestamps)
[tinyIncrements](#column-method-tinyIncrements)
[tinyInteger](#column-method-tinyInteger)
[tinyText](#column-method-tinyText)
[unsignedBigInteger](#column-method-unsignedBigInteger)
[unsignedDecimal](#column-method-unsignedDecimal)
[unsignedInteger](#column-method-unsignedInteger)
[unsignedMediumInteger](#column-method-unsignedMediumInteger)
[unsignedSmallInteger](#column-method-unsignedSmallInteger)
[unsignedTinyInteger](#column-method-unsignedTinyInteger)
[ulidMorphs](#column-method-ulidMorphs)
[uuidMorphs](#column-method-uuidMorphs)
[ulid](#column-method-ulid)
[uuid](#column-method-uuid)
[year](#column-method-year)

</div>

<a name="column-method-bigIncrements"></a>
#### `bigIncrements()` {.collection-method .first-collection-method}

The `bigIncrements` method creates an auto-incrementing `UNSIGNED BIGINT` (primary key) equivalent column:

    $table->bigIncrements('id');

<a name="column-method-bigInteger"></a>
#### `bigInteger()` {.collection-method}

The `bigInteger` method creates a `BIGINT` equivalent column:

    $table->bigInteger('votes');

<a name="column-method-binary"></a>
#### `binary()` {.collection-method}

The `binary` method creates a `BLOB` equivalent column:

    $table->binary('photo');

<a name="column-method-boolean"></a>
#### `boolean()` {.collection-method}

The `boolean` method creates a `BOOLEAN` equivalent column:

    $table->boolean('confirmed');

<a name="column-method-char"></a>
#### `char()` {.collection-method}

The `char` method creates a `CHAR` equivalent column with of a given length:

    $table->char('name', 100);

<a name="column-method-dateTimeTz"></a>
#### `dateTimeTz()` {.collection-method}

The `dateTimeTz` method creates a `DATETIME` (with timezone) equivalent column with an optional precision (total digits):

    $table->dateTimeTz('created_at', $precision = 0);

<a name="column-method-dateTime"></a>
#### `dateTime()` {.collection-method}

The `dateTime` method creates a `DATETIME` equivalent column with an optional precision (total digits):

    $table->dateTime('created_at', $precision = 0);

<a name="column-method-date"></a>
#### `date()` {.collection-method}

The `date` method creates a `DATE` equivalent column:

    $table->date('created_at');

<a name="column-method-decimal"></a>
#### `decimal()` {.collection-method}

The `decimal` method creates a `DECIMAL` equivalent column with the given precision (total digits) and scale (decimal digits):

    $table->decimal('amount', $precision = 8, $scale = 2);

<a name="column-method-double"></a>
#### `double()` {.collection-method}

The `double` method creates a `DOUBLE` equivalent column with the given precision (total digits) and scale (decimal digits):

    $table->double('amount', 8, 2);

<a name="column-method-enum"></a>
#### `enum()` {.collection-method}

The `enum` method creates a `ENUM` equivalent column with the given valid values:

    $table->enum('difficulty', ['easy', 'hard']);

<a name="column-method-float"></a>
#### `float()` {.collection-method}

The `float` method creates a `FLOAT` equivalent column with the given precision (total digits) and scale (decimal digits):

    $table->float('amount', 8, 2);

<a name="column-method-foreignId"></a>
#### `foreignId()` {.collection-method}

The `foreignId` method creates an `UNSIGNED BIGINT` equivalent column:

    $table->foreignId('user_id');

<a name="column-method-foreignIdFor"></a>
#### `foreignIdFor()` {.collection-method}

The `foreignIdFor` method adds a `{column}_id` equivalent column for a given model class. The column type will be `UNSIGNED BIGINT`, `CHAR(36)`, or `CHAR(26)` depending on the model key type:

    $table->foreignIdFor(User::class);

<a name="column-method-foreignUlid"></a>
#### `foreignUlid()` {.collection-method}

The `foreignUlid` method creates a `ULID` equivalent column:

    $table->foreignUlid('user_id');

<a name="column-method-foreignUuid"></a>
#### `foreignUuid()` {.collection-method}

The `foreignUuid` method creates a `UUID` equivalent column:

    $table->foreignUuid('user_id');

<a name="column-method-geometryCollection"></a>
#### `geometryCollection()` {.collection-method}

The `geometryCollection` method creates a `GEOMETRYCOLLECTION` equivalent column:

    $table->geometryCollection('positions');

<a name="column-method-geometry"></a>
#### `geometry()` {.collection-method}

The `geometry` method creates a `GEOMETRY` equivalent column:

    $table->geometry('positions');

<a name="column-method-id"></a>
#### `id()` {.collection-method}

The `id` method is an alias of the `bigIncrements` method. By default, the method will create an `id` column; however, you may pass a column name if you would like to assign a different name to the column:

    $table->id();

<a name="column-method-increments"></a>
#### `increments()` {.collection-method}

The `increments` method creates an auto-incrementing `UNSIGNED INTEGER` equivalent column as a primary key:

    $table->increments('id');

<a name="column-method-integer"></a>
#### `integer()` {.collection-method}

The `integer` method creates an `INTEGER` equivalent column:

    $table->integer('votes');

<a name="column-method-ipAddress"></a>
#### `ipAddress()` {.collection-method}

The `ipAddress` method creates a `VARCHAR` equivalent column:

    $table->ipAddress('visitor');
    
When using Postgres, an `INET` column will be created.

<a name="column-method-json"></a>
#### `json()` {.collection-method}

The `json` method creates a `JSON` equivalent column:

    $table->json('options');

<a name="column-method-jsonb"></a>
#### `jsonb()` {.collection-method}

The `jsonb` method creates a `JSONB` equivalent column:

    $table->jsonb('options');

<a name="column-method-lineString"></a>
#### `lineString()` {.collection-method}

The `lineString` method creates a `LINESTRING` equivalent column:

    $table->lineString('positions');

<a name="column-method-longText"></a>
#### `longText()` {.collection-method}

The `longText` method creates a `LONGTEXT` equivalent column:

    $table->longText('description');

<a name="column-method-macAddress"></a>
#### `macAddress()` {.collection-method}

The `macAddress` method creates a column that is intended to hold a MAC address. Some database systems, such as PostgreSQL, have a dedicated column type for this type of data. Other database systems will use a string equivalent column:

    $table->macAddress('device');

<a name="column-method-mediumIncrements"></a>
#### `mediumIncrements()` {.collection-method}

The `mediumIncrements` method creates an auto-incrementing `UNSIGNED MEDIUMINT` equivalent column as a primary key:

    $table->mediumIncrements('id');

<a name="column-method-mediumInteger"></a>
#### `mediumInteger()` {.collection-method}

The `mediumInteger` method creates a `MEDIUMINT` equivalent column:

    $table->mediumInteger('votes');

<a name="column-method-mediumText"></a>
#### `mediumText()` {.collection-method}

The `mediumText` method creates a `MEDIUMTEXT` equivalent column:

    $table->mediumText('description');

<a name="column-method-morphs"></a>
#### `morphs()` {.collection-method}

The `morphs` method is a convenience method that adds a `{column}_id` equivalent column and a `{column}_type` `VARCHAR` equivalent column. The column type for the `{column}_id` will be `UNSIGNED BIGINT`, `CHAR(36)`, or `CHAR(26)` depending on the model key type.

This method is intended to be used when defining the columns necessary for a polymorphic [Eloquent relationship](/docs/{{version}}/eloquent-relationships). In the following example, `taggable_id` and `taggable_type` columns would be created:

    $table->morphs('taggable');

<a name="column-method-multiLineString"></a>
#### `multiLineString()` {.collection-method}

The `multiLineString` method creates a `MULTILINESTRING` equivalent column:

    $table->multiLineString('positions');

<a name="column-method-multiPoint"></a>
#### `multiPoint()` {.collection-method}

The `multiPoint` method creates a `MULTIPOINT` equivalent column:

    $table->multiPoint('positions');

<a name="column-method-multiPolygon"></a>
#### `multiPolygon()` {.collection-method}

The `multiPolygon` method creates a `MULTIPOLYGON` equivalent column:

    $table->multiPolygon('positions');

<a name="column-method-nullableTimestamps"></a>
#### `nullableTimestamps()` {.collection-method}

The `nullableTimestamps` method is an alias of the [timestamps](#column-method-timestamps) method:

    $table->nullableTimestamps(0);

<a name="column-method-nullableMorphs"></a>
#### `nullableMorphs()` {.collection-method}

The method is similar to the [morphs](#column-method-morphs) method; however, the columns that are created will be "nullable":

    $table->nullableMorphs('taggable');

<a name="column-method-nullableUlidMorphs"></a>
#### `nullableUlidMorphs()` {.collection-method}

The method is similar to the [ulidMorphs](#column-method-ulidMorphs) method; however, the columns that are created will be "nullable":

    $table->nullableUlidMorphs('taggable');

<a name="column-method-nullableUuidMorphs"></a>
#### `nullableUuidMorphs()` {.collection-method}

The method is similar to the [uuidMorphs](#column-method-uuidMorphs) method; however, the columns that are created will be "nullable":

    $table->nullableUuidMorphs('taggable');

<a name="column-method-point"></a>
#### `point()` {.collection-method}

The `point` method creates a `POINT` equivalent column:

    $table->point('position');

<a name="column-method-polygon"></a>
#### `polygon()` {.collection-method}

The `polygon` method creates a `POLYGON` equivalent column:

    $table->polygon('position');

<a name="column-method-rememberToken"></a>
#### `rememberToken()` {.collection-method}

The `rememberToken` method creates a nullable, `VARCHAR(100)` equivalent column that is intended to store the current "remember me" [authentication token](/docs/{{version}}/authentication#remembering-users):

    $table->rememberToken();

<a name="column-method-set"></a>
#### `set()` {.collection-method}

The `set` method creates a `SET` equivalent column with the given list of valid values:

    $table->set('flavors', ['strawberry', 'vanilla']);

<a name="column-method-smallIncrements"></a>
#### `smallIncrements()` {.collection-method}

The `smallIncrements` method creates an auto-incrementing `UNSIGNED SMALLINT` equivalent column as a primary key:

    $table->smallIncrements('id');

<a name="column-method-smallInteger"></a>
#### `smallInteger()` {.collection-method}

The `smallInteger` method creates a `SMALLINT` equivalent column:

    $table->smallInteger('votes');

<a name="column-method-softDeletesTz"></a>
#### `softDeletesTz()` {.collection-method}

The `softDeletesTz` method adds a nullable `deleted_at` `TIMESTAMP` (with timezone) equivalent column with an optional precision (total digits). This column is intended to store the `deleted_at` timestamp needed for Eloquent's "soft delete" functionality:

    $table->softDeletesTz($column = 'deleted_at', $precision = 0);

<a name="column-method-softDeletes"></a>
#### `softDeletes()` {.collection-method}

The `softDeletes` method adds a nullable `deleted_at` `TIMESTAMP` equivalent column with an optional precision (total digits). This column is intended to store the `deleted_at` timestamp needed for Eloquent's "soft delete" functionality:

    $table->softDeletes($column = 'deleted_at', $precision = 0);

<a name="column-method-string"></a>
#### `string()` {.collection-method}

The `string` method creates a `VARCHAR` equivalent column of the given length:

    $table->string('name', 100);

<a name="column-method-text"></a>
#### `text()` {.collection-method}

The `text` method creates a `TEXT` equivalent column:

    $table->text('description');

<a name="column-method-timeTz"></a>
#### `timeTz()` {.collection-method}

The `timeTz` method creates a `TIME` (with timezone) equivalent column with an optional precision (total digits):

    $table->timeTz('sunrise', $precision = 0);

<a name="column-method-time"></a>
#### `time()` {.collection-method}

The `time` method creates a `TIME` equivalent column with an optional precision (total digits):

    $table->time('sunrise', $precision = 0);

<a name="column-method-timestampTz"></a>
#### `timestampTz()` {.collection-method}

The `timestampTz` method creates a `TIMESTAMP` (with timezone) equivalent column with an optional precision (total digits):

    $table->timestampTz('added_at', $precision = 0);

<a name="column-method-timestamp"></a>
#### `timestamp()` {.collection-method}

The `timestamp` method creates a `TIMESTAMP` equivalent column with an optional precision (total digits):

    $table->timestamp('added_at', $precision = 0);

<a name="column-method-timestampsTz"></a>
#### `timestampsTz()` {.collection-method}

The `timestampsTz` method creates `created_at` and `updated_at` `TIMESTAMP` (with timezone) equivalent columns with an optional precision (total digits):

    $table->timestampsTz($precision = 0);

<a name="column-method-timestamps"></a>
#### `timestamps()` {.collection-method}

The `timestamps` method creates `created_at` and `updated_at` `TIMESTAMP` equivalent columns with an optional precision (total digits):

    $table->timestamps($precision = 0);

<a name="column-method-tinyIncrements"></a>
#### `tinyIncrements()` {.collection-method}

The `tinyIncrements` method creates an auto-incrementing `UNSIGNED TINYINT` equivalent column as a primary key:

    $table->tinyIncrements('id');

<a name="column-method-tinyInteger"></a>
#### `tinyInteger()` {.collection-method}

The `tinyInteger` method creates a `TINYINT` equivalent column:

    $table->tinyInteger('votes');

<a name="column-method-tinyText"></a>
#### `tinyText()` {.collection-method}

The `tinyText` method creates a `TINYTEXT` equivalent column:

    $table->tinyText('notes');

<a name="column-method-unsignedBigInteger"></a>
#### `unsignedBigInteger()` {.collection-method}

The `unsignedBigInteger` method creates an `UNSIGNED BIGINT` equivalent column:

    $table->unsignedBigInteger('votes');

<a name="column-method-unsignedDecimal"></a>
#### `unsignedDecimal()` {.collection-method}

The `unsignedDecimal` method creates an `UNSIGNED DECIMAL` equivalent column with an optional precision (total digits) and scale (decimal digits):

    $table->unsignedDecimal('amount', $precision = 8, $scale = 2);

<a name="column-method-unsignedInteger"></a>
#### `unsignedInteger()` {.collection-method}

The `unsignedInteger` method creates an `UNSIGNED INTEGER` equivalent column:

    $table->unsignedInteger('votes');

<a name="column-method-unsignedMediumInteger"></a>
#### `unsignedMediumInteger()` {.collection-method}

The `unsignedMediumInteger` method creates an `UNSIGNED MEDIUMINT` equivalent column:

    $table->unsignedMediumInteger('votes');

<a name="column-method-unsignedSmallInteger"></a>
#### `unsignedSmallInteger()` {.collection-method}

The `unsignedSmallInteger` method creates an `UNSIGNED SMALLINT` equivalent column:

    $table->unsignedSmallInteger('votes');

<a name="column-method-unsignedTinyInteger"></a>
#### `unsignedTinyInteger()` {.collection-method}

The `unsignedTinyInteger` method creates an `UNSIGNED TINYINT` equivalent column:

    $table->unsignedTinyInteger('votes');

<a name="column-method-ulidMorphs"></a>
#### `ulidMorphs()` {.collection-method}

The `ulidMorphs` method is a convenience method that adds a `{column}_id` `CHAR(26)` equivalent column and a `{column}_type` `VARCHAR` equivalent column.

This method is intended to be used when defining the columns necessary for a polymorphic [Eloquent relationship](/docs/{{version}}/eloquent-relationships) that use ULID identifiers. In the following example, `taggable_id` and `taggable_type` columns would be created:

    $table->ulidMorphs('taggable');

<a name="column-method-uuidMorphs"></a>
#### `uuidMorphs()` {.collection-method}

The `uuidMorphs` method is a convenience method that adds a `{column}_id` `CHAR(36)` equivalent column and a `{column}_type` `VARCHAR` equivalent column.

This method is intended to be used when defining the columns necessary for a polymorphic [Eloquent relationship](/docs/{{version}}/eloquent-relationships) that use UUID identifiers. In the following example, `taggable_id` and `taggable_type` columns would be created:

    $table->uuidMorphs('taggable');

<a name="column-method-ulid"></a>
#### `ulid()` {.collection-method}

The `ulid` method creates a `ULID` equivalent column:

    $table->ulid('id');

<a name="column-method-uuid"></a>
#### `uuid()` {.collection-method}

The `uuid` method creates a `UUID` equivalent column:

    $table->uuid('id');

<a name="column-method-year"></a>
#### `year()` {.collection-method}

The `year` method creates a `YEAR` equivalent column:

    $table->year('birth_year');

<a name="column-modifiers"></a>
### Column Modifiers

In addition to the column types listed above, there are several column "modifiers" you may use when adding a column to a database table. For example, to make the column "nullable", you may use the `nullable` method:

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('users', function (Blueprint $table) {
        $table->string('email')->nullable();
    });

The following table contains all of the available column modifiers. This list does not include [index modifiers](#creating-indexes):

Modifier  |  Description
--------  |  -----------
`->after('column')`  |  Place the column "after" another column (MySQL).
`->autoIncrement()`  |  Set INTEGER columns as auto-incrementing (primary key).
`->charset('utf8mb4')`  |  Specify a character set for the column (MySQL).
`->collation('utf8mb4_unicode_ci')`  |  Specify a collation for the column (MySQL/PostgreSQL/SQL Server).
`->comment('my comment')`  |  Add a comment to a column (MySQL/PostgreSQL).
`->default($value)`  |  Specify a "default" value for the column.
`->first()`  |  Place the column "first" in the table (MySQL).
`->from($integer)`  |  Set the starting value of an auto-incrementing field (MySQL / PostgreSQL).
`->invisible()`  |  Make the column "invisible" to `SELECT *` queries (MySQL).
`->nullable($value = true)`  |  Allow NULL values to be inserted into the column.
`->storedAs($expression)`  |  Create a stored generated column (MySQL / PostgreSQL).
`->unsigned()`  |  Set INTEGER columns as UNSIGNED (MySQL).
`->useCurrent()`  |  Set TIMESTAMP columns to use CURRENT_TIMESTAMP as default value.
`->useCurrentOnUpdate()`  |  Set TIMESTAMP columns to use CURRENT_TIMESTAMP when a record is updated (MySQL).
`->virtualAs($expression)`  |  Create a virtual generated column (MySQL / PostgreSQL / SQLite).
`->generatedAs($expression)`  |  Create an identity column with specified sequence options (PostgreSQL).
`->always()`  |  Defines the precedence of sequence values over input for an identity column (PostgreSQL).
`->isGeometry()`  |  Set spatial column type to `geometry` - the default type is `geography` (PostgreSQL).

<a name="default-expressions"></a>
#### Default Expressions

The `default` modifier accepts a value or an `Illuminate\Database\Query\Expression` instance. Using an `Expression` instance will prevent Laravel from wrapping the value in quotes and allow you to use database specific functions. One situation where this is particularly useful is when you need to assign default values to JSON columns:

    <?php

    use Illuminate\Support\Facades\Schema;
    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Database\Query\Expression;
    use Illuminate\Database\Migrations\Migration;

    return new class extends Migration
    {
        /**
         * Run the migrations.
         */
        public function up(): void
        {
            Schema::create('flights', function (Blueprint $table) {
                $table->id();
                $table->json('movies')->default(new Expression('(JSON_ARRAY())'));
                $table->timestamps();
            });
        }
    };

> [!WARNING]  
> Support for default expressions depends on your database driver, database version, and the field type. Please refer to your database's documentation.

<a name="column-order"></a>
#### Column Order

When using the MySQL database, the `after` method may be used to add columns after an existing column in the schema:

    $table->after('password', function (Blueprint $table) {
        $table->string('address_line1');
        $table->string('address_line2');
        $table->string('city');
    });

<a name="modifying-columns"></a>
### Modifying Columns

The `change` method allows you to modify the type and attributes of existing columns. For example, you may wish to increase the size of a `string` column. To see the `change` method in action, let's increase the size of the `name` column from 25 to 50. To accomplish this, we simply define the new state of the column and then call the `change` method:

    Schema::table('users', function (Blueprint $table) {
        $table->string('name', 50)->change();
    });

When modifying a column, you must explicitly include all of the modifiers you want to keep on the column definition - any missing attribute will be dropped. For example, to retain the `unsigned`, `default`, and `comment` attributes, you must call each modifier explicitly when changing the column:

    Schema::table('users', function (Blueprint $table) {
        $table->integer('votes')->unsigned()->default(1)->comment('my comment')->change();
    });

<a name="modifying-columns-on-sqlite"></a>
#### Modifying Columns on SQLite

If your application is utilizing an SQLite database, you must install the `doctrine/dbal` package using the Composer package manager before modifying a column. The Doctrine DBAL library is used to determine the current state of the column and to create the SQL queries needed to make the requested changes to your column:

    composer require doctrine/dbal

If you plan to modify columns created using the `timestamp` method, you must also add the following configuration to your application's `config/database.php` configuration file:

```php
use Illuminate\Database\DBAL\TimestampType;

'dbal' => [
    'types' => [
        'timestamp' => TimestampType::class,
    ],
],
```

> [!WARNING]  
> When using the `doctrine/dbal` package, the following column types can be modified: `bigInteger`, `binary`, `boolean`, `char`, `date`, `dateTime`, `dateTimeTz`, `decimal`, `double`, `integer`, `json`, `longText`, `mediumText`, `smallInteger`, `string`, `text`, `time`, `tinyText`, `unsignedBigInteger`, `unsignedInteger`, `unsignedSmallInteger`, `ulid`, and `uuid`.

<a name="renaming-columns"></a>
### Renaming Columns

To rename a column, you may use the `renameColumn` method provided by the schema builder:

    Schema::table('users', function (Blueprint $table) {
        $table->renameColumn('from', 'to');
    });

<a name="renaming-columns-on-legacy-databases"></a>
#### Renaming Columns on Legacy Databases

If you are running a database installation older than one of the following releases, you should ensure that you have installed the `doctrine/dbal` library via the Composer package manager before renaming a column:

<div class="content-list" markdown="1">

- MySQL < `8.0.3`
- MariaDB < `10.5.2`
- SQLite < `3.25.0`

</div>

<a name="dropping-columns"></a>
### Dropping Columns

To drop a column, you may use the `dropColumn` method on the schema builder:

    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('votes');
    });

You may drop multiple columns from a table by passing an array of column names to the `dropColumn` method:

    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn(['votes', 'avatar', 'location']);
    });

<a name="dropping-columns-on-legacy-databases"></a>
#### Dropping Columns on Legacy Databases

If you are running a version of SQLite prior to `3.35.0`, you must install the `doctrine/dbal` package via the Composer package manager before the `dropColumn` method may be used. Dropping or modifying multiple columns within a single migration while using this package is not supported.

<a name="available-command-aliases"></a>
#### Available Command Aliases

Laravel provides several convenient methods related to dropping common types of columns. Each of these methods is described in the table below:

Command  |  Description
-------  |  -----------
`$table->dropMorphs('morphable');`  |  Drop the `morphable_id` and `morphable_type` columns.
`$table->dropRememberToken();`  |  Drop the `remember_token` column.
`$table->dropSoftDeletes();`  |  Drop the `deleted_at` column.
`$table->dropSoftDeletesTz();`  |  Alias of `dropSoftDeletes()` method.
`$table->dropTimestamps();`  |  Drop the `created_at` and `updated_at` columns.
`$table->dropTimestampsTz();` |  Alias of `dropTimestamps()` method.

<a name="indexes"></a>
## Indexes

<a name="creating-indexes"></a>
### Creating Indexes

The Laravel schema builder supports several types of indexes. The following example creates a new `email` column and specifies that its values should be unique. To create the index, we can chain the `unique` method onto the column definition:

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('users', function (Blueprint $table) {
        $table->string('email')->unique();
    });

Alternatively, you may create the index after defining the column. To do so, you should call the `unique` method on the schema builder blueprint. This method accepts the name of the column that should receive a unique index:

    $table->unique('email');

You may even pass an array of columns to an index method to create a compound (or composite) index:

    $table->index(['account_id', 'created_at']);

When creating an index, Laravel will automatically generate an index name based on the table, column names, and the index type, but you may pass a second argument to the method to specify the index name yourself:

    $table->unique('email', 'unique_email');

<a name="available-index-types"></a>
#### Available Index Types

Laravel's schema builder blueprint class provides methods for creating each type of index supported by Laravel. Each index method accepts an optional second argument to specify the name of the index. If omitted, the name will be derived from the names of the table and column(s) used for the index, as well as the index type. Each of the available index methods is described in the table below:

Command  |  Description
-------  |  -----------
`$table->primary('id');`  |  Adds a primary key.
`$table->primary(['id', 'parent_id']);`  |  Adds composite keys.
`$table->unique('email');`  |  Adds a unique index.
`$table->index('state');`  |  Adds an index.
`$table->fullText('body');`  |  Adds a full text index (MySQL/PostgreSQL).
`$table->fullText('body')->language('english');`  |  Adds a full text index of the specified language (PostgreSQL).
`$table->spatialIndex('location');`  |  Adds a spatial index (except SQLite).

<a name="index-lengths-mysql-mariadb"></a>
#### Index Lengths and MySQL / MariaDB

By default, Laravel uses the `utf8mb4` character set. If you are running a version of MySQL older than the 5.7.7 release or MariaDB older than the 10.2.2 release, you may need to manually configure the default string length generated by migrations in order for MySQL to create indexes for them. You may configure the default string length by calling the `Schema::defaultStringLength` method within the `boot` method of your `App\Providers\AppServiceProvider` class:

    use Illuminate\Support\Facades\Schema;

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Schema::defaultStringLength(191);
    }

Alternatively, you may enable the `innodb_large_prefix` option for your database. Refer to your database's documentation for instructions on how to properly enable this option.

<a name="renaming-indexes"></a>
### Renaming Indexes

To rename an index, you may use the `renameIndex` method provided by the schema builder blueprint. This method accepts the current index name as its first argument and the desired name as its second argument:

    $table->renameIndex('from', 'to')

> [!WARNING]  
> If your application is utilizing an SQLite database, you must install the `doctrine/dbal` package via the Composer package manager before the `renameIndex` method may be used.

<a name="dropping-indexes"></a>
### Dropping Indexes

To drop an index, you must specify the index's name. By default, Laravel automatically assigns an index name based on the table name, the name of the indexed column, and the index type. Here are some examples:

Command  |  Description
-------  |  -----------
`$table->dropPrimary('users_id_primary');`  |  Drop a primary key from the "users" table.
`$table->dropUnique('users_email_unique');`  |  Drop a unique index from the "users" table.
`$table->dropIndex('geo_state_index');`  |  Drop a basic index from the "geo" table.
`$table->dropFullText('posts_body_fulltext');`  |  Drop a full text index from the "posts" table.
`$table->dropSpatialIndex('geo_location_spatialindex');`  |  Drop a spatial index from the "geo" table  (except SQLite).

If you pass an array of columns into a method that drops indexes, the conventional index name will be generated based on the table name, columns, and index type:

    Schema::table('geo', function (Blueprint $table) {
        $table->dropIndex(['state']); // Drops index 'geo_state_index'
    });

<a name="foreign-key-constraints"></a>
### Foreign Key Constraints

Laravel also provides support for creating foreign key constraints, which are used to force referential integrity at the database level. For example, let's define a `user_id` column on the `posts` table that references the `id` column on a `users` table:

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('posts', function (Blueprint $table) {
        $table->unsignedBigInteger('user_id');

        $table->foreign('user_id')->references('id')->on('users');
    });

Since this syntax is rather verbose, Laravel provides additional, terser methods that use conventions to provide a better developer experience. When using the `foreignId` method to create your column, the example above can be rewritten like so:

    Schema::table('posts', function (Blueprint $table) {
        $table->foreignId('user_id')->constrained();
    });

The `foreignId` method creates an `UNSIGNED BIGINT` equivalent column, while the `constrained` method will use conventions to determine the table and column being referenced. If your table name does not match Laravel's conventions, you may manually provide it to the `constrained` method. In addition, the name that should be assigned to the generated index may be specified as well:

    Schema::table('posts', function (Blueprint $table) {
        $table->foreignId('user_id')->constrained(
            table: 'users', indexName: 'posts_user_id'
        );
    });

You may also specify the desired action for the "on delete" and "on update" properties of the constraint:

    $table->foreignId('user_id')
          ->constrained()
          ->onUpdate('cascade')
          ->onDelete('cascade');

An alternative, expressive syntax is also provided for these actions:

| Method                        | Description                                       |
|-------------------------------|---------------------------------------------------|
| `$table->cascadeOnUpdate();`  | Updates should cascade.                           |
| `$table->restrictOnUpdate();` | Updates should be restricted.                     |
| `$table->noActionOnUpdate();` | No action on updates.                             |
| `$table->cascadeOnDelete();`  | Deletes should cascade.                           |
| `$table->restrictOnDelete();` | Deletes should be restricted.                     |
| `$table->nullOnDelete();`     | Deletes should set the foreign key value to null. |

Any additional [column modifiers](#column-modifiers) must be called before the `constrained` method:

    $table->foreignId('user_id')
          ->nullable()
          ->constrained();

<a name="dropping-foreign-keys"></a>
#### Dropping Foreign Keys

To drop a foreign key, you may use the `dropForeign` method, passing the name of the foreign key constraint to be deleted as an argument. Foreign key constraints use the same naming convention as indexes. In other words, the foreign key constraint name is based on the name of the table and the columns in the constraint, followed by a "\_foreign" suffix:

    $table->dropForeign('posts_user_id_foreign');

Alternatively, you may pass an array containing the column name that holds the foreign key to the `dropForeign` method. The array will be converted to a foreign key constraint name using Laravel's constraint naming conventions:

    $table->dropForeign(['user_id']);

<a name="toggling-foreign-key-constraints"></a>
#### Toggling Foreign Key Constraints

You may enable or disable foreign key constraints within your migrations by using the following methods:

    Schema::enableForeignKeyConstraints();

    Schema::disableForeignKeyConstraints();

    Schema::withoutForeignKeyConstraints(function () {
        // Constraints disabled within this closure...
    });

> [!WARNING]  
> SQLite disables foreign key constraints by default. When using SQLite, make sure to [enable foreign key support](/docs/{{version}}/database#configuration) in your database configuration before attempting to create them in your migrations. In addition, SQLite only supports foreign keys upon creation of the table and [not when tables are altered](https://www.sqlite.org/omitted.html).

<a name="events"></a>
## Events

For convenience, each migration operation will dispatch an [event](/docs/{{version}}/events). All of the following events extend the base `Illuminate\Database\Events\MigrationEvent` class:

 Class | Description
-------|-------
| `Illuminate\Database\Events\MigrationsStarted` | A batch of migrations is about to be executed. |
| `Illuminate\Database\Events\MigrationsEnded` | A batch of migrations has finished executing. |
| `Illuminate\Database\Events\MigrationStarted` | A single migration is about to be executed. |
| `Illuminate\Database\Events\MigrationEnded` | A single migration has finished executing. |
| `Illuminate\Database\Events\SchemaDumped` | A database schema dump has completed. |
| `Illuminate\Database\Events\SchemaLoaded` | An existing database schema dump has loaded. |



## Pagination

# Database: Pagination

- [Introduction](#introduction)
- [Basic Usage](#basic-usage)
    - [Paginating Query Builder Results](#paginating-query-builder-results)
    - [Paginating Eloquent Results](#paginating-eloquent-results)
    - [Cursor Pagination](#cursor-pagination)
    - [Manually Creating a Paginator](#manually-creating-a-paginator)
    - [Customizing Pagination URLs](#customizing-pagination-urls)
- [Displaying Pagination Results](#displaying-pagination-results)
    - [Adjusting the Pagination Link Window](#adjusting-the-pagination-link-window)
    - [Converting Results to JSON](#converting-results-to-json)
- [Customizing the Pagination View](#customizing-the-pagination-view)
    - [Using Bootstrap](#using-bootstrap)
- [Paginator and LengthAwarePaginator Instance Methods](#paginator-instance-methods)
- [Cursor Paginator Instance Methods](#cursor-paginator-instance-methods)

<a name="introduction"></a>
## Introduction

In other frameworks, pagination can be very painful. We hope Laravel's approach to pagination will be a breath of fresh air. Laravel's paginator is integrated with the [query builder](/docs/{{version}}/queries) and [Eloquent ORM](/docs/{{version}}/eloquent) and provides convenient, easy-to-use pagination of database records with zero configuration.

By default, the HTML generated by the paginator is compatible with the [Tailwind CSS framework](https://tailwindcss.com/); however, Bootstrap pagination support is also available.

<a name="tailwind-jit"></a>
#### Tailwind JIT

If you are using Laravel's default Tailwind pagination views and the Tailwind JIT engine, you should ensure your application's `tailwind.config.js` file's `content` key references Laravel's pagination views so that their Tailwind classes are not purged:

```js
content: [
    './resources/**/*.blade.php',
    './resources/**/*.js',
    './resources/**/*.vue',
    './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
],
```

<a name="basic-usage"></a>
## Basic Usage

<a name="paginating-query-builder-results"></a>
### Paginating Query Builder Results

There are several ways to paginate items. The simplest is by using the `paginate` method on the [query builder](/docs/{{version}}/queries) or an [Eloquent query](/docs/{{version}}/eloquent). The `paginate` method automatically takes care of setting the query's "limit" and "offset" based on the current page being viewed by the user. By default, the current page is detected by the value of the `page` query string argument on the HTTP request. This value is automatically detected by Laravel, and is also automatically inserted into links generated by the paginator.

In this example, the only argument passed to the `paginate` method is the number of items you would like displayed "per page". In this case, let's specify that we would like to display `15` items per page:

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Support\Facades\DB;
    use Illuminate\View\View;

    class UserController extends Controller
    {
        /**
         * Show all application users.
         */
        public function index(): View
        {
            return view('user.index', [
                'users' => DB::table('users')->paginate(15)
            ]);
        }
    }

<a name="simple-pagination"></a>
#### Simple Pagination

The `paginate` method counts the total number of records matched by the query before retrieving the records from the database. This is done so that the paginator knows how many pages of records there are in total. However, if you do not plan to show the total number of pages in your application's UI then the record count query is unnecessary.

Therefore, if you only need to display simple "Next" and "Previous" links in your application's UI, you may use the `simplePaginate` method to perform a single, efficient query:

    $users = DB::table('users')->simplePaginate(15);

<a name="paginating-eloquent-results"></a>
### Paginating Eloquent Results

You may also paginate [Eloquent](/docs/{{version}}/eloquent) queries. In this example, we will paginate the `App\Models\User` model and indicate that we plan to display 15 records per page. As you can see, the syntax is nearly identical to paginating query builder results:

    use App\Models\User;

    $users = User::paginate(15);

Of course, you may call the `paginate` method after setting other constraints on the query, such as `where` clauses:

    $users = User::where('votes', '>', 100)->paginate(15);

You may also use the `simplePaginate` method when paginating Eloquent models:

    $users = User::where('votes', '>', 100)->simplePaginate(15);

Similarly, you may use the `cursorPaginate` method to cursor paginate Eloquent models:

    $users = User::where('votes', '>', 100)->cursorPaginate(15);

<a name="multiple-paginator-instances-per-page"></a>
#### Multiple Paginator Instances per Page

Sometimes you may need to render two separate paginators on a single screen that is rendered by your application. However, if both paginator instances use the `page` query string parameter to store the current page, the two paginator's will conflict. To resolve this conflict, you may pass the name of the query string parameter you wish to use to store the paginator's current page via the third argument provided to the `paginate`, `simplePaginate`, and `cursorPaginate` methods:

    use App\Models\User;

    $users = User::where('votes', '>', 100)->paginate(
        $perPage = 15, $columns = ['*'], $pageName = 'users'
    );

<a name="cursor-pagination"></a>
### Cursor Pagination

While `paginate` and `simplePaginate` create queries using the SQL "offset" clause, cursor pagination works by constructing "where" clauses that compare the values of the ordered columns contained in the query, providing the most efficient database performance available amongst all of Laravel's pagination methods. This method of pagination is particularly well-suited for large data-sets and "infinite" scrolling user interfaces.

Unlike offset based pagination, which includes a page number in the query string of the URLs generated by the paginator, cursor based pagination places a "cursor" string in the query string. The cursor is an encoded string containing the location that the next paginated query should start paginating and the direction that it should paginate:

```nothing
http://localhost/users?cursor=eyJpZCI6MTUsIl9wb2ludHNUb05leHRJdGVtcyI6dHJ1ZX0
```

You may create a cursor based paginator instance via the `cursorPaginate` method offered by the query builder. This method returns an instance of `Illuminate\Pagination\CursorPaginator`:

    $users = DB::table('users')->orderBy('id')->cursorPaginate(15);

Once you have retrieved a cursor paginator instance, you may [display the pagination results](#displaying-pagination-results) as you typically would when using the `paginate` and `simplePaginate` methods. For more information on the instance methods offered by the cursor paginator, please consult the [cursor paginator instance method documentation](#cursor-paginator-instance-methods).

> [!WARNING]  
> Your query must contain an "order by" clause in order to take advantage of cursor pagination. In addition, the columns that the query are ordered by must belong to the table you are paginating.

<a name="cursor-vs-offset-pagination"></a>
#### Cursor vs. Offset Pagination

To illustrate the differences between offset pagination and cursor pagination, let's examine some example SQL queries. Both of the following queries will both display the "second page" of results for a `users` table ordered by `id`:

```sql
# Offset Pagination...
select * from users order by id asc limit 15 offset 15;

# Cursor Pagination...
select * from users where id > 15 order by id asc limit 15;
```

The cursor pagination query offers the following advantages over offset pagination:

- For large data-sets, cursor pagination will offer better performance if the "order by" columns are indexed. This is because the "offset" clause scans through all previously matched data.
- For data-sets with frequent writes, offset pagination may skip records or show duplicates if results have been recently added to or deleted from the page a user is currently viewing.

However, cursor pagination has the following limitations:

- Like `simplePaginate`, cursor pagination can only be used to display "Next" and "Previous" links and does not support generating links with page numbers.
- It requires that the ordering is based on at least one unique column or a combination of columns that are unique. Columns with `null` values are not supported.
- Query expressions in "order by" clauses are supported only if they are aliased and added to the "select" clause as well. 
- Query expressions with parameters are not supported.

<a name="manually-creating-a-paginator"></a>
### Manually Creating a Paginator

Sometimes you may wish to create a pagination instance manually, passing it an array of items that you already have in memory. You may do so by creating either an `Illuminate\Pagination\Paginator`, `Illuminate\Pagination\LengthAwarePaginator` or `Illuminate\Pagination\CursorPaginator` instance, depending on your needs.

The `Paginator` and `CursorPaginator` classes do not need to know the total number of items in the result set; however, because of this, these classes do not have methods for retrieving the index of the last page. The `LengthAwarePaginator` accepts almost the same arguments as the `Paginator`; however, it requires a count of the total number of items in the result set.

In other words, the `Paginator` corresponds to the `simplePaginate` method on the query builder, the `CursorPaginator` corresponds to the `cursorPaginate` method, and the `LengthAwarePaginator` corresponds to the `paginate` method.

> [!WARNING]  
> When manually creating a paginator instance, you should manually "slice" the array of results you pass to the paginator. If you're unsure how to do this, check out the [array_slice](https://secure.php.net/manual/en/function.array-slice.php) PHP function.

<a name="customizing-pagination-urls"></a>
### Customizing Pagination URLs

By default, links generated by the paginator will match the current request's URI. However, the paginator's `withPath` method allows you to customize the URI used by the paginator when generating links. For example, if you want the paginator to generate links like `http://example.com/admin/users?page=N`, you should pass `/admin/users` to the `withPath` method:

    use App\Models\User;

    Route::get('/users', function () {
        $users = User::paginate(15);

        $users->withPath('/admin/users');

        // ...
    });

<a name="appending-query-string-values"></a>
#### Appending Query String Values

You may append to the query string of pagination links using the `appends` method. For example, to append `sort=votes` to each pagination link, you should make the following call to `appends`:

    use App\Models\User;

    Route::get('/users', function () {
        $users = User::paginate(15);

        $users->appends(['sort' => 'votes']);

        // ...
    });

You may use the `withQueryString` method if you would like to append all of the current request's query string values to the pagination links:

    $users = User::paginate(15)->withQueryString();

<a name="appending-hash-fragments"></a>
#### Appending Hash Fragments

If you need to append a "hash fragment" to URLs generated by the paginator, you may use the `fragment` method. For example, to append `#users` to the end of each pagination link, you should invoke the `fragment` method like so:

    $users = User::paginate(15)->fragment('users');

<a name="displaying-pagination-results"></a>
## Displaying Pagination Results

When calling the `paginate` method, you will receive an instance of `Illuminate\Pagination\LengthAwarePaginator`, while calling the `simplePaginate` method returns an instance of `Illuminate\Pagination\Paginator`. And, finally, calling the `cursorPaginate` method returns an instance of `Illuminate\Pagination\CursorPaginator`.

These objects provide several methods that describe the result set. In addition to these helper methods, the paginator instances are iterators and may be looped as an array. So, once you have retrieved the results, you may display the results and render the page links using [Blade](/docs/{{version}}/blade):

```blade
<div class="container">
    @foreach ($users as $user)
        {{ $user->name }}
    @endforeach
</div>

{{ $users->links() }}
```

The `links` method will render the links to the rest of the pages in the result set. Each of these links will already contain the proper `page` query string variable. Remember, the HTML generated by the `links` method is compatible with the [Tailwind CSS framework](https://tailwindcss.com).

<a name="adjusting-the-pagination-link-window"></a>
### Adjusting the Pagination Link Window

When the paginator displays pagination links, the current page number is displayed as well as links for the three pages before and after the current page. Using the `onEachSide` method, you may control how many additional links are displayed on each side of the current page within the middle, sliding window of links generated by the paginator:

```blade
{{ $users->onEachSide(5)->links() }}
```

<a name="converting-results-to-json"></a>
### Converting Results to JSON

The Laravel paginator classes implement the `Illuminate\Contracts\Support\Jsonable` Interface contract and expose the `toJson` method, so it's very easy to convert your pagination results to JSON. You may also convert a paginator instance to JSON by returning it from a route or controller action:

    use App\Models\User;

    Route::get('/users', function () {
        return User::paginate();
    });

The JSON from the paginator will include meta information such as `total`, `current_page`, `last_page`, and more. The result records are available via the `data` key in the JSON array. Here is an example of the JSON created by returning a paginator instance from a route:

    {
       "total": 50,
       "per_page": 15,
       "current_page": 1,
       "last_page": 4,
       "first_page_url": "http://laravel.app?page=1",
       "last_page_url": "http://laravel.app?page=4",
       "next_page_url": "http://laravel.app?page=2",
       "prev_page_url": null,
       "path": "http://laravel.app",
       "from": 1,
       "to": 15,
       "data":[
            {
                // Record...
            },
            {
                // Record...
            }
       ]
    }

<a name="customizing-the-pagination-view"></a>
## Customizing the Pagination View

By default, the views rendered to display the pagination links are compatible with the [Tailwind CSS](https://tailwindcss.com) framework. However, if you are not using Tailwind, you are free to define your own views to render these links. When calling the `links` method on a paginator instance, you may pass the view name as the first argument to the method:

```blade
{{ $paginator->links('view.name') }}

<!-- Passing additional data to the view... -->
{{ $paginator->links('view.name', ['foo' => 'bar']) }}
```

However, the easiest way to customize the pagination views is by exporting them to your `resources/views/vendor` directory using the `vendor:publish` command:

```shell
php artisan vendor:publish --tag=laravel-pagination
```

This command will place the views in your application's `resources/views/vendor/pagination` directory. The `tailwind.blade.php` file within this directory corresponds to the default pagination view. You may edit this file to modify the pagination HTML.

If you would like to designate a different file as the default pagination view, you may invoke the paginator's `defaultView` and `defaultSimpleView` methods within the `boot` method of your `App\Providers\AppServiceProvider` class:

    <?php

    namespace App\Providers;

    use Illuminate\Pagination\Paginator;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * Bootstrap any application services.
         */
        public function boot(): void
        {
            Paginator::defaultView('view-name');

            Paginator::defaultSimpleView('view-name');
        }
    }

<a name="using-bootstrap"></a>
### Using Bootstrap

Laravel includes pagination views built using [Bootstrap CSS](https://getbootstrap.com/). To use these views instead of the default Tailwind views, you may call the paginator's `useBootstrapFour` or `useBootstrapFive` methods within the `boot` method of your `App\Providers\AppServiceProvider` class:

    use Illuminate\Pagination\Paginator;

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Paginator::useBootstrapFive();
        Paginator::useBootstrapFour();
    }

<a name="paginator-instance-methods"></a>
## Paginator / LengthAwarePaginator Instance Methods

Each paginator instance provides additional pagination information via the following methods:

Method  |  Description
-------  |  -----------
`$paginator->count()`  |  Get the number of items for the current page.
`$paginator->currentPage()`  |  Get the current page number.
`$paginator->firstItem()`  |  Get the result number of the first item in the results.
`$paginator->getOptions()`  |  Get the paginator options.
`$paginator->getUrlRange($start, $end)`  |  Create a range of pagination URLs.
`$paginator->hasPages()`  |  Determine if there are enough items to split into multiple pages.
`$paginator->hasMorePages()`  |  Determine if there are more items in the data store.
`$paginator->items()`  |  Get the items for the current page.
`$paginator->lastItem()`  |  Get the result number of the last item in the results.
`$paginator->lastPage()`  |  Get the page number of the last available page. (Not available when using `simplePaginate`).
`$paginator->nextPageUrl()`  |  Get the URL for the next page.
`$paginator->onFirstPage()`  |  Determine if the paginator is on the first page.
`$paginator->perPage()`  |  The number of items to be shown per page.
`$paginator->previousPageUrl()`  |  Get the URL for the previous page.
`$paginator->total()`  |  Determine the total number of matching items in the data store. (Not available when using `simplePaginate`).
`$paginator->url($page)`  |  Get the URL for a given page number.
`$paginator->getPageName()`  |  Get the query string variable used to store the page.
`$paginator->setPageName($name)`  |  Set the query string variable used to store the page.
`$paginator->through($callback)`  |  Transform each item using a callback.

<a name="cursor-paginator-instance-methods"></a>
## Cursor Paginator Instance Methods

Each cursor paginator instance provides additional pagination information via the following methods:

Method  |  Description
-------  |  -----------
`$paginator->count()`  |  Get the number of items for the current page.
`$paginator->cursor()`  |  Get the current cursor instance.
`$paginator->getOptions()`  |  Get the paginator options.
`$paginator->hasPages()`  |  Determine if there are enough items to split into multiple pages.
`$paginator->hasMorePages()`  |  Determine if there are more items in the data store.
`$paginator->getCursorName()`  |  Get the query string variable used to store the cursor.
`$paginator->items()`  |  Get the items for the current page.
`$paginator->nextCursor()`  |  Get the cursor instance for the next set of items.
`$paginator->nextPageUrl()`  |  Get the URL for the next page.
`$paginator->onFirstPage()`  |  Determine if the paginator is on the first page.
`$paginator->onLastPage()`  |  Determine if the paginator is on the last page.
`$paginator->perPage()`  |  The number of items to be shown per page.
`$paginator->previousCursor()`  |  Get the cursor instance for the previous set of items.
`$paginator->previousPageUrl()`  |  Get the URL for the previous page.
`$paginator->setCursorName()`  |  Set the query string variable used to store the cursor.
`$paginator->url($cursor)`  |  Get the URL for a given cursor instance.



## Queries

# Database: Query Builder

- [Introduction](#introduction)
- [Running Database Queries](#running-database-queries)
    - [Chunking Results](#chunking-results)
    - [Streaming Results Lazily](#streaming-results-lazily)
    - [Aggregates](#aggregates)
- [Select Statements](#select-statements)
- [Raw Expressions](#raw-expressions)
- [Joins](#joins)
- [Unions](#unions)
- [Basic Where Clauses](#basic-where-clauses)
    - [Where Clauses](#where-clauses)
    - [Or Where Clauses](#or-where-clauses)
    - [Where Not Clauses](#where-not-clauses)
    - [Where Any / All Clauses](#where-any-all-clauses)
    - [JSON Where Clauses](#json-where-clauses)
    - [Additional Where Clauses](#additional-where-clauses)
    - [Logical Grouping](#logical-grouping)
- [Advanced Where Clauses](#advanced-where-clauses)
    - [Where Exists Clauses](#where-exists-clauses)
    - [Subquery Where Clauses](#subquery-where-clauses)
    - [Full Text Where Clauses](#full-text-where-clauses)
- [Ordering, Grouping, Limit and Offset](#ordering-grouping-limit-and-offset)
    - [Ordering](#ordering)
    - [Grouping](#grouping)
    - [Limit and Offset](#limit-and-offset)
- [Conditional Clauses](#conditional-clauses)
- [Insert Statements](#insert-statements)
    - [Upserts](#upserts)
- [Update Statements](#update-statements)
    - [Updating JSON Columns](#updating-json-columns)
    - [Increment and Decrement](#increment-and-decrement)
- [Delete Statements](#delete-statements)
- [Pessimistic Locking](#pessimistic-locking)
- [Debugging](#debugging)

<a name="introduction"></a>
## Introduction

Laravel's database query builder provides a convenient, fluent interface to creating and running database queries. It can be used to perform most database operations in your application and works perfectly with all of Laravel's supported database systems.

The Laravel query builder uses PDO parameter binding to protect your application against SQL injection attacks. There is no need to clean or sanitize strings passed to the query builder as query bindings.

> [!WARNING]  
> PDO does not support binding column names. Therefore, you should never allow user input to dictate the column names referenced by your queries, including "order by" columns.

<a name="running-database-queries"></a>
## Running Database Queries

<a name="retrieving-all-rows-from-a-table"></a>
#### Retrieving All Rows From a Table

You may use the `table` method provided by the `DB` facade to begin a query. The `table` method returns a fluent query builder instance for the given table, allowing you to chain more constraints onto the query and then finally retrieve the results of the query using the `get` method:

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Support\Facades\DB;
    use Illuminate\View\View;

    class UserController extends Controller
    {
        /**
         * Show a list of all of the application's users.
         */
        public function index(): View
        {
            $users = DB::table('users')->get();

            return view('user.index', ['users' => $users]);
        }
    }

The `get` method returns an `Illuminate\Support\Collection` instance containing the results of the query where each result is an instance of the PHP `stdClass` object. You may access each column's value by accessing the column as a property of the object:

    use Illuminate\Support\Facades\DB;

    $users = DB::table('users')->get();

    foreach ($users as $user) {
        echo $user->name;
    }

> [!NOTE]  
> Laravel collections provide a variety of extremely powerful methods for mapping and reducing data. For more information on Laravel collections, check out the [collection documentation](/docs/{{version}}/collections).

<a name="retrieving-a-single-row-column-from-a-table"></a>
#### Retrieving a Single Row / Column From a Table

If you just need to retrieve a single row from a database table, you may use the `DB` facade's `first` method. This method will return a single `stdClass` object:

    $user = DB::table('users')->where('name', 'John')->first();

    return $user->email;

If you don't need an entire row, you may extract a single value from a record using the `value` method. This method will return the value of the column directly:

    $email = DB::table('users')->where('name', 'John')->value('email');

To retrieve a single row by its `id` column value, use the `find` method:

    $user = DB::table('users')->find(3);

<a name="retrieving-a-list-of-column-values"></a>
#### Retrieving a List of Column Values

If you would like to retrieve an `Illuminate\Support\Collection` instance containing the values of a single column, you may use the `pluck` method. In this example, we'll retrieve a collection of user titles:

    use Illuminate\Support\Facades\DB;

    $titles = DB::table('users')->pluck('title');

    foreach ($titles as $title) {
        echo $title;
    }

 You may specify the column that the resulting collection should use as its keys by providing a second argument to the `pluck` method:

    $titles = DB::table('users')->pluck('title', 'name');

    foreach ($titles as $name => $title) {
        echo $title;
    }

<a name="chunking-results"></a>
### Chunking Results

If you need to work with thousands of database records, consider using the `chunk` method provided by the `DB` facade. This method retrieves a small chunk of results at a time and feeds each chunk into a closure for processing. For example, let's retrieve the entire `users` table in chunks of 100 records at a time:

    use Illuminate\Support\Collection;
    use Illuminate\Support\Facades\DB;

    DB::table('users')->orderBy('id')->chunk(100, function (Collection $users) {
        foreach ($users as $user) {
            // ...
        }
    });

You may stop further chunks from being processed by returning `false` from the closure:

    DB::table('users')->orderBy('id')->chunk(100, function (Collection $users) {
        // Process the records...

        return false;
    });

If you are updating database records while chunking results, your chunk results could change in unexpected ways. If you plan to update the retrieved records while chunking, it is always best to use the `chunkById` method instead. This method will automatically paginate the results based on the record's primary key:

    DB::table('users')->where('active', false)
        ->chunkById(100, function (Collection $users) {
            foreach ($users as $user) {
                DB::table('users')
                    ->where('id', $user->id)
                    ->update(['active' => true]);
            }
        });

> [!WARNING]  
> When updating or deleting records inside the chunk callback, any changes to the primary key or foreign keys could affect the chunk query. This could potentially result in records not being included in the chunked results.

<a name="streaming-results-lazily"></a>
### Streaming Results Lazily

The `lazy` method works similarly to [the `chunk` method](#chunking-results) in the sense that it executes the query in chunks. However, instead of passing each chunk into a callback, the `lazy()` method returns a [`LazyCollection`](/docs/{{version}}/collections#lazy-collections), which lets you interact with the results as a single stream:

```php
use Illuminate\Support\Facades\DB;

DB::table('users')->orderBy('id')->lazy()->each(function (object $user) {
    // ...
});
```

Once again, if you plan to update the retrieved records while iterating over them, it is best to use the `lazyById` or `lazyByIdDesc` methods instead. These methods will automatically paginate the results based on the record's primary key:

```php
DB::table('users')->where('active', false)
    ->lazyById()->each(function (object $user) {
        DB::table('users')
            ->where('id', $user->id)
            ->update(['active' => true]);
    });
```

> [!WARNING]  
> When updating or deleting records while iterating over them, any changes to the primary key or foreign keys could affect the chunk query. This could potentially result in records not being included in the results.

<a name="aggregates"></a>
### Aggregates

The query builder also provides a variety of methods for retrieving aggregate values like `count`, `max`, `min`, `avg`, and `sum`. You may call any of these methods after constructing your query:

    use Illuminate\Support\Facades\DB;

    $users = DB::table('users')->count();

    $price = DB::table('orders')->max('price');

Of course, you may combine these methods with other clauses to fine-tune how your aggregate value is calculated:

    $price = DB::table('orders')
                    ->where('finalized', 1)
                    ->avg('price');

<a name="determining-if-records-exist"></a>
#### Determining if Records Exist

Instead of using the `count` method to determine if any records exist that match your query's constraints, you may use the `exists` and `doesntExist` methods:

    if (DB::table('orders')->where('finalized', 1)->exists()) {
        // ...
    }

    if (DB::table('orders')->where('finalized', 1)->doesntExist()) {
        // ...
    }

<a name="select-statements"></a>
## Select Statements

<a name="specifying-a-select-clause"></a>
#### Specifying a Select Clause

You may not always want to select all columns from a database table. Using the `select` method, you can specify a custom "select" clause for the query:

    use Illuminate\Support\Facades\DB;

    $users = DB::table('users')
                ->select('name', 'email as user_email')
                ->get();

The `distinct` method allows you to force the query to return distinct results:

    $users = DB::table('users')->distinct()->get();

If you already have a query builder instance and you wish to add a column to its existing select clause, you may use the `addSelect` method:

    $query = DB::table('users')->select('name');

    $users = $query->addSelect('age')->get();

<a name="raw-expressions"></a>
## Raw Expressions

Sometimes you may need to insert an arbitrary string into a query. To create a raw string expression, you may use the `raw` method provided by the `DB` facade:

    $users = DB::table('users')
                 ->select(DB::raw('count(*) as user_count, status'))
                 ->where('status', '<>', 1)
                 ->groupBy('status')
                 ->get();

> [!WARNING]  
> Raw statements will be injected into the query as strings, so you should be extremely careful to avoid creating SQL injection vulnerabilities.

<a name="raw-methods"></a>
### Raw Methods

Instead of using the `DB::raw` method, you may also use the following methods to insert a raw expression into various parts of your query. **Remember, Laravel can not guarantee that any query using raw expressions is protected against SQL injection vulnerabilities.**

<a name="selectraw"></a>
#### `selectRaw`

The `selectRaw` method can be used in place of `addSelect(DB::raw(/* ... */))`. This method accepts an optional array of bindings as its second argument:

    $orders = DB::table('orders')
                    ->selectRaw('price * ? as price_with_tax', [1.0825])
                    ->get();

<a name="whereraw-orwhereraw"></a>
#### `whereRaw / orWhereRaw`

The `whereRaw` and `orWhereRaw` methods can be used to inject a raw "where" clause into your query. These methods accept an optional array of bindings as their second argument:

    $orders = DB::table('orders')
                    ->whereRaw('price > IF(state = "TX", ?, 100)', [200])
                    ->get();

<a name="havingraw-orhavingraw"></a>
#### `havingRaw / orHavingRaw`

The `havingRaw` and `orHavingRaw` methods may be used to provide a raw string as the value of the "having" clause. These methods accept an optional array of bindings as their second argument:

    $orders = DB::table('orders')
                    ->select('department', DB::raw('SUM(price) as total_sales'))
                    ->groupBy('department')
                    ->havingRaw('SUM(price) > ?', [2500])
                    ->get();

<a name="orderbyraw"></a>
#### `orderByRaw`

The `orderByRaw` method may be used to provide a raw string as the value of the "order by" clause:

    $orders = DB::table('orders')
                    ->orderByRaw('updated_at - created_at DESC')
                    ->get();

<a name="groupbyraw"></a>
### `groupByRaw`

The `groupByRaw` method may be used to provide a raw string as the value of the `group by` clause:

    $orders = DB::table('orders')
                    ->select('city', 'state')
                    ->groupByRaw('city, state')
                    ->get();

<a name="joins"></a>
## Joins

<a name="inner-join-clause"></a>
#### Inner Join Clause

The query builder may also be used to add join clauses to your queries. To perform a basic "inner join", you may use the `join` method on a query builder instance. The first argument passed to the `join` method is the name of the table you need to join to, while the remaining arguments specify the column constraints for the join. You may even join multiple tables in a single query:

    use Illuminate\Support\Facades\DB;

    $users = DB::table('users')
                ->join('contacts', 'users.id', '=', 'contacts.user_id')
                ->join('orders', 'users.id', '=', 'orders.user_id')
                ->select('users.*', 'contacts.phone', 'orders.price')
                ->get();

<a name="left-join-right-join-clause"></a>
#### Left Join / Right Join Clause

If you would like to perform a "left join" or "right join" instead of an "inner join", use the `leftJoin` or `rightJoin` methods. These methods have the same signature as the `join` method:

    $users = DB::table('users')
                ->leftJoin('posts', 'users.id', '=', 'posts.user_id')
                ->get();

    $users = DB::table('users')
                ->rightJoin('posts', 'users.id', '=', 'posts.user_id')
                ->get();

<a name="cross-join-clause"></a>
#### Cross Join Clause

You may use the `crossJoin` method to perform a "cross join". Cross joins generate a cartesian product between the first table and the joined table:

    $sizes = DB::table('sizes')
                ->crossJoin('colors')
                ->get();

<a name="advanced-join-clauses"></a>
#### Advanced Join Clauses

You may also specify more advanced join clauses. To get started, pass a closure as the second argument to the `join` method. The closure will receive a `Illuminate\Database\Query\JoinClause` instance which allows you to specify constraints on the "join" clause:

    DB::table('users')
            ->join('contacts', function (JoinClause $join) {
                $join->on('users.id', '=', 'contacts.user_id')->orOn(/* ... */);
            })
            ->get();

If you would like to use a "where" clause on your joins, you may use the `where` and `orWhere` methods provided by the `JoinClause` instance. Instead of comparing two columns, these methods will compare the column against a value:

    DB::table('users')
            ->join('contacts', function (JoinClause $join) {
                $join->on('users.id', '=', 'contacts.user_id')
                     ->where('contacts.user_id', '>', 5);
            })
            ->get();

<a name="subquery-joins"></a>
#### Subquery Joins

You may use the `joinSub`, `leftJoinSub`, and `rightJoinSub` methods to join a query to a subquery. Each of these methods receives three arguments: the subquery, its table alias, and a closure that defines the related columns. In this example, we will retrieve a collection of users where each user record also contains the `created_at` timestamp of the user's most recently published blog post:

    $latestPosts = DB::table('posts')
                       ->select('user_id', DB::raw('MAX(created_at) as last_post_created_at'))
                       ->where('is_published', true)
                       ->groupBy('user_id');

    $users = DB::table('users')
            ->joinSub($latestPosts, 'latest_posts', function (JoinClause $join) {
                $join->on('users.id', '=', 'latest_posts.user_id');
            })->get();

<a name="lateral-joins"></a>
#### Lateral Joins

> [!WARNING]  
> Lateral joins are currently supported by PostgreSQL, MySQL >= 8.0.14, and SQL Server.

You may use the `joinLateral` and `leftJoinLateral` methods to perform a "lateral join" with a subquery. Each of these methods receives two arguments: the subquery and its table alias. The join condition(s) should be specified within the `where` clause of the given subquery. Lateral joins are evaluated for each row and can reference columns outside the subquery.

In this example, we will retrieve a collection of users as well as the user's three most recent blog posts. Each user can produce up to three rows in the result set: one for each of their most recent blog posts. The join condition is specified with a `whereColumn` clause within the subquery, referencing the current user row:

    $latestPosts = DB::table('posts')
                       ->select('id as post_id', 'title as post_title', 'created_at as post_created_at')
                       ->whereColumn('user_id', 'users.id')
                       ->orderBy('created_at', 'desc')
                       ->limit(3);

    $users = DB::table('users')
                ->joinLateral($latestPosts, 'latest_posts')
                ->get();

<a name="unions"></a>
## Unions

The query builder also provides a convenient method to "union" two or more queries together. For example, you may create an initial query and use the `union` method to union it with more queries:

    use Illuminate\Support\Facades\DB;

    $first = DB::table('users')
                ->whereNull('first_name');

    $users = DB::table('users')
                ->whereNull('last_name')
                ->union($first)
                ->get();

In addition to the `union` method, the query builder provides a `unionAll` method. Queries that are combined using the `unionAll` method will not have their duplicate results removed. The `unionAll` method has the same method signature as the `union` method.

<a name="basic-where-clauses"></a>
## Basic Where Clauses

<a name="where-clauses"></a>
### Where Clauses

You may use the query builder's `where` method to add "where" clauses to the query. The most basic call to the `where` method requires three arguments. The first argument is the name of the column. The second argument is an operator, which can be any of the database's supported operators. The third argument is the value to compare against the column's value.

For example, the following query retrieves users where the value of the `votes` column is equal to `100` and the value of the `age` column is greater than `35`:

    $users = DB::table('users')
                    ->where('votes', '=', 100)
                    ->where('age', '>', 35)
                    ->get();

For convenience, if you want to verify that a column is `=` to a given value, you may pass the value as the second argument to the `where` method. Laravel will assume you would like to use the `=` operator:

    $users = DB::table('users')->where('votes', 100)->get();

As previously mentioned, you may use any operator that is supported by your database system:

    $users = DB::table('users')
                    ->where('votes', '>=', 100)
                    ->get();

    $users = DB::table('users')
                    ->where('votes', '<>', 100)
                    ->get();

    $users = DB::table('users')
                    ->where('name', 'like', 'T%')
                    ->get();

You may also pass an array of conditions to the `where` function. Each element of the array should be an array containing the three arguments typically passed to the `where` method:

    $users = DB::table('users')->where([
        ['status', '=', '1'],
        ['subscribed', '<>', '1'],
    ])->get();

> [!WARNING]  
> PDO does not support binding column names. Therefore, you should never allow user input to dictate the column names referenced by your queries, including "order by" columns.

<a name="or-where-clauses"></a>
### Or Where Clauses

When chaining together calls to the query builder's `where` method, the "where" clauses will be joined together using the `and` operator. However, you may use the `orWhere` method to join a clause to the query using the `or` operator. The `orWhere` method accepts the same arguments as the `where` method:

    $users = DB::table('users')
                        ->where('votes', '>', 100)
                        ->orWhere('name', 'John')
                        ->get();

If you need to group an "or" condition within parentheses, you may pass a closure as the first argument to the `orWhere` method:

    $users = DB::table('users')
                ->where('votes', '>', 100)
                ->orWhere(function (Builder $query) {
                    $query->where('name', 'Abigail')
                          ->where('votes', '>', 50);
                })
                ->get();

The example above will produce the following SQL:

```sql
select * from users where votes > 100 or (name = 'Abigail' and votes > 50)
```

> [!WARNING]  
> You should always group `orWhere` calls in order to avoid unexpected behavior when global scopes are applied.

<a name="where-not-clauses"></a>
### Where Not Clauses

The `whereNot` and `orWhereNot` methods may be used to negate a given group of query constraints. For example, the following query excludes products that are on clearance or which have a price that is less than ten:

    $products = DB::table('products')
                    ->whereNot(function (Builder $query) {
                        $query->where('clearance', true)
                              ->orWhere('price', '<', 10);
                    })
                    ->get();

<a name="where-any-all-clauses"></a>
### Where Any / All Clauses

Sometimes you may need to apply the same query constraints to multiple columns. For example, you may want to retrieve all records where any columns in a given list are `LIKE` a given value. You may accomplish this using the `whereAny` method:

    $users = DB::table('users')
                ->where('active', true)
                ->whereAny([
                    'name',
                    'email',
                    'phone',
                ], 'LIKE', 'Example%')
                ->get();

The query above will result in the following SQL:

```sql
SELECT *
FROM users
WHERE active = true AND (
    name LIKE 'Example%' OR
    email LIKE 'Example%' OR
    phone LIKE 'Example%'
)
```

Similarly, the `whereAll` method may be used to retrieve records where all of the given columns match a given constraint:

    $posts = DB::table('posts')
                ->where('published', true)
                ->whereAll([
                    'title',
                    'content',
                ], 'LIKE', '%Laravel%')
                ->get();

The query above will result in the following SQL:

```sql
SELECT *
FROM posts
WHERE published = true AND (
    title LIKE '%Laravel%' AND
    content LIKE '%Laravel%'
)
```

<a name="json-where-clauses"></a>
### JSON Where Clauses

Laravel also supports querying JSON column types on databases that provide support for JSON column types. Currently, this includes MySQL 5.7+, PostgreSQL, SQL Server 2016, and SQLite 3.39.0 (with the [JSON1 extension](https://www.sqlite.org/json1.html)). To query a JSON column, use the `->` operator:

    $users = DB::table('users')
                    ->where('preferences->dining->meal', 'salad')
                    ->get();

You may use `whereJsonContains` to query JSON arrays:

    $users = DB::table('users')
                    ->whereJsonContains('options->languages', 'en')
                    ->get();

If your application uses the MySQL or PostgreSQL databases, you may pass an array of values to the `whereJsonContains` method:

    $users = DB::table('users')
                    ->whereJsonContains('options->languages', ['en', 'de'])
                    ->get();

You may use `whereJsonLength` method to query JSON arrays by their length:

    $users = DB::table('users')
                    ->whereJsonLength('options->languages', 0)
                    ->get();

    $users = DB::table('users')
                    ->whereJsonLength('options->languages', '>', 1)
                    ->get();

<a name="additional-where-clauses"></a>
### Additional Where Clauses

**whereBetween / orWhereBetween**

The `whereBetween` method verifies that a column's value is between two values:

    $users = DB::table('users')
               ->whereBetween('votes', [1, 100])
               ->get();

**whereNotBetween / orWhereNotBetween**

The `whereNotBetween` method verifies that a column's value lies outside of two values:

    $users = DB::table('users')
                        ->whereNotBetween('votes', [1, 100])
                        ->get();

**whereBetweenColumns / whereNotBetweenColumns / orWhereBetweenColumns / orWhereNotBetweenColumns**

The `whereBetweenColumns` method verifies that a column's value is between the two values of two columns in the same table row:

    $patients = DB::table('patients')
                           ->whereBetweenColumns('weight', ['minimum_allowed_weight', 'maximum_allowed_weight'])
                           ->get();

The `whereNotBetweenColumns` method verifies that a column's value lies outside the two values of two columns in the same table row:

    $patients = DB::table('patients')
                           ->whereNotBetweenColumns('weight', ['minimum_allowed_weight', 'maximum_allowed_weight'])
                           ->get();

**whereIn / whereNotIn / orWhereIn / orWhereNotIn**

The `whereIn` method verifies that a given column's value is contained within the given array:

    $users = DB::table('users')
                        ->whereIn('id', [1, 2, 3])
                        ->get();

The `whereNotIn` method verifies that the given column's value is not contained in the given array:

    $users = DB::table('users')
                        ->whereNotIn('id', [1, 2, 3])
                        ->get();

You may also provide a query object as the `whereIn` method's second argument:

    $activeUsers = DB::table('users')->select('id')->where('is_active', 1);

    $users = DB::table('comments')
                        ->whereIn('user_id', $activeUsers)
                        ->get();

The example above will produce the following SQL:

```sql
select * from comments where user_id in (
    select id
    from users
    where is_active = 1
)
```

> [!WARNING]  
> If you are adding a large array of integer bindings to your query, the `whereIntegerInRaw` or `whereIntegerNotInRaw` methods may be used to greatly reduce your memory usage.

**whereNull / whereNotNull / orWhereNull / orWhereNotNull**

The `whereNull` method verifies that the value of the given column is `NULL`:

    $users = DB::table('users')
                    ->whereNull('updated_at')
                    ->get();

The `whereNotNull` method verifies that the column's value is not `NULL`:

    $users = DB::table('users')
                    ->whereNotNull('updated_at')
                    ->get();

**whereDate / whereMonth / whereDay / whereYear / whereTime**

The `whereDate` method may be used to compare a column's value against a date:

    $users = DB::table('users')
                    ->whereDate('created_at', '2016-12-31')
                    ->get();

The `whereMonth` method may be used to compare a column's value against a specific month:

    $users = DB::table('users')
                    ->whereMonth('created_at', '12')
                    ->get();

The `whereDay` method may be used to compare a column's value against a specific day of the month:

    $users = DB::table('users')
                    ->whereDay('created_at', '31')
                    ->get();

The `whereYear` method may be used to compare a column's value against a specific year:

    $users = DB::table('users')
                    ->whereYear('created_at', '2016')
                    ->get();

The `whereTime` method may be used to compare a column's value against a specific time:

    $users = DB::table('users')
                    ->whereTime('created_at', '=', '11:20:45')
                    ->get();

**whereColumn / orWhereColumn**

The `whereColumn` method may be used to verify that two columns are equal:

    $users = DB::table('users')
                    ->whereColumn('first_name', 'last_name')
                    ->get();

You may also pass a comparison operator to the `whereColumn` method:

    $users = DB::table('users')
                    ->whereColumn('updated_at', '>', 'created_at')
                    ->get();

You may also pass an array of column comparisons to the `whereColumn` method. These conditions will be joined using the `and` operator:

    $users = DB::table('users')
                    ->whereColumn([
                        ['first_name', '=', 'last_name'],
                        ['updated_at', '>', 'created_at'],
                    ])->get();

<a name="logical-grouping"></a>
### Logical Grouping

Sometimes you may need to group several "where" clauses within parentheses in order to achieve your query's desired logical grouping. In fact, you should generally always group calls to the `orWhere` method in parentheses in order to avoid unexpected query behavior. To accomplish this, you may pass a closure to the `where` method:

    $users = DB::table('users')
               ->where('name', '=', 'John')
               ->where(function (Builder $query) {
                   $query->where('votes', '>', 100)
                         ->orWhere('title', '=', 'Admin');
               })
               ->get();

As you can see, passing a closure into the `where` method instructs the query builder to begin a constraint group. The closure will receive a query builder instance which you can use to set the constraints that should be contained within the parenthesis group. The example above will produce the following SQL:

```sql
select * from users where name = 'John' and (votes > 100 or title = 'Admin')
```

> [!WARNING]  
> You should always group `orWhere` calls in order to avoid unexpected behavior when global scopes are applied.

<a name="advanced-where-clauses"></a>
### Advanced Where Clauses

<a name="where-exists-clauses"></a>
### Where Exists Clauses

The `whereExists` method allows you to write "where exists" SQL clauses. The `whereExists` method accepts a closure which will receive a query builder instance, allowing you to define the query that should be placed inside of the "exists" clause:

    $users = DB::table('users')
               ->whereExists(function (Builder $query) {
                   $query->select(DB::raw(1))
                         ->from('orders')
                         ->whereColumn('orders.user_id', 'users.id');
               })
               ->get();

Alternatively, you may provide a query object to the `whereExists` method instead of a closure:

    $orders = DB::table('orders')
                    ->select(DB::raw(1))
                    ->whereColumn('orders.user_id', 'users.id');

    $users = DB::table('users')
                        ->whereExists($orders)
                        ->get();

Both of the examples above will produce the following SQL:

```sql
select * from users
where exists (
    select 1
    from orders
    where orders.user_id = users.id
)
```

<a name="subquery-where-clauses"></a>
### Subquery Where Clauses

Sometimes you may need to construct a "where" clause that compares the results of a subquery to a given value. You may accomplish this by passing a closure and a value to the `where` method. For example, the following query will retrieve all users who have a recent "membership" of a given type;

    use App\Models\User;
    use Illuminate\Database\Query\Builder;

    $users = User::where(function (Builder $query) {
        $query->select('type')
            ->from('membership')
            ->whereColumn('membership.user_id', 'users.id')
            ->orderByDesc('membership.start_date')
            ->limit(1);
    }, 'Pro')->get();

Or, you may need to construct a "where" clause that compares a column to the results of a subquery. You may accomplish this by passing a column, operator, and closure to the `where` method. For example, the following query will retrieve all income records where the amount is less than average;

    use App\Models\Income;
    use Illuminate\Database\Query\Builder;

    $incomes = Income::where('amount', '<', function (Builder $query) {
        $query->selectRaw('avg(i.amount)')->from('incomes as i');
    })->get();

<a name="full-text-where-clauses"></a>
### Full Text Where Clauses

> [!WARNING]  
> Full text where clauses are currently supported by MySQL and PostgreSQL.

The `whereFullText` and `orWhereFullText` methods may be used to add full text "where" clauses to a query for columns that have [full text indexes](/docs/{{version}}/migrations#available-index-types). These methods will be transformed into the appropriate SQL for the underlying database system by Laravel. For example, a `MATCH AGAINST` clause will be generated for applications utilizing MySQL:

    $users = DB::table('users')
               ->whereFullText('bio', 'web developer')
               ->get();

<a name="ordering-grouping-limit-and-offset"></a>
## Ordering, Grouping, Limit and Offset

<a name="ordering"></a>
### Ordering

<a name="orderby"></a>
#### The `orderBy` Method

The `orderBy` method allows you to sort the results of the query by a given column. The first argument accepted by the `orderBy` method should be the column you wish to sort by, while the second argument determines the direction of the sort and may be either `asc` or `desc`:

    $users = DB::table('users')
                    ->orderBy('name', 'desc')
                    ->get();

To sort by multiple columns, you may simply invoke `orderBy` as many times as necessary:

    $users = DB::table('users')
                    ->orderBy('name', 'desc')
                    ->orderBy('email', 'asc')
                    ->get();

<a name="latest-oldest"></a>
#### The `latest` and `oldest` Methods

The `latest` and `oldest` methods allow you to easily order results by date. By default, the result will be ordered by the table's `created_at` column. Or, you may pass the column name that you wish to sort by:

    $user = DB::table('users')
                    ->latest()
                    ->first();

<a name="random-ordering"></a>
#### Random Ordering

The `inRandomOrder` method may be used to sort the query results randomly. For example, you may use this method to fetch a random user:

    $randomUser = DB::table('users')
                    ->inRandomOrder()
                    ->first();

<a name="removing-existing-orderings"></a>
#### Removing Existing Orderings

The `reorder` method removes all of the "order by" clauses that have previously been applied to the query:

    $query = DB::table('users')->orderBy('name');

    $unorderedUsers = $query->reorder()->get();

You may pass a column and direction when calling the `reorder` method in order to remove all existing "order by" clauses and apply an entirely new order to the query:

    $query = DB::table('users')->orderBy('name');

    $usersOrderedByEmail = $query->reorder('email', 'desc')->get();

<a name="grouping"></a>
### Grouping

<a name="groupby-having"></a>
#### The `groupBy` and `having` Methods

As you might expect, the `groupBy` and `having` methods may be used to group the query results. The `having` method's signature is similar to that of the `where` method:

    $users = DB::table('users')
                    ->groupBy('account_id')
                    ->having('account_id', '>', 100)
                    ->get();

You can use the `havingBetween` method to filter the results within a given range:

    $report = DB::table('orders')
                    ->selectRaw('count(id) as number_of_orders, customer_id')
                    ->groupBy('customer_id')
                    ->havingBetween('number_of_orders', [5, 15])
                    ->get();

You may pass multiple arguments to the `groupBy` method to group by multiple columns:

    $users = DB::table('users')
                    ->groupBy('first_name', 'status')
                    ->having('account_id', '>', 100)
                    ->get();

To build more advanced `having` statements, see the [`havingRaw`](#raw-methods) method.

<a name="limit-and-offset"></a>
### Limit and Offset

<a name="skip-take"></a>
#### The `skip` and `take` Methods

You may use the `skip` and `take` methods to limit the number of results returned from the query or to skip a given number of results in the query:

    $users = DB::table('users')->skip(10)->take(5)->get();

Alternatively, you may use the `limit` and `offset` methods. These methods are functionally equivalent to the `take` and `skip` methods, respectively:

    $users = DB::table('users')
                    ->offset(10)
                    ->limit(5)
                    ->get();

<a name="conditional-clauses"></a>
## Conditional Clauses

Sometimes you may want certain query clauses to apply to a query based on another condition. For instance, you may only want to apply a `where` statement if a given input value is present on the incoming HTTP request. You may accomplish this using the `when` method:

    $role = $request->string('role');

    $users = DB::table('users')
                    ->when($role, function (Builder $query, string $role) {
                        $query->where('role_id', $role);
                    })
                    ->get();

The `when` method only executes the given closure when the first argument is `true`. If the first argument is `false`, the closure will not be executed. So, in the example above, the closure given to the `when` method will only be invoked if the `role` field is present on the incoming request and evaluates to `true`.

You may pass another closure as the third argument to the `when` method. This closure will only execute if the first argument evaluates as `false`. To illustrate how this feature may be used, we will use it to configure the default ordering of a query:

    $sortByVotes = $request->boolean('sort_by_votes');

    $users = DB::table('users')
                    ->when($sortByVotes, function (Builder $query, bool $sortByVotes) {
                        $query->orderBy('votes');
                    }, function (Builder $query) {
                        $query->orderBy('name');
                    })
                    ->get();

<a name="insert-statements"></a>
## Insert Statements

The query builder also provides an `insert` method that may be used to insert records into the database table. The `insert` method accepts an array of column names and values:

    DB::table('users')->insert([
        'email' => 'kayla@example.com',
        'votes' => 0
    ]);

You may insert several records at once by passing an array of arrays. Each array represents a record that should be inserted into the table:

    DB::table('users')->insert([
        ['email' => 'picard@example.com', 'votes' => 0],
        ['email' => 'janeway@example.com', 'votes' => 0],
    ]);

The `insertOrIgnore` method will ignore errors while inserting records into the database. When using this method, you should be aware that duplicate record errors will be ignored and other types of errors may also be ignored depending on the database engine. For example, `insertOrIgnore` will [bypass MySQL's strict mode](https://dev.mysql.com/doc/refman/en/sql-mode.html#ignore-effect-on-execution):

    DB::table('users')->insertOrIgnore([
        ['id' => 1, 'email' => 'sisko@example.com'],
        ['id' => 2, 'email' => 'archer@example.com'],
    ]);

The `insertUsing` method will insert new records into the table while using a subquery to determine the data that should be inserted:

    DB::table('pruned_users')->insertUsing([
        'id', 'name', 'email', 'email_verified_at'
    ], DB::table('users')->select(
        'id', 'name', 'email', 'email_verified_at'
    )->where('updated_at', '<=', now()->subMonth()));

<a name="auto-incrementing-ids"></a>
#### Auto-Incrementing IDs

If the table has an auto-incrementing id, use the `insertGetId` method to insert a record and then retrieve the ID:

    $id = DB::table('users')->insertGetId(
        ['email' => 'john@example.com', 'votes' => 0]
    );

> [!WARNING]  
> When using PostgreSQL the `insertGetId` method expects the auto-incrementing column to be named `id`. If you would like to retrieve the ID from a different "sequence", you may pass the column name as the second parameter to the `insertGetId` method.

<a name="upserts"></a>
### Upserts

The `upsert` method will insert records that do not exist and update the records that already exist with new values that you may specify. The method's first argument consists of the values to insert or update, while the second argument lists the column(s) that uniquely identify records within the associated table. The method's third and final argument is an array of columns that should be updated if a matching record already exists in the database:

    DB::table('flights')->upsert(
        [
            ['departure' => 'Oakland', 'destination' => 'San Diego', 'price' => 99],
            ['departure' => 'Chicago', 'destination' => 'New York', 'price' => 150]
        ],
        ['departure', 'destination'],
        ['price']
    );

In the example above, Laravel will attempt to insert two records. If a record already exists with the same `departure` and `destination` column values, Laravel will update that record's `price` column.

> [!WARNING]  
> All databases except SQL Server require the columns in the second argument of the `upsert` method to have a "primary" or "unique" index. In addition, the MySQL database driver ignores the second argument of the `upsert` method and always uses the "primary" and "unique" indexes of the table to detect existing records.

<a name="update-statements"></a>
## Update Statements

In addition to inserting records into the database, the query builder can also update existing records using the `update` method. The `update` method, like the `insert` method, accepts an array of column and value pairs indicating the columns to be updated. The `update` method returns the number of affected rows. You may constrain the `update` query using `where` clauses:

    $affected = DB::table('users')
                  ->where('id', 1)
                  ->update(['votes' => 1]);

<a name="update-or-insert"></a>
#### Update or Insert

Sometimes you may want to update an existing record in the database or create it if no matching record exists. In this scenario, the `updateOrInsert` method may be used. The `updateOrInsert` method accepts two arguments: an array of conditions by which to find the record, and an array of column and value pairs indicating the columns to be updated.

The `updateOrInsert` method will attempt to locate a matching database record using the first argument's column and value pairs. If the record exists, it will be updated with the values in the second argument. If the record can not be found, a new record will be inserted with the merged attributes of both arguments:

    DB::table('users')
        ->updateOrInsert(
            ['email' => 'john@example.com', 'name' => 'John'],
            ['votes' => '2']
        );

<a name="updating-json-columns"></a>
### Updating JSON Columns

When updating a JSON column, you should use `->` syntax to update the appropriate key in the JSON object. This operation is supported on MySQL 5.7+ and PostgreSQL 9.5+:

    $affected = DB::table('users')
                  ->where('id', 1)
                  ->update(['options->enabled' => true]);

<a name="increment-and-decrement"></a>
### Increment and Decrement

The query builder also provides convenient methods for incrementing or decrementing the value of a given column. Both of these methods accept at least one argument: the column to modify. A second argument may be provided to specify the amount by which the column should be incremented or decremented:

    DB::table('users')->increment('votes');

    DB::table('users')->increment('votes', 5);

    DB::table('users')->decrement('votes');

    DB::table('users')->decrement('votes', 5);

If needed, you may also specify additional columns to update during the increment or decrement operation:

    DB::table('users')->increment('votes', 1, ['name' => 'John']);

In addition, you may increment or decrement multiple columns at once using the `incrementEach` and `decrementEach` methods:

    DB::table('users')->incrementEach([
        'votes' => 5,
        'balance' => 100,
    ]);

<a name="delete-statements"></a>
## Delete Statements

The query builder's `delete` method may be used to delete records from the table. The `delete` method returns the number of affected rows. You may constrain `delete` statements by adding "where" clauses before calling the `delete` method:

    $deleted = DB::table('users')->delete();

    $deleted = DB::table('users')->where('votes', '>', 100)->delete();

If you wish to truncate an entire table, which will remove all records from the table and reset the auto-incrementing ID to zero, you may use the `truncate` method:

    DB::table('users')->truncate();

<a name="table-truncation-and-postgresql"></a>
#### Table Truncation and PostgreSQL

When truncating a PostgreSQL database, the `CASCADE` behavior will be applied. This means that all foreign key related records in other tables will be deleted as well.

<a name="pessimistic-locking"></a>
## Pessimistic Locking

The query builder also includes a few functions to help you achieve "pessimistic locking" when executing your `select` statements. To execute a statement with a "shared lock", you may call the `sharedLock` method. A shared lock prevents the selected rows from being modified until your transaction is committed:

    DB::table('users')
            ->where('votes', '>', 100)
            ->sharedLock()
            ->get();

Alternatively, you may use the `lockForUpdate` method. A "for update" lock prevents the selected records from being modified or from being selected with another shared lock:

    DB::table('users')
            ->where('votes', '>', 100)
            ->lockForUpdate()
            ->get();

<a name="debugging"></a>
## Debugging

You may use the `dd` and `dump` methods while building a query to dump the current query bindings and SQL. The `dd` method will display the debug information and then stop executing the request. The `dump` method will display the debug information but allow the request to continue executing:

    DB::table('users')->where('votes', '>', 100)->dd();

    DB::table('users')->where('votes', '>', 100)->dump();

The `dumpRawSql` and `ddRawSql` methods may be invoked on a query to dump the query's SQL with all parameter bindings properly substituted:

    DB::table('users')->where('votes', '>', 100)->dumpRawSql();

    DB::table('users')->where('votes', '>', 100)->ddRawSql();



## Seeding

# Database: Seeding

- [Introduction](#introduction)
- [Writing Seeders](#writing-seeders)
    - [Using Model Factories](#using-model-factories)
    - [Calling Additional Seeders](#calling-additional-seeders)
    - [Muting Model Events](#muting-model-events)
- [Running Seeders](#running-seeders)

<a name="introduction"></a>
## Introduction

Laravel includes the ability to seed your database with data using seed classes. All seed classes are stored in the `database/seeders` directory. By default, a `DatabaseSeeder` class is defined for you. From this class, you may use the `call` method to run other seed classes, allowing you to control the seeding order.

> [!NOTE]  
> [Mass assignment protection](/docs/{{version}}/eloquent#mass-assignment) is automatically disabled during database seeding.

<a name="writing-seeders"></a>
## Writing Seeders

To generate a seeder, execute the `make:seeder` [Artisan command](/docs/{{version}}/artisan). All seeders generated by the framework will be placed in the `database/seeders` directory:

```shell
php artisan make:seeder UserSeeder
```

A seeder class only contains one method by default: `run`. This method is called when the `db:seed` [Artisan command](/docs/{{version}}/artisan) is executed. Within the `run` method, you may insert data into your database however you wish. You may use the [query builder](/docs/{{version}}/queries) to manually insert data or you may use [Eloquent model factories](/docs/{{version}}/eloquent-factories).

As an example, let's modify the default `DatabaseSeeder` class and add a database insert statement to the `run` method:

    <?php

    namespace Database\Seeders;

    use Illuminate\Database\Seeder;
    use Illuminate\Support\Facades\DB;
    use Illuminate\Support\Facades\Hash;
    use Illuminate\Support\Str;

    class DatabaseSeeder extends Seeder
    {
        /**
         * Run the database seeders.
         */
        public function run(): void
        {
            DB::table('users')->insert([
                'name' => Str::random(10),
                'email' => Str::random(10).'@example.com',
                'password' => Hash::make('password'),
            ]);
        }
    }

> [!NOTE]  
> You may type-hint any dependencies you need within the `run` method's signature. They will automatically be resolved via the Laravel [service container](/docs/{{version}}/container).

<a name="using-model-factories"></a>
### Using Model Factories

Of course, manually specifying the attributes for each model seed is cumbersome. Instead, you can use [model factories](/docs/{{version}}/eloquent-factories) to conveniently generate large amounts of database records. First, review the [model factory documentation](/docs/{{version}}/eloquent-factories) to learn how to define your factories.

For example, let's create 50 users that each has one related post:

    use App\Models\User;

    /**
     * Run the database seeders.
     */
    public function run(): void
    {
        User::factory()
                ->count(50)
                ->hasPosts(1)
                ->create();
    }

<a name="calling-additional-seeders"></a>
### Calling Additional Seeders

Within the `DatabaseSeeder` class, you may use the `call` method to execute additional seed classes. Using the `call` method allows you to break up your database seeding into multiple files so that no single seeder class becomes too large. The `call` method accepts an array of seeder classes that should be executed:

    /**
     * Run the database seeders.
     */
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
            PostSeeder::class,
            CommentSeeder::class,
        ]);
    }

<a name="muting-model-events"></a>
### Muting Model Events

While running seeds, you may want to prevent models from dispatching events. You may achieve this using the `WithoutModelEvents` trait. When used, the `WithoutModelEvents` trait ensures no model events are dispatched, even if additional seed classes are executed via the `call` method:

    <?php

    namespace Database\Seeders;

    use Illuminate\Database\Seeder;
    use Illuminate\Database\Console\Seeds\WithoutModelEvents;

    class DatabaseSeeder extends Seeder
    {
        use WithoutModelEvents;

        /**
         * Run the database seeders.
         */
        public function run(): void
        {
            $this->call([
                UserSeeder::class,
            ]);
        }
    }

<a name="running-seeders"></a>
## Running Seeders

You may execute the `db:seed` Artisan command to seed your database. By default, the `db:seed` command runs the `Database\Seeders\DatabaseSeeder` class, which may in turn invoke other seed classes. However, you may use the `--class` option to specify a specific seeder class to run individually:

```shell
php artisan db:seed

php artisan db:seed --class=UserSeeder
```

You may also seed your database using the `migrate:fresh` command in combination with the `--seed` option, which will drop all tables and re-run all of your migrations. This command is useful for completely re-building your database. The `--seeder` option may be used to specify a specific seeder to run:

```shell
php artisan migrate:fresh --seed

php artisan migrate:fresh --seed --seeder=UserSeeder 
```

<a name="forcing-seeding-production"></a>
#### Forcing Seeders to Run in Production

Some seeding operations may cause you to alter or lose data. In order to protect you from running seeding commands against your production database, you will be prompted for confirmation before the seeders are executed in the `production` environment. To force the seeders to run without a prompt, use the `--force` flag:

```shell
php artisan db:seed --force
```


