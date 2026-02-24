# Events


## Broadcasting

# Broadcasting

- [Introduction](#introduction)
- [Server Side Installation](#server-side-installation)
    - [Configuration](#configuration)
    - [Reverb](#reverb)
    - [Pusher Channels](#pusher-channels)
    - [Ably](#ably)
    - [Open Source Alternatives](#open-source-alternatives)
- [Client Side Installation](#client-side-installation)
    - [Reverb](#client-reverb)
    - [Pusher Channels](#client-pusher-channels)
    - [Ably](#client-ably)
- [Concept Overview](#concept-overview)
    - [Using an Example Application](#using-example-application)
- [Defining Broadcast Events](#defining-broadcast-events)
    - [Broadcast Name](#broadcast-name)
    - [Broadcast Data](#broadcast-data)
    - [Broadcast Queue](#broadcast-queue)
    - [Broadcast Conditions](#broadcast-conditions)
    - [Broadcasting and Database Transactions](#broadcasting-and-database-transactions)
- [Authorizing Channels](#authorizing-channels)
    - [Defining Authorization Routes](#defining-authorization-routes)
    - [Defining Authorization Callbacks](#defining-authorization-callbacks)
    - [Defining Channel Classes](#defining-channel-classes)
- [Broadcasting Events](#broadcasting-events)
    - [Only to Others](#only-to-others)
    - [Customizing the Connection](#customizing-the-connection)
- [Receiving Broadcasts](#receiving-broadcasts)
    - [Listening for Events](#listening-for-events)
    - [Leaving a Channel](#leaving-a-channel)
    - [Namespaces](#namespaces)
- [Presence Channels](#presence-channels)
    - [Authorizing Presence Channels](#authorizing-presence-channels)
    - [Joining Presence Channels](#joining-presence-channels)
    - [Broadcasting to Presence Channels](#broadcasting-to-presence-channels)
- [Model Broadcasting](#model-broadcasting)
    - [Model Broadcasting Conventions](#model-broadcasting-conventions)
    - [Listening for Model Broadcasts](#listening-for-model-broadcasts)
- [Client Events](#client-events)
- [Notifications](#notifications)

<a name="introduction"></a>
## Introduction

In many modern web applications, WebSockets are used to implement realtime, live-updating user interfaces. When some data is updated on the server, a message is typically sent over a WebSocket connection to be handled by the client. WebSockets provide a more efficient alternative to continually polling your application's server for data changes that should be reflected in your UI.

For example, imagine your application is able to export a user's data to a CSV file and email it to them. However, creating this CSV file takes several minutes so you choose to create and mail the CSV within a [queued job](/docs/{{version}}/queues). When the CSV has been created and mailed to the user, we can use event broadcasting to dispatch an `App\Events\UserDataExported` event that is received by our application's JavaScript. Once the event is received, we can display a message to the user that their CSV has been emailed to them without them ever needing to refresh the page.

To assist you in building these types of features, Laravel makes it easy to "broadcast" your server-side Laravel [events](/docs/{{version}}/events) over a WebSocket connection. Broadcasting your Laravel events allows you to share the same event names and data between your server-side Laravel application and your client-side JavaScript application.

The core concepts behind broadcasting are simple: clients connect to named channels on the frontend, while your Laravel application broadcasts events to these channels on the backend. These events can contain any additional data you wish to make available to the frontend.

<a name="supported-drivers"></a>
#### Supported Drivers

By default, Laravel includes three server-side broadcasting drivers for you to choose from: [Laravel Reverb](https://reverb.laravel.com), [Pusher Channels](https://pusher.com/channels), and [Ably](https://ably.com).

> [!NOTE]  
> Before diving into event broadcasting, make sure you have read Laravel's documentation on [events and listeners](/docs/{{version}}/events).

<a name="server-side-installation"></a>
## Server Side Installation

To get started using Laravel's event broadcasting, we need to do some configuration within the Laravel application as well as install a few packages.

Event broadcasting is accomplished by a server-side broadcasting driver that broadcasts your Laravel events so that Laravel Echo (a JavaScript library) can receive them within the browser client. Don't worry - we'll walk through each part of the installation process step-by-step.

<a name="configuration"></a>
### Configuration

All of your application's event broadcasting configuration is stored in the `config/broadcasting.php` configuration file. Laravel supports several broadcast drivers out of the box: [Pusher Channels](https://pusher.com/channels), [Redis](/docs/{{version}}/redis), and a `log` driver for local development and debugging. Additionally, a `null` driver is included which allows you to totally disable broadcasting during testing. A configuration example is included for each of these drivers in the `config/broadcasting.php` configuration file.

<a name="broadcast-service-provider"></a>
#### Broadcast Service Provider

Before broadcasting any events, you will first need to register the `App\Providers\BroadcastServiceProvider`. In new Laravel applications, you only need to uncomment this provider in the `providers` array of your `config/app.php` configuration file. This `BroadcastServiceProvider` contains the code necessary to register the broadcast authorization routes and callbacks.

<a name="queue-configuration"></a>
#### Queue Configuration

You will also need to configure and run a [queue worker](/docs/{{version}}/queues). All event broadcasting is done via queued jobs so that the response time of your application is not seriously affected by events being broadcast.

<a name="reverb"></a>
### Reverb

You may install Reverb using the Composer package manager:

```sh
composer require laravel/reverb
```

Once the package is installed, you may run Reverb's installation command to publish the configuration, update your applications's broadcasting configuration, and add Reverb's required environment variables:

```sh
php artisan reverb:install
```

You can find detailed Reverb installation and usage instructions in the [Reverb documentation](/docs/{{version}}/reverb).

<a name="pusher-channels"></a>
### Pusher Channels

If you plan to broadcast your events using [Pusher Channels](https://pusher.com/channels), you should install the Pusher Channels PHP SDK using the Composer package manager:

```shell
composer require pusher/pusher-php-server
```

Next, you should configure your Pusher Channels credentials in the `config/broadcasting.php` configuration file. An example Pusher Channels configuration is already included in this file, allowing you to quickly specify your key, secret, and application ID. Typically, these values should be set via the `PUSHER_APP_KEY`, `PUSHER_APP_SECRET`, and `PUSHER_APP_ID` [environment variables](/docs/{{version}}/configuration#environment-configuration):

```ini
PUSHER_APP_ID=your-pusher-app-id
PUSHER_APP_KEY=your-pusher-key
PUSHER_APP_SECRET=your-pusher-secret
PUSHER_APP_CLUSTER=mt1
```

The `config/broadcasting.php` file's `pusher` configuration also allows you to specify additional `options` that are supported by Channels, such as the cluster.

Next, you will need to change your broadcast driver to `pusher` in your `.env` file:

```ini
BROADCAST_DRIVER=pusher
```

Finally, you are ready to install and configure [Laravel Echo](#client-side-installation), which will receive the broadcast events on the client-side.

<a name="pusher-compatible-open-source-alternatives"></a>
#### Open Source Pusher Alternatives

[soketi](https://docs.soketi.app/) provides a Pusher compatible WebSocket server for Laravel, allowing you to leverage the full power of Laravel broadcasting without a commercial WebSocket provider. For more information on installing and using open source packages for broadcasting, please consult our documentation on [open source alternatives](#open-source-alternatives).

<a name="ably"></a>
### Ably

> [!NOTE]  
> The documentation below discusses how to use Ably in "Pusher compatibility" mode. However, the Ably team recommends and maintains a broadcaster and Echo client that is able to take advantage of the unique capabilities offered by Ably. For more information on using the Ably maintained drivers, please [consult Ably's Laravel broadcaster documentation](https://github.com/ably/laravel-broadcaster).

If you plan to broadcast your events using [Ably](https://ably.com), you should install the Ably PHP SDK using the Composer package manager:

```shell
composer require ably/ably-php
```

Next, you should configure your Ably credentials in the `config/broadcasting.php` configuration file. An example Ably configuration is already included in this file, allowing you to quickly specify your key. Typically, this value should be set via the `ABLY_KEY` [environment variable](/docs/{{version}}/configuration#environment-configuration):

```ini
ABLY_KEY=your-ably-key
```

Next, you will need to change your broadcast driver to `ably` in your `.env` file:

```ini
BROADCAST_DRIVER=ably
```

Finally, you are ready to install and configure [Laravel Echo](#client-side-installation), which will receive the broadcast events on the client-side.

<a name="open-source-alternatives"></a>
### Open Source Alternatives

<a name="open-source-alternatives-node"></a>
#### Node

[Soketi](https://github.com/soketi/soketi) is a Node based, Pusher compatible WebSocket server for Laravel. Under the hood, Soketi utilizes µWebSockets.js for extreme scalability and speed. This package allows you to leverage the full power of Laravel broadcasting without a commercial WebSocket provider. For more information on installing and using this package, please consult its [official documentation](https://docs.soketi.app/).

<a name="client-side-installation"></a>
## Client Side Installation

<a name="client-reverb"></a>
### Reverb

[Laravel Echo](https://github.com/laravel/echo) is a JavaScript library that makes it painless to subscribe to channels and listen for events broadcast by your server-side broadcasting driver. You may install Echo via the NPM package manager. In this example, we will also install the `pusher-js` package since Reverb utilizes the Pusher protocol for WebSocket subscriptions, channels, and messages:

```shell
npm install --save-dev laravel-echo pusher-js
```

Once Echo is installed, you are ready to create a fresh Echo instance in your application's JavaScript. A great place to do this is at the bottom of the `resources/js/bootstrap.js` file that is included with the Laravel framework. By default, an example Echo configuration is already included in this file - you simply need to uncomment it and update the `broadcaster` configuration option to `reverb`:

```js
import Echo from 'laravel-echo';

import Pusher from 'pusher-js';
window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST,
    wsPort: import.meta.env.VITE_REVERB_PORT,
    wssPort: import.meta.env.VITE_REVERB_PORT,
    forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'https') === 'https',
    enabledTransports: ['ws', 'wss'],
});
```

Next, you should compile your application's assets:

```shell
npm run build
```

> [!WARNING]  
> The Laravel Echo `reverb` broadcaster requires laravel-echo v1.16.0+.

<a name="client-pusher-channels"></a>
### Pusher Channels

[Laravel Echo](https://github.com/laravel/echo) is a JavaScript library that makes it painless to subscribe to channels and listen for events broadcast by your server-side broadcasting driver. You may install Echo via the NPM package manager. In this example, we will also install the `pusher-js` package since we will be using the Pusher Channels broadcaster:

```shell
npm install --save-dev laravel-echo pusher-js
```

Once Echo is installed, you are ready to create a fresh Echo instance in your application's JavaScript. A great place to do this is at the bottom of the `resources/js/bootstrap.js` file that is included with the Laravel framework. By default, an example Echo configuration is already included in this file - you simply need to uncomment it:

```js
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: 'pusher',
    key: import.meta.env.VITE_PUSHER_APP_KEY,
    cluster: import.meta.env.VITE_PUSHER_APP_CLUSTER,
    forceTLS: true
});
```

Once you have uncommented and adjusted the Echo configuration according to your needs, you may compile your application's assets:

```shell
npm run build
```

> [!NOTE]  
> To learn more about compiling your application's JavaScript assets, please consult the documentation on [Vite](/docs/{{version}}/vite).

<a name="using-an-existing-client-instance"></a>
#### Using an Existing Client Instance

If you already have a pre-configured Pusher Channels client instance that you would like Echo to utilize, you may pass it to Echo via the `client` configuration option:

```js
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

const options = {
    broadcaster: 'pusher',
    key: 'your-pusher-channels-key'
}

window.Echo = new Echo({
    ...options,
    client: new Pusher(options.key, options)
});
```

<a name="client-ably"></a>
### Ably

> [!NOTE]  
> The documentation below discusses how to use Ably in "Pusher compatibility" mode. However, the Ably team recommends and maintains a broadcaster and Echo client that is able to take advantage of the unique capabilities offered by Ably. For more information on using the Ably maintained drivers, please [consult Ably's Laravel broadcaster documentation](https://github.com/ably/laravel-broadcaster).

[Laravel Echo](https://github.com/laravel/echo) is a JavaScript library that makes it painless to subscribe to channels and listen for events broadcast by your server-side broadcasting driver. You may install Echo via the NPM package manager. In this example, we will also install the `pusher-js` package.

You may wonder why we would install the `pusher-js` JavaScript library even though we are using Ably to broadcast our events. Thankfully, Ably includes a Pusher compatibility mode which lets us use the Pusher protocol when listening for events in our client-side application:

```shell
npm install --save-dev laravel-echo pusher-js
```

**Before continuing, you should enable Pusher protocol support in your Ably application settings. You may enable this feature within the "Protocol Adapter Settings" portion of your Ably application's settings dashboard.**

Once Echo is installed, you are ready to create a fresh Echo instance in your application's JavaScript. A great place to do this is at the bottom of the `resources/js/bootstrap.js` file that is included with the Laravel framework. By default, an example Echo configuration is already included in this file; however, the default configuration in the `bootstrap.js` file is intended for Pusher. You may copy the configuration below to transition your configuration to Ably:

```js
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: 'pusher',
    key: import.meta.env.VITE_ABLY_PUBLIC_KEY,
    wsHost: 'realtime-pusher.ably.io',
    wsPort: 443,
    disableStats: true,
    encrypted: true,
});
```

Note that our Ably Echo configuration references a `VITE_ABLY_PUBLIC_KEY` environment variable. This variable's value should be your Ably public key. Your public key is the portion of your Ably key that occurs before the `:` character.

Once you have uncommented and adjusted the Echo configuration according to your needs, you may compile your application's assets:

```shell
npm run dev
```

> [!NOTE]  
> To learn more about compiling your application's JavaScript assets, please consult the documentation on [Vite](/docs/{{version}}/vite).

<a name="concept-overview"></a>
## Concept Overview

Laravel's event broadcasting allows you to broadcast your server-side Laravel events to your client-side JavaScript application using a driver-based approach to WebSockets. Currently, Laravel ships with [Pusher Channels](https://pusher.com/channels) and [Ably](https://ably.com) drivers. The events may be easily consumed on the client-side using the [Laravel Echo](#client-side-installation) JavaScript package.

Events are broadcast over "channels", which may be specified as public or private. Any visitor to your application may subscribe to a public channel without any authentication or authorization; however, in order to subscribe to a private channel, a user must be authenticated and authorized to listen on that channel.

> [!NOTE]  
> If you would like to explore open source alternatives to Pusher, check out the [open source alternatives](#open-source-alternatives).

<a name="using-example-application"></a>
### Using an Example Application

Before diving into each component of event broadcasting, let's take a high level overview using an e-commerce store as an example.

In our application, let's assume we have a page that allows users to view the shipping status for their orders. Let's also assume that an `OrderShipmentStatusUpdated` event is fired when a shipping status update is processed by the application:

    use App\Events\OrderShipmentStatusUpdated;

    OrderShipmentStatusUpdated::dispatch($order);

<a name="the-shouldbroadcast-interface"></a>
#### The `ShouldBroadcast` Interface

When a user is viewing one of their orders, we don't want them to have to refresh the page to view status updates. Instead, we want to broadcast the updates to the application as they are created. So, we need to mark the `OrderShipmentStatusUpdated` event with the `ShouldBroadcast` interface. This will instruct Laravel to broadcast the event when it is fired:

    <?php

    namespace App\Events;

    use App\Models\Order;
    use Illuminate\Broadcasting\Channel;
    use Illuminate\Broadcasting\InteractsWithSockets;
    use Illuminate\Broadcasting\PresenceChannel;
    use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
    use Illuminate\Queue\SerializesModels;

    class OrderShipmentStatusUpdated implements ShouldBroadcast
    {
        /**
         * The order instance.
         *
         * @var \App\Models\Order
         */
        public $order;
    }

The `ShouldBroadcast` interface requires our event to define a `broadcastOn` method. This method is responsible for returning the channels that the event should broadcast on. An empty stub of this method is already defined on generated event classes, so we only need to fill in its details. We only want the creator of the order to be able to view status updates, so we will broadcast the event on a private channel that is tied to the order:

    use Illuminate\Broadcasting\Channel;
    use Illuminate\Broadcasting\PrivateChannel;

    /**
     * Get the channel the event should broadcast on.
     */
    public function broadcastOn(): Channel
    {
        return new PrivateChannel('orders.'.$this->order->id);
    }

If you wish the event to broadcast on multiple channels, you may return an `array` instead:

    use Illuminate\Broadcasting\PrivateChannel;

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('orders.'.$this->order->id),
            // ...
        ];
    }

<a name="example-application-authorizing-channels"></a>
#### Authorizing Channels

Remember, users must be authorized to listen on private channels. We may define our channel authorization rules in our application's `routes/channels.php` file. In this example, we need to verify that any user attempting to listen on the private `orders.1` channel is actually the creator of the order:

    use App\Models\Order;
    use App\Models\User;

    Broadcast::channel('orders.{orderId}', function (User $user, int $orderId) {
        return $user->id === Order::findOrNew($orderId)->user_id;
    });

The `channel` method accepts two arguments: the name of the channel and a callback which returns `true` or `false` indicating whether the user is authorized to listen on the channel.

All authorization callbacks receive the currently authenticated user as their first argument and any additional wildcard parameters as their subsequent arguments. In this example, we are using the `{orderId}` placeholder to indicate that the "ID" portion of the channel name is a wildcard.

<a name="listening-for-event-broadcasts"></a>
#### Listening for Event Broadcasts

Next, all that remains is to listen for the event in our JavaScript application. We can do this using [Laravel Echo](#client-side-installation). First, we'll use the `private` method to subscribe to the private channel. Then, we may use the `listen` method to listen for the `OrderShipmentStatusUpdated` event. By default, all of the event's public properties will be included on the broadcast event:

```js
Echo.private(`orders.${orderId}`)
    .listen('OrderShipmentStatusUpdated', (e) => {
        console.log(e.order);
    });
```

<a name="defining-broadcast-events"></a>
## Defining Broadcast Events

To inform Laravel that a given event should be broadcast, you must implement the `Illuminate\Contracts\Broadcasting\ShouldBroadcast` interface on the event class. This interface is already imported into all event classes generated by the framework so you may easily add it to any of your events.

The `ShouldBroadcast` interface requires you to implement a single method: `broadcastOn`. The `broadcastOn` method should return a channel or array of channels that the event should broadcast on. The channels should be instances of `Channel`, `PrivateChannel`, or `PresenceChannel`. Instances of `Channel` represent public channels that any user may subscribe to, while `PrivateChannels` and `PresenceChannels` represent private channels that require [channel authorization](#authorizing-channels):

    <?php

    namespace App\Events;

    use App\Models\User;
    use Illuminate\Broadcasting\Channel;
    use Illuminate\Broadcasting\InteractsWithSockets;
    use Illuminate\Broadcasting\PresenceChannel;
    use Illuminate\Broadcasting\PrivateChannel;
    use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
    use Illuminate\Queue\SerializesModels;

    class ServerCreated implements ShouldBroadcast
    {
        use SerializesModels;

        /**
         * Create a new event instance.
         */
        public function __construct(
            public User $user,
        ) {}

        /**
         * Get the channels the event should broadcast on.
         *
         * @return array<int, \Illuminate\Broadcasting\Channel>
         */
        public function broadcastOn(): array
        {
            return [
                new PrivateChannel('user.'.$this->user->id),
            ];
        }
    }

After implementing the `ShouldBroadcast` interface, you only need to [fire the event](/docs/{{version}}/events) as you normally would. Once the event has been fired, a [queued job](/docs/{{version}}/queues) will automatically broadcast the event using your specified broadcast driver.

<a name="broadcast-name"></a>
### Broadcast Name

By default, Laravel will broadcast the event using the event's class name. However, you may customize the broadcast name by defining a `broadcastAs` method on the event:

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'server.created';
    }

If you customize the broadcast name using the `broadcastAs` method, you should make sure to register your listener with a leading `.` character. This will instruct Echo to not prepend the application's namespace to the event:

    .listen('.server.created', function (e) {
        ....
    });

<a name="broadcast-data"></a>
### Broadcast Data

When an event is broadcast, all of its `public` properties are automatically serialized and broadcast as the event's payload, allowing you to access any of its public data from your JavaScript application. So, for example, if your event has a single public `$user` property that contains an Eloquent model, the event's broadcast payload would be:

```json
{
    "user": {
        "id": 1,
        "name": "Patrick Stewart"
        ...
    }
}
```

However, if you wish to have more fine-grained control over your broadcast payload, you may add a `broadcastWith` method to your event. This method should return the array of data that you wish to broadcast as the event payload:

    /**
     * Get the data to broadcast.
     *
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return ['id' => $this->user->id];
    }

<a name="broadcast-queue"></a>
### Broadcast Queue

By default, each broadcast event is placed on the default queue for the default queue connection specified in your `queue.php` configuration file. You may customize the queue connection and name used by the broadcaster by defining `connection` and `queue` properties on your event class:

    /**
     * The name of the queue connection to use when broadcasting the event.
     *
     * @var string
     */
    public $connection = 'redis';

    /**
     * The name of the queue on which to place the broadcasting job.
     *
     * @var string
     */
    public $queue = 'default';

Alternatively, you may customize the queue name by defining a `broadcastQueue` method on your event:

    /**
     * The name of the queue on which to place the broadcasting job.
     */
    public function broadcastQueue(): string
    {
        return 'default';
    }

If you would like to broadcast your event using the `sync` queue instead of the default queue driver, you can implement the `ShouldBroadcastNow` interface instead of `ShouldBroadcast`:

    <?php

    use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

    class OrderShipmentStatusUpdated implements ShouldBroadcastNow
    {
        // ...
    }

<a name="broadcast-conditions"></a>
### Broadcast Conditions

Sometimes you want to broadcast your event only if a given condition is true. You may define these conditions by adding a `broadcastWhen` method to your event class:

    /**
     * Determine if this event should broadcast.
     */
    public function broadcastWhen(): bool
    {
        return $this->order->value > 100;
    }

<a name="broadcasting-and-database-transactions"></a>
#### Broadcasting and Database Transactions

When broadcast events are dispatched within database transactions, they may be processed by the queue before the database transaction has committed. When this happens, any updates you have made to models or database records during the database transaction may not yet be reflected in the database. In addition, any models or database records created within the transaction may not exist in the database. If your event depends on these models, unexpected errors can occur when the job that broadcasts the event is processed.

If your queue connection's `after_commit` configuration option is set to `false`, you may still indicate that a particular broadcast event should be dispatched after all open database transactions have been committed by implementing the `ShouldDispatchAfterCommit` interface on the event class:

    <?php

    namespace App\Events;

    use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
    use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
    use Illuminate\Queue\SerializesModels;

    class ServerCreated implements ShouldBroadcast, ShouldDispatchAfterCommit
    {
        use SerializesModels;
    }

> [!NOTE]  
> To learn more about working around these issues, please review the documentation regarding [queued jobs and database transactions](/docs/{{version}}/queues#jobs-and-database-transactions).

<a name="authorizing-channels"></a>
## Authorizing Channels

Private channels require you to authorize that the currently authenticated user can actually listen on the channel. This is accomplished by making an HTTP request to your Laravel application with the channel name and allowing your application to determine if the user can listen on that channel. When using [Laravel Echo](#client-side-installation), the HTTP request to authorize subscriptions to private channels will be made automatically; however, you do need to define the proper routes to respond to these requests.

<a name="defining-authorization-routes"></a>
### Defining Authorization Routes

Thankfully, Laravel makes it easy to define the routes to respond to channel authorization requests. In the `App\Providers\BroadcastServiceProvider` included with your Laravel application, you will see a call to the `Broadcast::routes` method. This method will register the `/broadcasting/auth` route to handle authorization requests:

    Broadcast::routes();

The `Broadcast::routes` method will automatically place its routes within the `web` middleware group; however, you may pass an array of route attributes to the method if you would like to customize the assigned attributes:

    Broadcast::routes($attributes);

<a name="customizing-the-authorization-endpoint"></a>
#### Customizing the Authorization Endpoint

By default, Echo will use the `/broadcasting/auth` endpoint to authorize channel access. However, you may specify your own authorization endpoint by passing the `authEndpoint` configuration option to your Echo instance:

```js
window.Echo = new Echo({
    broadcaster: 'pusher',
    // ...
    authEndpoint: '/custom/endpoint/auth'
});
```

<a name="customizing-the-authorization-request"></a>
#### Customizing the Authorization Request

You can customize how Laravel Echo performs authorization requests by providing a custom authorizer when initializing Echo:

```js
window.Echo = new Echo({
    // ...
    authorizer: (channel, options) => {
        return {
            authorize: (socketId, callback) => {
                axios.post('/api/broadcasting/auth', {
                    socket_id: socketId,
                    channel_name: channel.name
                })
                .then(response => {
                    callback(null, response.data);
                })
                .catch(error => {
                    callback(error);
                });
            }
        };
    },
})
```

<a name="defining-authorization-callbacks"></a>
### Defining Authorization Callbacks

Next, we need to define the logic that will actually determine if the currently authenticated user can listen to a given channel. This is done in the `routes/channels.php` file that is included with your application. In this file, you may use the `Broadcast::channel` method to register channel authorization callbacks:

    use App\Models\User;

    Broadcast::channel('orders.{orderId}', function (User $user, int $orderId) {
        return $user->id === Order::findOrNew($orderId)->user_id;
    });

The `channel` method accepts two arguments: the name of the channel and a callback which returns `true` or `false` indicating whether the user is authorized to listen on the channel.

All authorization callbacks receive the currently authenticated user as their first argument and any additional wildcard parameters as their subsequent arguments. In this example, we are using the `{orderId}` placeholder to indicate that the "ID" portion of the channel name is a wildcard.

You may view a list of your application's broadcast authorization callbacks using the `channel:list` Artisan command:

```shell
php artisan channel:list
```

<a name="authorization-callback-model-binding"></a>
#### Authorization Callback Model Binding

Just like HTTP routes, channel routes may also take advantage of implicit and explicit [route model binding](/docs/{{version}}/routing#route-model-binding). For example, instead of receiving a string or numeric order ID, you may request an actual `Order` model instance:

    use App\Models\Order;
    use App\Models\User;

    Broadcast::channel('orders.{order}', function (User $user, Order $order) {
        return $user->id === $order->user_id;
    });

> [!WARNING]  
> Unlike HTTP route model binding, channel model binding does not support automatic [implicit model binding scoping](/docs/{{version}}/routing#implicit-model-binding-scoping). However, this is rarely a problem because most channels can be scoped based on a single model's unique, primary key.

<a name="authorization-callback-authentication"></a>
#### Authorization Callback Authentication

Private and presence broadcast channels authenticate the current user via your application's default authentication guard. If the user is not authenticated, channel authorization is automatically denied and the authorization callback is never executed. However, you may assign multiple, custom guards that should authenticate the incoming request if necessary:

    Broadcast::channel('channel', function () {
        // ...
    }, ['guards' => ['web', 'admin']]);

<a name="defining-channel-classes"></a>
### Defining Channel Classes

If your application is consuming many different channels, your `routes/channels.php` file could become bulky. So, instead of using closures to authorize channels, you may use channel classes. To generate a channel class, use the `make:channel` Artisan command. This command will place a new channel class in the `App/Broadcasting` directory.

```shell
php artisan make:channel OrderChannel
```

Next, register your channel in your `routes/channels.php` file:

    use App\Broadcasting\OrderChannel;

    Broadcast::channel('orders.{order}', OrderChannel::class);

Finally, you may place the authorization logic for your channel in the channel class' `join` method. This `join` method will house the same logic you would have typically placed in your channel authorization closure. You may also take advantage of channel model binding:

    <?php

    namespace App\Broadcasting;

    use App\Models\Order;
    use App\Models\User;

    class OrderChannel
    {
        /**
         * Create a new channel instance.
         */
        public function __construct()
        {
            // ...
        }

        /**
         * Authenticate the user's access to the channel.
         */
        public function join(User $user, Order $order): array|bool
        {
            return $user->id === $order->user_id;
        }
    }

> [!NOTE]  
> Like many other classes in Laravel, channel classes will automatically be resolved by the [service container](/docs/{{version}}/container). So, you may type-hint any dependencies required by your channel in its constructor.

<a name="broadcasting-events"></a>
## Broadcasting Events

Once you have defined an event and marked it with the `ShouldBroadcast` interface, you only need to fire the event using the event's dispatch method. The event dispatcher will notice that the event is marked with the `ShouldBroadcast` interface and will queue the event for broadcasting:

    use App\Events\OrderShipmentStatusUpdated;

    OrderShipmentStatusUpdated::dispatch($order);

<a name="only-to-others"></a>
### Only to Others

When building an application that utilizes event broadcasting, you may occasionally need to broadcast an event to all subscribers to a given channel except for the current user. You may accomplish this using the `broadcast` helper and the `toOthers` method:

    use App\Events\OrderShipmentStatusUpdated;

    broadcast(new OrderShipmentStatusUpdated($update))->toOthers();

To better understand when you may want to use the `toOthers` method, let's imagine a task list application where a user may create a new task by entering a task name. To create a task, your application might make a request to a `/task` URL which broadcasts the task's creation and returns a JSON representation of the new task. When your JavaScript application receives the response from the end-point, it might directly insert the new task into its task list like so:

```js
axios.post('/task', task)
    .then((response) => {
        this.tasks.push(response.data);
    });
```

However, remember that we also broadcast the task's creation. If your JavaScript application is also listening for this event in order to add tasks to the task list, you will have duplicate tasks in your list: one from the end-point and one from the broadcast. You may solve this by using the `toOthers` method to instruct the broadcaster to not broadcast the event to the current user.

> [!WARNING]  
> Your event must use the `Illuminate\Broadcasting\InteractsWithSockets` trait in order to call the `toOthers` method.

<a name="only-to-others-configuration"></a>
#### Configuration

When you initialize a Laravel Echo instance, a socket ID is assigned to the connection. If you are using a global [Axios](https://github.com/mzabriskie/axios) instance to make HTTP requests from your JavaScript application, the socket ID will automatically be attached to every outgoing request as an `X-Socket-ID` header. Then, when you call the `toOthers` method, Laravel will extract the socket ID from the header and instruct the broadcaster to not broadcast to any connections with that socket ID.

If you are not using a global Axios instance, you will need to manually configure your JavaScript application to send the `X-Socket-ID` header with all outgoing requests. You may retrieve the socket ID using the `Echo.socketId` method:

```js
var socketId = Echo.socketId();
```

<a name="customizing-the-connection"></a>
### Customizing the Connection

If your application interacts with multiple broadcast connections and you want to broadcast an event using a broadcaster other than your default, you may specify which connection to push an event to using the `via` method:

    use App\Events\OrderShipmentStatusUpdated;

    broadcast(new OrderShipmentStatusUpdated($update))->via('pusher');

Alternatively, you may specify the event's broadcast connection by calling the `broadcastVia` method within the event's constructor. However, before doing so, you should ensure that the event class uses the `InteractsWithBroadcasting` trait:

    <?php

    namespace App\Events;

    use Illuminate\Broadcasting\Channel;
    use Illuminate\Broadcasting\InteractsWithBroadcasting;
    use Illuminate\Broadcasting\InteractsWithSockets;
    use Illuminate\Broadcasting\PresenceChannel;
    use Illuminate\Broadcasting\PrivateChannel;
    use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
    use Illuminate\Queue\SerializesModels;

    class OrderShipmentStatusUpdated implements ShouldBroadcast
    {
        use InteractsWithBroadcasting;

        /**
         * Create a new event instance.
         */
        public function __construct()
        {
            $this->broadcastVia('pusher');
        }
    }

<a name="receiving-broadcasts"></a>
## Receiving Broadcasts

<a name="listening-for-events"></a>
### Listening for Events

Once you have [installed and instantiated Laravel Echo](#client-side-installation), you are ready to start listening for events that are broadcast from your Laravel application. First, use the `channel` method to retrieve an instance of a channel, then call the `listen` method to listen for a specified event:

```js
Echo.channel(`orders.${this.order.id}`)
    .listen('OrderShipmentStatusUpdated', (e) => {
        console.log(e.order.name);
    });
```

If you would like to listen for events on a private channel, use the `private` method instead. You may continue to chain calls to the `listen` method to listen for multiple events on a single channel:

```js
Echo.private(`orders.${this.order.id}`)
    .listen(/* ... */)
    .listen(/* ... */)
    .listen(/* ... */);
```

<a name="stop-listening-for-events"></a>
#### Stop Listening for Events

If you would like to stop listening to a given event without [leaving the channel](#leaving-a-channel), you may use the `stopListening` method:

```js
Echo.private(`orders.${this.order.id}`)
    .stopListening('OrderShipmentStatusUpdated')
```

<a name="leaving-a-channel"></a>
### Leaving a Channel

To leave a channel, you may call the `leaveChannel` method on your Echo instance:

```js
Echo.leaveChannel(`orders.${this.order.id}`);
```

If you would like to leave a channel and also its associated private and presence channels, you may call the `leave` method:

```js
Echo.leave(`orders.${this.order.id}`);
```
<a name="namespaces"></a>
### Namespaces

You may have noticed in the examples above that we did not specify the full `App\Events` namespace for the event classes. This is because Echo will automatically assume the events are located in the `App\Events` namespace. However, you may configure the root namespace when you instantiate Echo by passing a `namespace` configuration option:

```js
window.Echo = new Echo({
    broadcaster: 'pusher',
    // ...
    namespace: 'App.Other.Namespace'
});
```

Alternatively, you may prefix event classes with a `.` when subscribing to them using Echo. This will allow you to always specify the fully-qualified class name:

```js
Echo.channel('orders')
    .listen('.Namespace\\Event\\Class', (e) => {
        // ...
    });
```

<a name="presence-channels"></a>
## Presence Channels

Presence channels build on the security of private channels while exposing the additional feature of awareness of who is subscribed to the channel. This makes it easy to build powerful, collaborative application features such as notifying users when another user is viewing the same page or listing the inhabitants of a chat room.

<a name="authorizing-presence-channels"></a>
### Authorizing Presence Channels

All presence channels are also private channels; therefore, users must be [authorized to access them](#authorizing-channels). However, when defining authorization callbacks for presence channels, you will not return `true` if the user is authorized to join the channel. Instead, you should return an array of data about the user.

The data returned by the authorization callback will be made available to the presence channel event listeners in your JavaScript application. If the user is not authorized to join the presence channel, you should return `false` or `null`:

    use App\Models\User;

    Broadcast::channel('chat.{roomId}', function (User $user, int $roomId) {
        if ($user->canJoinRoom($roomId)) {
            return ['id' => $user->id, 'name' => $user->name];
        }
    });

<a name="joining-presence-channels"></a>
### Joining Presence Channels

To join a presence channel, you may use Echo's `join` method. The `join` method will return a `PresenceChannel` implementation which, along with exposing the `listen` method, allows you to subscribe to the `here`, `joining`, and `leaving` events.

```js
Echo.join(`chat.${roomId}`)
    .here((users) => {
        // ...
    })
    .joining((user) => {
        console.log(user.name);
    })
    .leaving((user) => {
        console.log(user.name);
    })
    .error((error) => {
        console.error(error);
    });
```

The `here` callback will be executed immediately once the channel is joined successfully, and will receive an array containing the user information for all of the other users currently subscribed to the channel. The `joining` method will be executed when a new user joins a channel, while the `leaving` method will be executed when a user leaves the channel. The `error` method will be executed when the authentication endpoint returns an HTTP status code other than 200 or if there is a problem parsing the returned JSON.

<a name="broadcasting-to-presence-channels"></a>
### Broadcasting to Presence Channels

Presence channels may receive events just like public or private channels. Using the example of a chatroom, we may want to broadcast `NewMessage` events to the room's presence channel. To do so, we'll return an instance of `PresenceChannel` from the event's `broadcastOn` method:

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new PresenceChannel('chat.'.$this->message->room_id),
        ];
    }

As with other events, you may use the `broadcast` helper and the `toOthers` method to exclude the current user from receiving the broadcast:

    broadcast(new NewMessage($message));

    broadcast(new NewMessage($message))->toOthers();

As typical of other types of events, you may listen for events sent to presence channels using Echo's `listen` method:

```js
Echo.join(`chat.${roomId}`)
    .here(/* ... */)
    .joining(/* ... */)
    .leaving(/* ... */)
    .listen('NewMessage', (e) => {
        // ...
    });
```

<a name="model-broadcasting"></a>
## Model Broadcasting

> [!WARNING]  
> Before reading the following documentation about model broadcasting, we recommend you become familiar with the general concepts of Laravel's model broadcasting services as well as how to manually create and listen to broadcast events.

It is common to broadcast events when your application's [Eloquent models](/docs/{{version}}/eloquent) are created, updated, or deleted. Of course, this can easily be accomplished by manually [defining custom events for Eloquent model state changes](/docs/{{version}}/eloquent#events) and marking those events with the `ShouldBroadcast` interface.

However, if you are not using these events for any other purposes in your application, it can be cumbersome to create event classes for the sole purpose of broadcasting them. To remedy this, Laravel allows you to indicate that an Eloquent model should automatically broadcast its state changes.

To get started, your Eloquent model should use the `Illuminate\Database\Eloquent\BroadcastsEvents` trait. In addition, the model should define a `broadcastOn` method, which will return an array of channels that the model's events should broadcast on:

```php
<?php

namespace App\Models;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Database\Eloquent\BroadcastsEvents;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Post extends Model
{
    use BroadcastsEvents, HasFactory;

    /**
     * Get the user that the post belongs to.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the channels that model events should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel|\Illuminate\Database\Eloquent\Model>
     */
    public function broadcastOn(string $event): array
    {
        return [$this, $this->user];
    }
}
```

Once your model includes this trait and defines its broadcast channels, it will begin automatically broadcasting events when a model instance is created, updated, deleted, trashed, or restored.

In addition, you may have noticed that the `broadcastOn` method receives a string `$event` argument. This argument contains the type of event that has occurred on the model and will have a value of `created`, `updated`, `deleted`, `trashed`, or `restored`. By inspecting the value of this variable, you may determine which channels (if any) the model should broadcast to for a particular event:

```php
/**
 * Get the channels that model events should broadcast on.
 *
 * @return array<string, array<int, \Illuminate\Broadcasting\Channel|\Illuminate\Database\Eloquent\Model>>
 */
public function broadcastOn(string $event): array
{
    return match ($event) {
        'deleted' => [],
        default => [$this, $this->user],
    };
}
```

<a name="customizing-model-broadcasting-event-creation"></a>
#### Customizing Model Broadcasting Event Creation

Occasionally, you may wish to customize how Laravel creates the underlying model broadcasting event. You may accomplish this by defining a `newBroadcastableEvent` method on your Eloquent model. This method should return an `Illuminate\Database\Eloquent\BroadcastableModelEventOccurred` instance:

```php
use Illuminate\Database\Eloquent\BroadcastableModelEventOccurred;

/**
 * Create a new broadcastable model event for the model.
 */
protected function newBroadcastableEvent(string $event): BroadcastableModelEventOccurred
{
    return (new BroadcastableModelEventOccurred(
        $this, $event
    ))->dontBroadcastToCurrentUser();
}
```

<a name="model-broadcasting-conventions"></a>
### Model Broadcasting Conventions

<a name="model-broadcasting-channel-conventions"></a>
#### Channel Conventions

As you may have noticed, the `broadcastOn` method in the model example above did not return `Channel` instances. Instead, Eloquent models were returned directly. If an Eloquent model instance is returned by your model's `broadcastOn` method (or is contained in an array returned by the method), Laravel will automatically instantiate a private channel instance for the model using the model's class name and primary key identifier as the channel name.

So, an `App\Models\User` model with an `id` of `1` would be converted into an `Illuminate\Broadcasting\PrivateChannel` instance with a name of `App.Models.User.1`. Of course, in addition to returning Eloquent model instances from your model's `broadcastOn` method, you may return complete `Channel` instances in order to have full control over the model's channel names:

```php
use Illuminate\Broadcasting\PrivateChannel;

/**
 * Get the channels that model events should broadcast on.
 *
 * @return array<int, \Illuminate\Broadcasting\Channel>
 */
public function broadcastOn(string $event): array
{
    return [
        new PrivateChannel('user.'.$this->id)
    ];
}
```

If you plan to explicitly return a channel instance from your model's `broadcastOn` method, you may pass an Eloquent model instance to the channel's constructor. When doing so, Laravel will use the model channel conventions discussed above to convert the Eloquent model into a channel name string:

```php
return [new Channel($this->user)];
```

If you need to determine the channel name of a model, you may call the `broadcastChannel` method on any model instance. For example, this method returns the string `App.Models.User.1` for an `App\Models\User` model with an `id` of `1`:

```php
$user->broadcastChannel()
```

<a name="model-broadcasting-event-conventions"></a>
#### Event Conventions

Since model broadcast events are not associated with an "actual" event within your application's `App\Events` directory, they are assigned a name and a payload based on conventions. Laravel's convention is to broadcast the event using the class name of the model (not including the namespace) and the name of the model event that triggered the broadcast.

So, for example, an update to the `App\Models\Post` model would broadcast an event to your client-side application as `PostUpdated` with the following payload:

```json
{
    "model": {
        "id": 1,
        "title": "My first post"
        ...
    },
    ...
    "socket": "someSocketId",
}
```

The deletion of the `App\Models\User` model would broadcast an event named `UserDeleted`.

If you would like, you may define a custom broadcast name and payload by adding a `broadcastAs` and `broadcastWith` method to your model. These methods receive the name of the model event / operation that is occurring, allowing you to customize the event's name and payload for each model operation. If `null` is returned from the `broadcastAs` method, Laravel will use the model broadcasting event name conventions discussed above when broadcasting the event:

```php
/**
 * The model event's broadcast name.
 */
public function broadcastAs(string $event): string|null
{
    return match ($event) {
        'created' => 'post.created',
        default => null,
    };
}

/**
 * Get the data to broadcast for the model.
 *
 * @return array<string, mixed>
 */
public function broadcastWith(string $event): array
{
    return match ($event) {
        'created' => ['title' => $this->title],
        default => ['model' => $this],
    };
}
```

<a name="listening-for-model-broadcasts"></a>
### Listening for Model Broadcasts

Once you have added the `BroadcastsEvents` trait to your model and defined your model's `broadcastOn` method, you are ready to start listening for broadcasted model events within your client-side application. Before getting started, you may wish to consult the complete documentation on [listening for events](#listening-for-events).

First, use the `private` method to retrieve an instance of a channel, then call the `listen` method to listen for a specified event. Typically, the channel name given to the `private` method should correspond to Laravel's [model broadcasting conventions](#model-broadcasting-conventions).

Once you have obtained a channel instance, you may use the `listen` method to listen for a particular event. Since model broadcast events are not associated with an "actual" event within your application's `App\Events` directory, the [event name](#model-broadcasting-event-conventions) must be prefixed with a `.` to indicate it does not belong to a particular namespace. Each model broadcast event has a `model` property which contains all of the broadcastable properties of the model:

```js
Echo.private(`App.Models.User.${this.user.id}`)
    .listen('.PostUpdated', (e) => {
        console.log(e.model);
    });
```

<a name="client-events"></a>
## Client Events

> [!NOTE]  
> When using [Pusher Channels](https://pusher.com/channels), you must enable the "Client Events" option in the "App Settings" section of your [application dashboard](https://dashboard.pusher.com/) in order to send client events.

Sometimes you may wish to broadcast an event to other connected clients without hitting your Laravel application at all. This can be particularly useful for things like "typing" notifications, where you want to alert users of your application that another user is typing a message on a given screen.

To broadcast client events, you may use Echo's `whisper` method:

```js
Echo.private(`chat.${roomId}`)
    .whisper('typing', {
        name: this.user.name
    });
```

To listen for client events, you may use the `listenForWhisper` method:

```js
Echo.private(`chat.${roomId}`)
    .listenForWhisper('typing', (e) => {
        console.log(e.name);
    });
```

<a name="notifications"></a>
## Notifications

By pairing event broadcasting with [notifications](/docs/{{version}}/notifications), your JavaScript application may receive new notifications as they occur without needing to refresh the page. Before getting started, be sure to read over the documentation on using [the broadcast notification channel](/docs/{{version}}/notifications#broadcast-notifications).

Once you have configured a notification to use the broadcast channel, you may listen for the broadcast events using Echo's `notification` method. Remember, the channel name should match the class name of the entity receiving the notifications:

```js
Echo.private(`App.Models.User.${userId}`)
    .notification((notification) => {
        console.log(notification.type);
    });
```

In this example, all notifications sent to `App\Models\User` instances via the `broadcast` channel would be received by the callback. A channel authorization callback for the `App.Models.User.{id}` channel is included in the default `BroadcastServiceProvider` that ships with the Laravel framework.



## Events

# Events

- [Introduction](#introduction)
- [Registering Events and Listeners](#registering-events-and-listeners)
    - [Generating Events and Listeners](#generating-events-and-listeners)
    - [Manually Registering Events](#manually-registering-events)
    - [Event Discovery](#event-discovery)
- [Defining Events](#defining-events)
- [Defining Listeners](#defining-listeners)
- [Queued Event Listeners](#queued-event-listeners)
    - [Manually Interacting With the Queue](#manually-interacting-with-the-queue)
    - [Queued Event Listeners and Database Transactions](#queued-event-listeners-and-database-transactions)
    - [Handling Failed Jobs](#handling-failed-jobs)
- [Dispatching Events](#dispatching-events)
    - [Dispatching Events After Database Transactions](#dispatching-events-after-database-transactions)
- [Event Subscribers](#event-subscribers)
    - [Writing Event Subscribers](#writing-event-subscribers)
    - [Registering Event Subscribers](#registering-event-subscribers)
- [Testing](#testing)
    - [Faking a Subset of Events](#faking-a-subset-of-events)
    - [Scoped Events Fakes](#scoped-event-fakes)

<a name="introduction"></a>
## Introduction

Laravel's events provide a simple observer pattern implementation, allowing you to subscribe and listen for various events that occur within your application. Event classes are typically stored in the `app/Events` directory, while their listeners are stored in `app/Listeners`. Don't worry if you don't see these directories in your application as they will be created for you as you generate events and listeners using Artisan console commands.

Events serve as a great way to decouple various aspects of your application, since a single event can have multiple listeners that do not depend on each other. For example, you may wish to send a Slack notification to your user each time an order has shipped. Instead of coupling your order processing code to your Slack notification code, you can raise an `App\Events\OrderShipped` event which a listener can receive and use to dispatch a Slack notification.

<a name="registering-events-and-listeners"></a>
## Registering Events and Listeners

The `App\Providers\EventServiceProvider` included with your Laravel application provides a convenient place to register all of your application's event listeners. The `listen` property contains an array of all events (keys) and their listeners (values). You may add as many events to this array as your application requires. For example, let's add an `OrderShipped` event:

    use App\Events\OrderShipped;
    use App\Listeners\SendShipmentNotification;

    /**
     * The event listener mappings for the application.
     *
     * @var array<class-string, array<int, class-string>>
     */
    protected $listen = [
        OrderShipped::class => [
            SendShipmentNotification::class,
        ],
    ];

> [!NOTE]  
> The `event:list` command may be used to display a list of all events and listeners registered by your application.

<a name="generating-events-and-listeners"></a>
### Generating Events and Listeners

Of course, manually creating the files for each event and listener is cumbersome. Instead, add listeners and events to your `EventServiceProvider` and use the `event:generate` Artisan command. This command will generate any events or listeners that are listed in your `EventServiceProvider` that do not already exist:

```shell
php artisan event:generate
```

Alternatively, you may use the `make:event` and `make:listener` Artisan commands to generate individual events and listeners:

```shell
php artisan make:event PodcastProcessed

php artisan make:listener SendPodcastNotification --event=PodcastProcessed
```

<a name="manually-registering-events"></a>
### Manually Registering Events

Typically, events should be registered via the `EventServiceProvider` `$listen` array; however, you may also register class or closure based event listeners manually in the `boot` method of your `EventServiceProvider`:

    use App\Events\PodcastProcessed;
    use App\Listeners\SendPodcastNotification;
    use Illuminate\Support\Facades\Event;

    /**
     * Register any other events for your application.
     */
    public function boot(): void
    {
        Event::listen(
            PodcastProcessed::class,
            SendPodcastNotification::class,
        );

        Event::listen(function (PodcastProcessed $event) {
            // ...
        });
    }

<a name="queuable-anonymous-event-listeners"></a>
#### Queueable Anonymous Event Listeners

When registering closure based event listeners manually, you may wrap the listener closure within the `Illuminate\Events\queueable` function to instruct Laravel to execute the listener using the [queue](/docs/{{version}}/queues):

    use App\Events\PodcastProcessed;
    use function Illuminate\Events\queueable;
    use Illuminate\Support\Facades\Event;

    /**
     * Register any other events for your application.
     */
    public function boot(): void
    {
        Event::listen(queueable(function (PodcastProcessed $event) {
            // ...
        }));
    }

Like queued jobs, you may use the `onConnection`, `onQueue`, and `delay` methods to customize the execution of the queued listener:

    Event::listen(queueable(function (PodcastProcessed $event) {
        // ...
    })->onConnection('redis')->onQueue('podcasts')->delay(now()->addSeconds(10)));

If you would like to handle anonymous queued listener failures, you may provide a closure to the `catch` method while defining the `queueable` listener. This closure will receive the event instance and the `Throwable` instance that caused the listener's failure:

    use App\Events\PodcastProcessed;
    use function Illuminate\Events\queueable;
    use Illuminate\Support\Facades\Event;
    use Throwable;

    Event::listen(queueable(function (PodcastProcessed $event) {
        // ...
    })->catch(function (PodcastProcessed $event, Throwable $e) {
        // The queued listener failed...
    }));

<a name="wildcard-event-listeners"></a>
#### Wildcard Event Listeners

You may even register listeners using the `*` as a wildcard parameter, allowing you to catch multiple events on the same listener. Wildcard listeners receive the event name as their first argument and the entire event data array as their second argument:

    Event::listen('event.*', function (string $eventName, array $data) {
        // ...
    });

<a name="event-discovery"></a>
### Event Discovery

Instead of registering events and listeners manually in the `$listen` array of the `EventServiceProvider`, you can enable automatic event discovery. When event discovery is enabled, Laravel will automatically find and register your events and listeners by scanning your application's `Listeners` directory. In addition, any explicitly defined events listed in the `EventServiceProvider` will still be registered.

Laravel finds event listeners by scanning the listener classes using PHP's reflection services. When Laravel finds any listener class method that begins with `handle` or `__invoke`, Laravel will register those methods as event listeners for the event that is type-hinted in the method's signature:

    use App\Events\PodcastProcessed;

    class SendPodcastNotification
    {
        /**
         * Handle the given event.
         */
        public function handle(PodcastProcessed $event): void
        {
            // ...
        }
    }

Event discovery is disabled by default, but you can enable it by overriding the `shouldDiscoverEvents` method of your application's `EventServiceProvider`:

    /**
     * Determine if events and listeners should be automatically discovered.
     */
    public function shouldDiscoverEvents(): bool
    {
        return true;
    }

By default, all listeners within your application's `app/Listeners` directory will be scanned. If you would like to define additional directories to scan, you may override the `discoverEventsWithin` method in your `EventServiceProvider`:

    /**
     * Get the listener directories that should be used to discover events.
     *
     * @return array<int, string>
     */
    protected function discoverEventsWithin(): array
    {
        return [
            $this->app->path('Listeners'),
        ];
    }

<a name="event-discovery-in-production"></a>
#### Event Discovery In Production

In production, it is not efficient for the framework to scan all of your listeners on every request. Therefore, during your deployment process, you should run the `event:cache` Artisan command to cache a manifest of all of your application's events and listeners. This manifest will be used by the framework to speed up the event registration process. The `event:clear` command may be used to destroy the cache.

<a name="defining-events"></a>
## Defining Events

An event class is essentially a data container which holds the information related to the event. For example, let's assume an `App\Events\OrderShipped` event receives an [Eloquent ORM](/docs/{{version}}/eloquent) object:

    <?php

    namespace App\Events;

    use App\Models\Order;
    use Illuminate\Broadcasting\InteractsWithSockets;
    use Illuminate\Foundation\Events\Dispatchable;
    use Illuminate\Queue\SerializesModels;

    class OrderShipped
    {
        use Dispatchable, InteractsWithSockets, SerializesModels;

        /**
         * Create a new event instance.
         */
        public function __construct(
            public Order $order,
        ) {}
    }

As you can see, this event class contains no logic. It is a container for the `App\Models\Order` instance that was purchased. The `SerializesModels` trait used by the event will gracefully serialize any Eloquent models if the event object is serialized using PHP's `serialize` function, such as when utilizing [queued listeners](#queued-event-listeners).

<a name="defining-listeners"></a>
## Defining Listeners

Next, let's take a look at the listener for our example event. Event listeners receive event instances in their `handle` method. The `event:generate` and `make:listener` Artisan commands will automatically import the proper event class and type-hint the event on the `handle` method. Within the `handle` method, you may perform any actions necessary to respond to the event:

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;

    class SendShipmentNotification
    {
        /**
         * Create the event listener.
         */
        public function __construct()
        {
            // ...
        }

        /**
         * Handle the event.
         */
        public function handle(OrderShipped $event): void
        {
            // Access the order using $event->order...
        }
    }

> [!NOTE]  
> Your event listeners may also type-hint any dependencies they need on their constructors. All event listeners are resolved via the Laravel [service container](/docs/{{version}}/container), so dependencies will be injected automatically.

<a name="stopping-the-propagation-of-an-event"></a>
#### Stopping The Propagation Of An Event

Sometimes, you may wish to stop the propagation of an event to other listeners. You may do so by returning `false` from your listener's `handle` method.

<a name="queued-event-listeners"></a>
## Queued Event Listeners

Queueing listeners can be beneficial if your listener is going to perform a slow task such as sending an email or making an HTTP request. Before using queued listeners, make sure to [configure your queue](/docs/{{version}}/queues) and start a queue worker on your server or local development environment.

To specify that a listener should be queued, add the `ShouldQueue` interface to the listener class. Listeners generated by the `event:generate` and `make:listener` Artisan commands already have this interface imported into the current namespace so you can use it immediately:

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;
    use Illuminate\Contracts\Queue\ShouldQueue;

    class SendShipmentNotification implements ShouldQueue
    {
        // ...
    }

That's it! Now, when an event handled by this listener is dispatched, the listener will automatically be queued by the event dispatcher using Laravel's [queue system](/docs/{{version}}/queues). If no exceptions are thrown when the listener is executed by the queue, the queued job will automatically be deleted after it has finished processing.

<a name="customizing-the-queue-connection-queue-name"></a>
#### Customizing The Queue Connection, Name, & Delay

If you would like to customize the queue connection, queue name, or queue delay time of an event listener, you may define the `$connection`, `$queue`, or `$delay` properties on your listener class:

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;
    use Illuminate\Contracts\Queue\ShouldQueue;

    class SendShipmentNotification implements ShouldQueue
    {
        /**
         * The name of the connection the job should be sent to.
         *
         * @var string|null
         */
        public $connection = 'sqs';

        /**
         * The name of the queue the job should be sent to.
         *
         * @var string|null
         */
        public $queue = 'listeners';

        /**
         * The time (seconds) before the job should be processed.
         *
         * @var int
         */
        public $delay = 60;
    }

If you would like to define the listener's queue connection, queue name, or delay at runtime, you may define `viaConnection`, `viaQueue`, or `withDelay` methods on the listener:

    /**
     * Get the name of the listener's queue connection.
     */
    public function viaConnection(): string
    {
        return 'sqs';
    }

    /**
     * Get the name of the listener's queue.
     */
    public function viaQueue(): string
    {
        return 'listeners';
    }

    /**
     * Get the number of seconds before the job should be processed.
     */
    public function withDelay(OrderShipped $event): int
    {
        return $event->highPriority ? 0 : 60;
    }

<a name="conditionally-queueing-listeners"></a>
#### Conditionally Queueing Listeners

Sometimes, you may need to determine whether a listener should be queued based on some data that are only available at runtime. To accomplish this, a `shouldQueue` method may be added to a listener to determine whether the listener should be queued. If the `shouldQueue` method returns `false`, the listener will not be executed:

    <?php

    namespace App\Listeners;

    use App\Events\OrderCreated;
    use Illuminate\Contracts\Queue\ShouldQueue;

    class RewardGiftCard implements ShouldQueue
    {
        /**
         * Reward a gift card to the customer.
         */
        public function handle(OrderCreated $event): void
        {
            // ...
        }

        /**
         * Determine whether the listener should be queued.
         */
        public function shouldQueue(OrderCreated $event): bool
        {
            return $event->order->subtotal >= 5000;
        }
    }

<a name="manually-interacting-with-the-queue"></a>
### Manually Interacting With the Queue

If you need to manually access the listener's underlying queue job's `delete` and `release` methods, you may do so using the `Illuminate\Queue\InteractsWithQueue` trait. This trait is imported by default on generated listeners and provides access to these methods:

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Queue\InteractsWithQueue;

    class SendShipmentNotification implements ShouldQueue
    {
        use InteractsWithQueue;

        /**
         * Handle the event.
         */
        public function handle(OrderShipped $event): void
        {
            if (true) {
                $this->release(30);
            }
        }
    }

<a name="queued-event-listeners-and-database-transactions"></a>
### Queued Event Listeners and Database Transactions

When queued listeners are dispatched within database transactions, they may be processed by the queue before the database transaction has committed. When this happens, any updates you have made to models or database records during the database transaction may not yet be reflected in the database. In addition, any models or database records created within the transaction may not exist in the database. If your listener depends on these models, unexpected errors can occur when the job that dispatches the queued listener is processed.

If your queue connection's `after_commit` configuration option is set to `false`, you may still indicate that a particular queued listener should be dispatched after all open database transactions have been committed by implementing the `ShouldHandleEventsAfterCommit` interface on the listener class:

    <?php

    namespace App\Listeners;

    use Illuminate\Contracts\Events\ShouldHandleEventsAfterCommit;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Queue\InteractsWithQueue;

    class SendShipmentNotification implements ShouldQueue, ShouldHandleEventsAfterCommit
    {
        use InteractsWithQueue;
    }

> [!NOTE]  
> To learn more about working around these issues, please review the documentation regarding [queued jobs and database transactions](/docs/{{version}}/queues#jobs-and-database-transactions).

<a name="handling-failed-jobs"></a>
### Handling Failed Jobs

Sometimes your queued event listeners may fail. If the queued listener exceeds the maximum number of attempts as defined by your queue worker, the `failed` method will be called on your listener. The `failed` method receives the event instance and the `Throwable` that caused the failure:

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Queue\InteractsWithQueue;
    use Throwable;

    class SendShipmentNotification implements ShouldQueue
    {
        use InteractsWithQueue;

        /**
         * Handle the event.
         */
        public function handle(OrderShipped $event): void
        {
            // ...
        }

        /**
         * Handle a job failure.
         */
        public function failed(OrderShipped $event, Throwable $exception): void
        {
            // ...
        }
    }

<a name="specifying-queued-listener-maximum-attempts"></a>
#### Specifying Queued Listener Maximum Attempts

If one of your queued listeners is encountering an error, you likely do not want it to keep retrying indefinitely. Therefore, Laravel provides various ways to specify how many times or for how long a listener may be attempted.

You may define a `$tries` property on your listener class to specify how many times the listener may be attempted before it is considered to have failed:

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Queue\InteractsWithQueue;

    class SendShipmentNotification implements ShouldQueue
    {
        use InteractsWithQueue;

        /**
         * The number of times the queued listener may be attempted.
         *
         * @var int
         */
        public $tries = 5;
    }

As an alternative to defining how many times a listener may be attempted before it fails, you may define a time at which the listener should no longer be attempted. This allows a listener to be attempted any number of times within a given time frame. To define the time at which a listener should no longer be attempted, add a `retryUntil` method to your listener class. This method should return a `DateTime` instance:

    use DateTime;

    /**
     * Determine the time at which the listener should timeout.
     */
    public function retryUntil(): DateTime
    {
        return now()->addMinutes(5);
    }

<a name="dispatching-events"></a>
## Dispatching Events

To dispatch an event, you may call the static `dispatch` method on the event. This method is made available on the event by the `Illuminate\Foundation\Events\Dispatchable` trait. Any arguments passed to the `dispatch` method will be passed to the event's constructor:

    <?php

    namespace App\Http\Controllers;

    use App\Events\OrderShipped;
    use App\Http\Controllers\Controller;
    use App\Models\Order;
    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;

    class OrderShipmentController extends Controller
    {
        /**
         * Ship the given order.
         */
        public function store(Request $request): RedirectResponse
        {
            $order = Order::findOrFail($request->order_id);

            // Order shipment logic...

            OrderShipped::dispatch($order);

            return redirect('/orders');
        }
    }
    
 If you would like to conditionally dispatch an event, you may use the `dispatchIf` and `dispatchUnless` methods:

    OrderShipped::dispatchIf($condition, $order);

    OrderShipped::dispatchUnless($condition, $order);

> [!NOTE]  
> When testing, it can be helpful to assert that certain events were dispatched without actually triggering their listeners. Laravel's [built-in testing helpers](#testing) make it a cinch.

<a name="dispatching-events-after-database-transactions"></a>
### Dispatching Events After Database Transactions

Sometimes, you may want to instruct Laravel to only dispatch an event after the active database transaction has committed. To do so, you may implement the `ShouldDispatchAfterCommit` interface on the event class.

This interface instructs Laravel to not dispatch the event until the current database transaction is committed. If the transaction fails, the event will be discarded. If no database transaction is in progress when the event is dispatched, the event will be dispatched immediately:

    <?php

    namespace App\Events;

    use App\Models\Order;
    use Illuminate\Broadcasting\InteractsWithSockets;
    use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
    use Illuminate\Foundation\Events\Dispatchable;
    use Illuminate\Queue\SerializesModels;

    class OrderShipped implements ShouldDispatchAfterCommit
    {
        use Dispatchable, InteractsWithSockets, SerializesModels;

        /**
         * Create a new event instance.
         */
        public function __construct(
            public Order $order,
        ) {}
    }

<a name="event-subscribers"></a>
## Event Subscribers

<a name="writing-event-subscribers"></a>
### Writing Event Subscribers

Event subscribers are classes that may subscribe to multiple events from within the subscriber class itself, allowing you to define several event handlers within a single class. Subscribers should define a `subscribe` method, which will be passed an event dispatcher instance. You may call the `listen` method on the given dispatcher to register event listeners:

    <?php

    namespace App\Listeners;

    use Illuminate\Auth\Events\Login;
    use Illuminate\Auth\Events\Logout;
    use Illuminate\Events\Dispatcher;

    class UserEventSubscriber
    {
        /**
         * Handle user login events.
         */
        public function handleUserLogin(Login $event): void {}

        /**
         * Handle user logout events.
         */
        public function handleUserLogout(Logout $event): void {}

        /**
         * Register the listeners for the subscriber.
         */
        public function subscribe(Dispatcher $events): void
        {
            $events->listen(
                Login::class,
                [UserEventSubscriber::class, 'handleUserLogin']
            );

            $events->listen(
                Logout::class,
                [UserEventSubscriber::class, 'handleUserLogout']
            );
        }
    }

If your event listener methods are defined within the subscriber itself, you may find it more convenient to return an array of events and method names from the subscriber's `subscribe` method. Laravel will automatically determine the subscriber's class name when registering the event listeners:

    <?php

    namespace App\Listeners;

    use Illuminate\Auth\Events\Login;
    use Illuminate\Auth\Events\Logout;
    use Illuminate\Events\Dispatcher;

    class UserEventSubscriber
    {
        /**
         * Handle user login events.
         */
        public function handleUserLogin(Login $event): void {}

        /**
         * Handle user logout events.
         */
        public function handleUserLogout(Logout $event): void {}

        /**
         * Register the listeners for the subscriber.
         *
         * @return array<string, string>
         */
        public function subscribe(Dispatcher $events): array
        {
            return [
                Login::class => 'handleUserLogin',
                Logout::class => 'handleUserLogout',
            ];
        }
    }

<a name="registering-event-subscribers"></a>
### Registering Event Subscribers

After writing the subscriber, you are ready to register it with the event dispatcher. You may register subscribers using the `$subscribe` property on the `EventServiceProvider`. For example, let's add the `UserEventSubscriber` to the list:

    <?php

    namespace App\Providers;

    use App\Listeners\UserEventSubscriber;
    use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

    class EventServiceProvider extends ServiceProvider
    {
        /**
         * The event listener mappings for the application.
         *
         * @var array
         */
        protected $listen = [
            // ...
        ];

        /**
         * The subscriber classes to register.
         *
         * @var array
         */
        protected $subscribe = [
            UserEventSubscriber::class,
        ];
    }

<a name="testing"></a>
## Testing

When testing code that dispatches events, you may wish to instruct Laravel to not actually execute the event's listeners, since the listener's code can be tested directly and separately of the code that dispatches the corresponding event. Of course, to test the listener itself, you may instantiate a listener instance and invoke the `handle` method directly in your test.

Using the `Event` facade's `fake` method, you may prevent listeners from executing, execute the code under test, and then assert which events were dispatched by your application using the `assertDispatched`, `assertNotDispatched`, and `assertNothingDispatched` methods:

    <?php

    namespace Tests\Feature;

    use App\Events\OrderFailedToShip;
    use App\Events\OrderShipped;
    use Illuminate\Support\Facades\Event;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        /**
         * Test order shipping.
         */
        public function test_orders_can_be_shipped(): void
        {
            Event::fake();

            // Perform order shipping...

            // Assert that an event was dispatched...
            Event::assertDispatched(OrderShipped::class);

            // Assert an event was dispatched twice...
            Event::assertDispatched(OrderShipped::class, 2);

            // Assert an event was not dispatched...
            Event::assertNotDispatched(OrderFailedToShip::class);

            // Assert that no events were dispatched...
            Event::assertNothingDispatched();
        }
    }

You may pass a closure to the `assertDispatched` or `assertNotDispatched` methods in order to assert that an event was dispatched that passes a given "truth test". If at least one event was dispatched that passes the given truth test then the assertion will be successful:

    Event::assertDispatched(function (OrderShipped $event) use ($order) {
        return $event->order->id === $order->id;
    });

If you would simply like to assert that an event listener is listening to a given event, you may use the `assertListening` method:

    Event::assertListening(
        OrderShipped::class,
        SendShipmentNotification::class
    );

> [!WARNING]  
> After calling `Event::fake()`, no event listeners will be executed. So, if your tests use model factories that rely on events, such as creating a UUID during a model's `creating` event, you should call `Event::fake()` **after** using your factories.

<a name="faking-a-subset-of-events"></a>
### Faking a Subset of Events

If you only want to fake event listeners for a specific set of events, you may pass them to the `fake` or `fakeFor` method:

    /**
     * Test order process.
     */
    public function test_orders_can_be_processed(): void
    {
        Event::fake([
            OrderCreated::class,
        ]);

        $order = Order::factory()->create();

        Event::assertDispatched(OrderCreated::class);

        // Other events are dispatched as normal...
        $order->update([...]);
    }

You may fake all events except for a set of specified events using the `except` method:

    Event::fake()->except([
        OrderCreated::class,
    ]);

<a name="scoped-event-fakes"></a>
### Scoped Event Fakes

If you only want to fake event listeners for a portion of your test, you may use the `fakeFor` method:

    <?php

    namespace Tests\Feature;

    use App\Events\OrderCreated;
    use App\Models\Order;
    use Illuminate\Support\Facades\Event;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        /**
         * Test order process.
         */
        public function test_orders_can_be_processed(): void
        {
            $order = Event::fakeFor(function () {
                $order = Order::factory()->create();

                Event::assertDispatched(OrderCreated::class);

                return $order;
            });

            // Events are dispatched as normal and observers will run ...
            $order->update([...]);
        }
    }


