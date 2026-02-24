# Auth


## Authentication

# Authentication

- [Introduction](#introduction)
    - [Starter Kits](#starter-kits)
    - [Database Considerations](#introduction-database-considerations)
    - [Ecosystem Overview](#ecosystem-overview)
- [Authentication Quickstart](#authentication-quickstart)
    - [Install a Starter Kit](#install-a-starter-kit)
    - [Retrieving the Authenticated User](#retrieving-the-authenticated-user)
    - [Protecting Routes](#protecting-routes)
    - [Login Throttling](#login-throttling)
- [Manually Authenticating Users](#authenticating-users)
    - [Remembering Users](#remembering-users)
    - [Other Authentication Methods](#other-authentication-methods)
- [HTTP Basic Authentication](#http-basic-authentication)
    - [Stateless HTTP Basic Authentication](#stateless-http-basic-authentication)
- [Logging Out](#logging-out)
    - [Invalidating Sessions on Other Devices](#invalidating-sessions-on-other-devices)
- [Password Confirmation](#password-confirmation)
    - [Configuration](#password-confirmation-configuration)
    - [Routing](#password-confirmation-routing)
    - [Protecting Routes](#password-confirmation-protecting-routes)
- [Adding Custom Guards](#adding-custom-guards)
    - [Closure Request Guards](#closure-request-guards)
- [Adding Custom User Providers](#adding-custom-user-providers)
    - [The User Provider Contract](#the-user-provider-contract)
    - [The Authenticatable Contract](#the-authenticatable-contract)
- [Automatic Password Rehashing](#automatic-password-rehashing)
- [Social Authentication](/docs/{{version}}/socialite)
- [Events](#events)

<a name="introduction"></a>
## Introduction

Many web applications provide a way for their users to authenticate with the application and "login". Implementing this feature in web applications can be a complex and potentially risky endeavor. For this reason, Laravel strives to give you the tools you need to implement authentication quickly, securely, and easily.

At its core, Laravel's authentication facilities are made up of "guards" and "providers". Guards define how users are authenticated for each request. For example, Laravel ships with a `session` guard which maintains state using session storage and cookies.

Providers define how users are retrieved from your persistent storage. Laravel ships with support for retrieving users using [Eloquent](/docs/{{version}}/eloquent) and the database query builder. However, you are free to define additional providers as needed for your application.

Your application's authentication configuration file is located at `config/auth.php`. This file contains several well-documented options for tweaking the behavior of Laravel's authentication services.

> [!NOTE]  
> Guards and providers should not be confused with "roles" and "permissions". To learn more about authorizing user actions via permissions, please refer to the [authorization](/docs/{{version}}/authorization) documentation.

<a name="starter-kits"></a>
### Starter Kits

Want to get started fast? Install a [Laravel application starter kit](/docs/{{version}}/starter-kits) in a fresh Laravel application. After migrating your database, navigate your browser to `/register` or any other URL that is assigned to your application. The starter kits will take care of scaffolding your entire authentication system!

**Even if you choose not to use a starter kit in your final Laravel application, installing the [Laravel Breeze](/docs/{{version}}/starter-kits#laravel-breeze) starter kit can be a wonderful opportunity to learn how to implement all of Laravel's authentication functionality in an actual Laravel project.** Since Laravel Breeze creates authentication controllers, routes, and views for you, you can examine the code within these files to learn how Laravel's authentication features may be implemented.

<a name="introduction-database-considerations"></a>
### Database Considerations

By default, Laravel includes an `App\Models\User` [Eloquent model](/docs/{{version}}/eloquent) in your `app/Models` directory. This model may be used with the default Eloquent authentication driver.

If your application is not using Eloquent, you may use the `database` authentication provider which uses the Laravel query builder. If your application is using MongoDB, check out MongoDB's official [Laravel user authentication documentation](https://www.mongodb.com/docs/drivers/php/laravel-mongodb/current/user-authentication/) .

When building the database schema for the `App\Models\User` model, make sure the password column is at least 60 characters in length. Of course, the `users` table migration that is included in new Laravel applications already creates a column that exceeds this length.

Also, you should verify that your `users` (or equivalent) table contains a nullable, string `remember_token` column of 100 characters. This column will be used to store a token for users that select the "remember me" option when logging into your application. Again, the default `users` table migration that is included in new Laravel applications already contains this column.

<a name="ecosystem-overview"></a>
### Ecosystem Overview

Laravel offers several packages related to authentication. Before continuing, we'll review the general authentication ecosystem in Laravel and discuss each package's intended purpose.

First, consider how authentication works. When using a web browser, a user will provide their username and password via a login form. If these credentials are correct, the application will store information about the authenticated user in the user's [session](/docs/{{version}}/session). A cookie issued to the browser contains the session ID so that subsequent requests to the application can associate the user with the correct session. After the session cookie is received, the application will retrieve the session data based on the session ID, note that the authentication information has been stored in the session, and will consider the user as "authenticated".

When a remote service needs to authenticate to access an API, cookies are not typically used for authentication because there is no web browser. Instead, the remote service sends an API token to the API on each request. The application may validate the incoming token against a table of valid API tokens and "authenticate" the request as being performed by the user associated with that API token.

<a name="laravels-built-in-browser-authentication-services"></a>
#### Laravel's Built-in Browser Authentication Services

Laravel includes built-in authentication and session services which are typically accessed via the `Auth` and `Session` facades. These features provide cookie-based authentication for requests that are initiated from web browsers. They provide methods that allow you to verify a user's credentials and authenticate the user. In addition, these services will automatically store the proper authentication data in the user's session and issue the user's session cookie. A discussion of how to use these services is contained within this documentation.

**Application Starter Kits**

As discussed in this documentation, you can interact with these authentication services manually to build your application's own authentication layer. However, to help you get started more quickly, we have released [free packages](/docs/{{version}}/starter-kits) that provide robust, modern scaffolding of the entire authentication layer. These packages are [Laravel Breeze](/docs/{{version}}/starter-kits#laravel-breeze), [Laravel Jetstream](/docs/{{version}}/starter-kits#laravel-jetstream), and [Laravel Fortify](/docs/{{version}}/fortify).

_Laravel Breeze_ is a simple, minimal implementation of all of Laravel's authentication features, including login, registration, password reset, email verification, and password confirmation. Laravel Breeze's view layer is comprised of simple [Blade templates](/docs/{{version}}/blade) styled with [Tailwind CSS](https://tailwindcss.com). To get started, check out the documentation on Laravel's [application starter kits](/docs/{{version}}/starter-kits).

_Laravel Fortify_ is a headless authentication backend for Laravel that implements many of the features found in this documentation, including cookie-based authentication as well as other features such as two-factor authentication and email verification. Fortify provides the authentication backend for Laravel Jetstream or may be used independently in combination with [Laravel Sanctum](/docs/{{version}}/sanctum) to provide authentication for an SPA that needs to authenticate with Laravel.

_[Laravel Jetstream](https://jetstream.laravel.com)_ is a robust application starter kit that consumes and exposes Laravel Fortify's authentication services with a beautiful, modern UI powered by [Tailwind CSS](https://tailwindcss.com), [Livewire](https://livewire.laravel.com), and / or [Inertia](https://inertiajs.com). Laravel Jetstream includes optional support for two-factor authentication, team support, browser session management, profile management, and built-in integration with [Laravel Sanctum](/docs/{{version}}/sanctum) to offer API token authentication. Laravel's API authentication offerings are discussed below.

<a name="laravels-api-authentication-services"></a>
#### Laravel's API Authentication Services

Laravel provides two optional packages to assist you in managing API tokens and authenticating requests made with API tokens: [Passport](/docs/{{version}}/passport) and [Sanctum](/docs/{{version}}/sanctum). Please note that these libraries and Laravel's built-in cookie based authentication libraries are not mutually exclusive. These libraries primarily focus on API token authentication while the built-in authentication services focus on cookie based browser authentication. Many applications will use both Laravel's built-in cookie based authentication services and one of Laravel's API authentication packages.

**Passport**

Passport is an OAuth2 authentication provider, offering a variety of OAuth2 "grant types" which allow you to issue various types of tokens. In general, this is a robust and complex package for API authentication. However, most applications do not require the complex features offered by the OAuth2 spec, which can be confusing for both users and developers. In addition, developers have been historically confused about how to authenticate SPA applications or mobile applications using OAuth2 authentication providers like Passport.

**Sanctum**

In response to the complexity of OAuth2 and developer confusion, we set out to build a simpler, more streamlined authentication package that could handle both first-party web requests from a web browser and API requests via tokens. This goal was realized with the release of [Laravel Sanctum](/docs/{{version}}/sanctum), which should be considered the preferred and recommended authentication package for applications that will be offering a first-party web UI in addition to an API, or will be powered by a single-page application (SPA) that exists separately from the backend Laravel application, or applications that offer a mobile client.

Laravel Sanctum is a hybrid web / API authentication package that can manage your application's entire authentication process. This is possible because when Sanctum based applications receive a request, Sanctum will first determine if the request includes a session cookie that references an authenticated session. Sanctum accomplishes this by calling Laravel's built-in authentication services which we discussed earlier. If the request is not being authenticated via a session cookie, Sanctum will inspect the request for an API token. If an API token is present, Sanctum will authenticate the request using that token. To learn more about this process, please consult Sanctum's ["how it works"](/docs/{{version}}/sanctum#how-it-works) documentation.

Laravel Sanctum is the API package we have chosen to include with the [Laravel Jetstream](https://jetstream.laravel.com) application starter kit because we believe it is the best fit for the majority of web application's authentication needs.

<a name="summary-choosing-your-stack"></a>
#### Summary and Choosing Your Stack

In summary, if your application will be accessed using a browser and you are building a monolithic Laravel application, your application will use Laravel's built-in authentication services.

Next, if your application offers an API that will be consumed by third parties, you will choose between [Passport](/docs/{{version}}/passport) or [Sanctum](/docs/{{version}}/sanctum) to provide API token authentication for your application. In general, Sanctum should be preferred when possible since it is a simple, complete solution for API authentication, SPA authentication, and mobile authentication, including support for "scopes" or "abilities".

If you are building a single-page application (SPA) that will be powered by a Laravel backend, you should use [Laravel Sanctum](/docs/{{version}}/sanctum). When using Sanctum, you will either need to [manually implement your own backend authentication routes](#authenticating-users) or utilize [Laravel Fortify](/docs/{{version}}/fortify) as a headless authentication backend service that provides routes and controllers for features such as registration, password reset, email verification, and more.

Passport may be chosen when your application absolutely needs all of the features provided by the OAuth2 specification.

And, if you would like to get started quickly, we are pleased to recommend [Laravel Breeze](/docs/{{version}}/starter-kits#laravel-breeze) as a quick way to start a new Laravel application that already uses our preferred authentication stack of Laravel's built-in authentication services and Laravel Sanctum.

<a name="authentication-quickstart"></a>
## Authentication Quickstart

> [!WARNING]  
> This portion of the documentation discusses authenticating users via the [Laravel application starter kits](/docs/{{version}}/starter-kits), which includes UI scaffolding to help you get started quickly. If you would like to integrate with Laravel's authentication systems directly, check out the documentation on [manually authenticating users](#authenticating-users).

<a name="install-a-starter-kit"></a>
### Install a Starter Kit

First, you should [install a Laravel application starter kit](/docs/{{version}}/starter-kits). Our current starter kits, Laravel Breeze and Laravel Jetstream, offer beautifully designed starting points for incorporating authentication into your fresh Laravel application.

Laravel Breeze is a minimal, simple implementation of all of Laravel's authentication features, including login, registration, password reset, email verification, and password confirmation. Laravel Breeze's view layer is made up of simple [Blade templates](/docs/{{version}}/blade) styled with [Tailwind CSS](https://tailwindcss.com). Additionally, Breeze provides scaffolding options based on [Livewire](https://livewire.laravel.com) or [Inertia](https://inertiajs.com), with the choice of using Vue or React for the Inertia-based scaffolding.

[Laravel Jetstream](https://jetstream.laravel.com) is a more robust application starter kit that includes support for scaffolding your application with [Livewire](https://livewire.laravel.com) or [Inertia and Vue](https://inertiajs.com). In addition, Jetstream features optional support for two-factor authentication, teams, profile management, browser session management, API support via [Laravel Sanctum](/docs/{{version}}/sanctum), account deletion, and more.

<a name="retrieving-the-authenticated-user"></a>
### Retrieving the Authenticated User

After installing an authentication starter kit and allowing users to register and authenticate with your application, you will often need to interact with the currently authenticated user. While handling an incoming request, you may access the authenticated user via the `Auth` facade's `user` method:

    use Illuminate\Support\Facades\Auth;

    // Retrieve the currently authenticated user...
    $user = Auth::user();

    // Retrieve the currently authenticated user's ID...
    $id = Auth::id();

Alternatively, once a user is authenticated, you may access the authenticated user via an `Illuminate\Http\Request` instance. Remember, type-hinted classes will automatically be injected into your controller methods. By type-hinting the `Illuminate\Http\Request` object, you may gain convenient access to the authenticated user from any controller method in your application via the request's `user` method:

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;

    class FlightController extends Controller
    {
        /**
         * Update the flight information for an existing flight.
         */
        public function update(Request $request): RedirectResponse
        {
            $user = $request->user();

            // ...

            return redirect('/flights');
        }
    }

<a name="determining-if-the-current-user-is-authenticated"></a>
#### Determining if the Current User is Authenticated

To determine if the user making the incoming HTTP request is authenticated, you may use the `check` method on the `Auth` facade. This method will return `true` if the user is authenticated:

    use Illuminate\Support\Facades\Auth;

    if (Auth::check()) {
        // The user is logged in...
    }

> [!NOTE]  
> Even though it is possible to determine if a user is authenticated using the `check` method, you will typically use a middleware to verify that the user is authenticated before allowing the user access to certain routes / controllers. To learn more about this, check out the documentation on [protecting routes](/docs/{{version}}/authentication#protecting-routes).

<a name="protecting-routes"></a>
### Protecting Routes

[Route middleware](/docs/{{version}}/middleware) can be used to only allow authenticated users to access a given route. Laravel ships with an `auth` middleware, which is a [middleware alias](/docs/{{version}}/middleware#middleware-aliases) for the `Illuminate\Auth\Middleware\Authenticate` class. Since this middleware is already aliased internally by Laravel, all you need to do is attach the middleware to a route definition:

    Route::get('/flights', function () {
        // Only authenticated users may access this route...
    })->middleware('auth');

<a name="redirecting-unauthenticated-users"></a>
#### Redirecting Unauthenticated Users

When the `auth` middleware detects an unauthenticated user, it will redirect the user to the `login` [named route](/docs/{{version}}/routing#named-routes). You may modify this behavior using the method `redirectGuestsTo` of your application's `bootstrap/app.php` file:

    use Illuminate\Http\Request;

    ->withMiddleware(function (Middleware $middleware) {
        $middleware->redirectGuestsTo('/login');

        // Using a closure...
        $middleware->redirectGuestsTo(fn (Request $request) => route('login'));
    })

<a name="specifying-a-guard"></a>
#### Specifying a Guard

When attaching the `auth` middleware to a route, you may also specify which "guard" should be used to authenticate the user. The guard specified should correspond to one of the keys in the `guards` array of your `auth.php` configuration file:

    Route::get('/flights', function () {
        // Only authenticated users may access this route...
    })->middleware('auth:admin');

<a name="login-throttling"></a>
### Login Throttling

If you are using the Laravel Breeze or Laravel Jetstream [starter kits](/docs/{{version}}/starter-kits), rate limiting will automatically be applied to login attempts. By default, the user will not be able to login for one minute if they fail to provide the correct credentials after several attempts. The throttling is unique to the user's username / email address and their IP address.

> [!NOTE]  
> If you would like to rate limit other routes in your application, check out the [rate limiting documentation](/docs/{{version}}/routing#rate-limiting).

<a name="authenticating-users"></a>
## Manually Authenticating Users

You are not required to use the authentication scaffolding included with Laravel's [application starter kits](/docs/{{version}}/starter-kits). If you choose not to use this scaffolding, you will need to manage user authentication using the Laravel authentication classes directly. Don't worry, it's a cinch!

We will access Laravel's authentication services via the `Auth` [facade](/docs/{{version}}/facades), so we'll need to make sure to import the `Auth` facade at the top of the class. Next, let's check out the `attempt` method. The `attempt` method is normally used to handle authentication attempts from your application's "login" form. If authentication is successful, you should regenerate the user's [session](/docs/{{version}}/session) to prevent [session fixation](https://en.wikipedia.org/wiki/Session_fixation):

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;
    use Illuminate\Http\RedirectResponse;
    use Illuminate\Support\Facades\Auth;

    class LoginController extends Controller
    {
        /**
         * Handle an authentication attempt.
         */
        public function authenticate(Request $request): RedirectResponse
        {
            $credentials = $request->validate([
                'email' => ['required', 'email'],
                'password' => ['required'],
            ]);

            if (Auth::attempt($credentials)) {
                $request->session()->regenerate();

                return redirect()->intended('dashboard');
            }

            return back()->withErrors([
                'email' => 'The provided credentials do not match our records.',
            ])->onlyInput('email');
        }
    }

The `attempt` method accepts an array of key / value pairs as its first argument. The values in the array will be used to find the user in your database table. So, in the example above, the user will be retrieved by the value of the `email` column. If the user is found, the hashed password stored in the database will be compared with the `password` value passed to the method via the array. You should not hash the incoming request's `password` value, since the framework will automatically hash the value before comparing it to the hashed password in the database. An authenticated session will be started for the user if the two hashed passwords match.

Remember, Laravel's authentication services will retrieve users from your database based on your authentication guard's "provider" configuration. In the default `config/auth.php` configuration file, the Eloquent user provider is specified and it is instructed to use the `App\Models\User` model when retrieving users. You may change these values within your configuration file based on the needs of your application.

The `attempt` method will return `true` if authentication was successful. Otherwise, `false` will be returned.

The `intended` method provided by Laravel's redirector will redirect the user to the URL they were attempting to access before being intercepted by the authentication middleware. A fallback URI may be given to this method in case the intended destination is not available.

<a name="specifying-additional-conditions"></a>
#### Specifying Additional Conditions

If you wish, you may also add extra query conditions to the authentication query in addition to the user's email and password. To accomplish this, we may simply add the query conditions to the array passed to the `attempt` method. For example, we may verify that the user is marked as "active":

    if (Auth::attempt(['email' => $email, 'password' => $password, 'active' => 1])) {
        // Authentication was successful...
    }

For complex query conditions, you may provide a closure in your array of credentials. This closure will be invoked with the query instance, allowing you to customize the query based on your application's needs:

    use Illuminate\Database\Eloquent\Builder;

    if (Auth::attempt([
        'email' => $email,
        'password' => $password,
        fn (Builder $query) => $query->has('activeSubscription'),
    ])) {
        // Authentication was successful...
    }

> [!WARNING]  
> In these examples, `email` is not a required option, it is merely used as an example. You should use whatever column name corresponds to a "username" in your database table.

The `attemptWhen` method, which receives a closure as its second argument, may be used to perform more extensive inspection of the potential user before actually authenticating the user. The closure receives the potential user and should return `true` or `false` to indicate if the user may be authenticated:

    if (Auth::attemptWhen([
        'email' => $email,
        'password' => $password,
    ], function (User $user) {
        return $user->isNotBanned();
    })) {
        // Authentication was successful...
    }

<a name="accessing-specific-guard-instances"></a>
#### Accessing Specific Guard Instances

Via the `Auth` facade's `guard` method, you may specify which guard instance you would like to utilize when authenticating the user. This allows you to manage authentication for separate parts of your application using entirely separate authenticatable models or user tables.

The guard name passed to the `guard` method should correspond to one of the guards configured in your `auth.php` configuration file:

    if (Auth::guard('admin')->attempt($credentials)) {
        // ...
    }

<a name="remembering-users"></a>
### Remembering Users

Many web applications provide a "remember me" checkbox on their login form. If you would like to provide "remember me" functionality in your application, you may pass a boolean value as the second argument to the `attempt` method.

When this value is `true`, Laravel will keep the user authenticated indefinitely or until they manually logout. Your `users` table must include the string `remember_token` column, which will be used to store the "remember me" token. The `users` table migration included with new Laravel applications already includes this column:

    use Illuminate\Support\Facades\Auth;

    if (Auth::attempt(['email' => $email, 'password' => $password], $remember)) {
        // The user is being remembered...
    }

If your application offers "remember me" functionality, you may use the `viaRemember`  method to determine if the currently authenticated user was authenticated using the "remember me" cookie:

    use Illuminate\Support\Facades\Auth;

    if (Auth::viaRemember()) {
        // ...
    }

<a name="other-authentication-methods"></a>
### Other Authentication Methods

<a name="authenticate-a-user-instance"></a>
#### Authenticate a User Instance

If you need to set an existing user instance as the currently authenticated user, you may pass the user instance to the `Auth` facade's `login` method. The given user instance must be an implementation of the `Illuminate\Contracts\Auth\Authenticatable` [contract](/docs/{{version}}/contracts). The `App\Models\User` model included with Laravel already implements this interface. This method of authentication is useful when you already have a valid user instance, such as directly after a user registers with your application:

    use Illuminate\Support\Facades\Auth;

    Auth::login($user);

You may pass a boolean value as the second argument to the `login` method. This value indicates if "remember me" functionality is desired for the authenticated session. Remember, this means that the session will be authenticated indefinitely or until the user manually logs out of the application:

    Auth::login($user, $remember = true);

If needed, you may specify an authentication guard before calling the `login` method:

    Auth::guard('admin')->login($user);

<a name="authenticate-a-user-by-id"></a>
#### Authenticate a User by ID

To authenticate a user using their database record's primary key, you may use the `loginUsingId` method. This method accepts the primary key of the user you wish to authenticate:

    Auth::loginUsingId(1);

You may pass a boolean value to the `remember` argument of the `loginUsingId` method. This value indicates if "remember me" functionality is desired for the authenticated session. Remember, this means that the session will be authenticated indefinitely or until the user manually logs out of the application:

    Auth::loginUsingId(1, remember: true);

<a name="authenticate-a-user-once"></a>
#### Authenticate a User Once

You may use the `once` method to authenticate a user with the application for a single request. No sessions or cookies will be utilized when calling this method:

    if (Auth::once($credentials)) {
        // ...
    }

<a name="http-basic-authentication"></a>
## HTTP Basic Authentication

[HTTP Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication) provides a quick way to authenticate users of your application without setting up a dedicated "login" page. To get started, attach the `auth.basic` [middleware](/docs/{{version}}/middleware) to a route. The `auth.basic` middleware is included with the Laravel framework, so you do not need to define it:

    Route::get('/profile', function () {
        // Only authenticated users may access this route...
    })->middleware('auth.basic');

Once the middleware has been attached to the route, you will automatically be prompted for credentials when accessing the route in your browser. By default, the `auth.basic` middleware will assume the `email` column on your `users` database table is the user's "username".

<a name="a-note-on-fastcgi"></a>
#### A Note on FastCGI

If you are using PHP FastCGI and Apache to serve your Laravel application, HTTP Basic authentication may not work correctly. To correct these problems, the following lines may be added to your application's `.htaccess` file:

```apache
RewriteCond %{HTTP:Authorization} ^(.+)$
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
```

<a name="stateless-http-basic-authentication"></a>
### Stateless HTTP Basic Authentication

You may also use HTTP Basic Authentication without setting a user identifier cookie in the session. This is primarily helpful if you choose to use HTTP Authentication to authenticate requests to your application's API. To accomplish this, [define a middleware](/docs/{{version}}/middleware) that calls the `onceBasic` method. If no response is returned by the `onceBasic` method, the request may be passed further into the application:

    <?php

    namespace App\Http\Middleware;

    use Closure;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Auth;
    use Symfony\Component\HttpFoundation\Response;

    class AuthenticateOnceWithBasicAuth
    {
        /**
         * Handle an incoming request.
         *
         * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
         */
        public function handle(Request $request, Closure $next): Response
        {
            return Auth::onceBasic() ?: $next($request);
        }

    }

Next, attach the middleware to a route:

    Route::get('/api/user', function () {
        // Only authenticated users may access this route...
    })->middleware(AuthenticateOnceWithBasicAuth::class);

<a name="logging-out"></a>
## Logging Out

To manually log users out of your application, you may use the `logout` method provided by the `Auth` facade. This will remove the authentication information from the user's session so that subsequent requests are not authenticated.

In addition to calling the `logout` method, it is recommended that you invalidate the user's session and regenerate their [CSRF token](/docs/{{version}}/csrf). After logging the user out, you would typically redirect the user to the root of your application:

    use Illuminate\Http\Request;
    use Illuminate\Http\RedirectResponse;
    use Illuminate\Support\Facades\Auth;

    /**
     * Log the user out of the application.
     */
    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();

        $request->session()->invalidate();

        $request->session()->regenerateToken();

        return redirect('/');
    }

<a name="invalidating-sessions-on-other-devices"></a>
### Invalidating Sessions on Other Devices

Laravel also provides a mechanism for invalidating and "logging out" a user's sessions that are active on other devices without invalidating the session on their current device. This feature is typically utilized when a user is changing or updating their password and you would like to invalidate sessions on other devices while keeping the current device authenticated.

Before getting started, you should make sure that the `Illuminate\Session\Middleware\AuthenticateSession` middleware is included on the routes that should receive session authentication. Typically, you should place this middleware on a route group definition so that it can be applied to the majority of your application's routes. By default, the `AuthenticateSession` middleware may be attached to a route using the `auth.session` [middleware alias](/docs/{{version}}/middleware#middleware-aliases):

    Route::middleware(['auth', 'auth.session'])->group(function () {
        Route::get('/', function () {
            // ...
        });
    });

Then, you may use the `logoutOtherDevices` method provided by the `Auth` facade. This method requires the user to confirm their current password, which your application should accept through an input form:

    use Illuminate\Support\Facades\Auth;

    Auth::logoutOtherDevices($currentPassword);

When the `logoutOtherDevices` method is invoked, the user's other sessions will be invalidated entirely, meaning they will be "logged out" of all guards they were previously authenticated by.

<a name="password-confirmation"></a>
## Password Confirmation

While building your application, you may occasionally have actions that should require the user to confirm their password before the action is performed or before the user is redirected to a sensitive area of the application. Laravel includes built-in middleware to make this process a breeze. Implementing this feature will require you to define two routes: one route to display a view asking the user to confirm their password and another route to confirm that the password is valid and redirect the user to their intended destination.

> [!NOTE]  
> The following documentation discusses how to integrate with Laravel's password confirmation features directly; however, if you would like to get started more quickly, the [Laravel application starter kits](/docs/{{version}}/starter-kits) include support for this feature!

<a name="password-confirmation-configuration"></a>
### Configuration

After confirming their password, a user will not be asked to confirm their password again for three hours. However, you may configure the length of time before the user is re-prompted for their password by changing the value of the `password_timeout` configuration value within your application's `config/auth.php` configuration file.

<a name="password-confirmation-routing"></a>
### Routing

<a name="the-password-confirmation-form"></a>
#### The Password Confirmation Form

First, we will define a route to display a view that requests the user to confirm their password:

    Route::get('/confirm-password', function () {
        return view('auth.confirm-password');
    })->middleware('auth')->name('password.confirm');

As you might expect, the view that is returned by this route should have a form containing a `password` field. In addition, feel free to include text within the view that explains that the user is entering a protected area of the application and must confirm their password.

<a name="confirming-the-password"></a>
#### Confirming the Password

Next, we will define a route that will handle the form request from the "confirm password" view. This route will be responsible for validating the password and redirecting the user to their intended destination:

    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Hash;
    use Illuminate\Support\Facades\Redirect;

    Route::post('/confirm-password', function (Request $request) {
        if (! Hash::check($request->password, $request->user()->password)) {
            return back()->withErrors([
                'password' => ['The provided password does not match our records.']
            ]);
        }

        $request->session()->passwordConfirmed();

        return redirect()->intended();
    })->middleware(['auth', 'throttle:6,1']);

Before moving on, let's examine this route in more detail. First, the request's `password` field is determined to actually match the authenticated user's password. If the password is valid, we need to inform Laravel's session that the user has confirmed their password. The `passwordConfirmed` method will set a timestamp in the user's session that Laravel can use to determine when the user last confirmed their password. Finally, we can redirect the user to their intended destination.

<a name="password-confirmation-protecting-routes"></a>
### Protecting Routes

You should ensure that any route that performs an action which requires recent password confirmation is assigned the `password.confirm` middleware. This middleware is included with the default installation of Laravel and will automatically store the user's intended destination in the session so that the user may be redirected to that location after confirming their password. After storing the user's intended destination in the session, the middleware will redirect the user to the `password.confirm` [named route](/docs/{{version}}/routing#named-routes):

    Route::get('/settings', function () {
        // ...
    })->middleware(['password.confirm']);

    Route::post('/settings', function () {
        // ...
    })->middleware(['password.confirm']);

<a name="adding-custom-guards"></a>
## Adding Custom Guards

You may define your own authentication guards using the `extend` method on the `Auth` facade. You should place your call to the `extend` method within a [service provider](/docs/{{version}}/providers). Since Laravel already ships with an `AppServiceProvider`, we can place the code in that provider:

    <?php

    namespace App\Providers;

    use App\Services\Auth\JwtGuard;
    use Illuminate\Contracts\Foundation\Application;
    use Illuminate\Support\Facades\Auth;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        // ...

        /**
         * Bootstrap any application services.
         */
        public function boot(): void
        {
            Auth::extend('jwt', function (Application $app, string $name, array $config) {
                // Return an instance of Illuminate\Contracts\Auth\Guard...

                return new JwtGuard(Auth::createUserProvider($config['provider']));
            });
        }
    }

As you can see in the example above, the callback passed to the `extend` method should return an implementation of `Illuminate\Contracts\Auth\Guard`. This interface contains a few methods you will need to implement to define a custom guard. Once your custom guard has been defined, you may reference the guard in the `guards` configuration of your `auth.php` configuration file:

    'guards' => [
        'api' => [
            'driver' => 'jwt',
            'provider' => 'users',
        ],
    ],

<a name="closure-request-guards"></a>
### Closure Request Guards

The simplest way to implement a custom, HTTP request based authentication system is by using the `Auth::viaRequest` method. This method allows you to quickly define your authentication process using a single closure.

To get started, call the `Auth::viaRequest` method within the `boot` method of your application's `AppServiceProvider`. The `viaRequest` method accepts an authentication driver name as its first argument. This name can be any string that describes your custom guard. The second argument passed to the method should be a closure that receives the incoming HTTP request and returns a user instance or, if authentication fails, `null`:

    use App\Models\User;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Auth;

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Auth::viaRequest('custom-token', function (Request $request) {
            return User::where('token', (string) $request->token)->first();
        });
    }

Once your custom authentication driver has been defined, you may configure it as a driver within the `guards` configuration of your `auth.php` configuration file:

    'guards' => [
        'api' => [
            'driver' => 'custom-token',
        ],
    ],

Finally, you may reference the guard when assigning the authentication middleware to a route:

    Route::middleware('auth:api')->group(function () {
        // ...
    });

<a name="adding-custom-user-providers"></a>
## Adding Custom User Providers

If you are not using a traditional relational database to store your users, you will need to extend Laravel with your own authentication user provider. We will use the `provider` method on the `Auth` facade to define a custom user provider. The user provider resolver should return an implementation of `Illuminate\Contracts\Auth\UserProvider`:

    <?php

    namespace App\Providers;

    use App\Extensions\MongoUserProvider;
    use Illuminate\Contracts\Foundation\Application;
    use Illuminate\Support\Facades\Auth;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        // ...

        /**
         * Bootstrap any application services.
         */
        public function boot(): void
        {
            Auth::provider('mongo', function (Application $app, array $config) {
                // Return an instance of Illuminate\Contracts\Auth\UserProvider...

                return new MongoUserProvider($app->make('mongo.connection'));
            });
        }
    }

After you have registered the provider using the `provider` method, you may switch to the new user provider in your `auth.php` configuration file. First, define a `provider` that uses your new driver:

    'providers' => [
        'users' => [
            'driver' => 'mongo',
        ],
    ],

Finally, you may reference this provider in your `guards` configuration:

    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],
    ],

<a name="the-user-provider-contract"></a>
### The User Provider Contract

`Illuminate\Contracts\Auth\UserProvider` implementations are responsible for fetching an `Illuminate\Contracts\Auth\Authenticatable` implementation out of a persistent storage system, such as MySQL, MongoDB, etc. These two interfaces allow the Laravel authentication mechanisms to continue functioning regardless of how the user data is stored or what type of class is used to represent the authenticated user:

Let's take a look at the `Illuminate\Contracts\Auth\UserProvider` contract:

    <?php

    namespace Illuminate\Contracts\Auth;

    interface UserProvider
    {
        public function retrieveById($identifier);
        public function retrieveByToken($identifier, $token);
        public function updateRememberToken(Authenticatable $user, $token);
        public function retrieveByCredentials(array $credentials);
        public function validateCredentials(Authenticatable $user, array $credentials);
        public function rehashPasswordIfRequired(Authenticatable $user, array $credentials, bool $force = false);
    }

The `retrieveById` function typically receives a key representing the user, such as an auto-incrementing ID from a MySQL database. The `Authenticatable` implementation matching the ID should be retrieved and returned by the method.

The `retrieveByToken` function retrieves a user by their unique `$identifier` and "remember me" `$token`, typically stored in a database column like `remember_token`. As with the previous method, the `Authenticatable` implementation with a matching token value should be returned by this method.

The `updateRememberToken` method updates the `$user` instance's `remember_token` with the new `$token`. A fresh token is assigned to users on a successful "remember me" authentication attempt or when the user is logging out.

The `retrieveByCredentials` method receives the array of credentials passed to the `Auth::attempt` method when attempting to authenticate with an application. The method should then "query" the underlying persistent storage for the user matching those credentials. Typically, this method will run a query with a "where" condition that searches for a user record with a "username" matching the value of `$credentials['username']`. The method should return an implementation of `Authenticatable`. **This method should not attempt to do any password validation or authentication.**

The `validateCredentials` method should compare the given `$user` with the `$credentials` to authenticate the user. For example, this method will typically use the `Hash::check` method to compare the value of `$user->getAuthPassword()` to the value of `$credentials['password']`. This method should return `true` or `false` indicating whether the password is valid.

The `rehashPasswordIfRequired` method should rehash the given `$user`'s password if required and supported. For example, this method will typically use the `Hash::needsRehash` method to determine if the `$credentials['password']` value needs to be rehashed. If the password needs to be rehashed, the method should use the `Hash::make` method to rehash the password and update the user's record in the underlying persistent storage.

<a name="the-authenticatable-contract"></a>
### The Authenticatable Contract

Now that we have explored each of the methods on the `UserProvider`, let's take a look at the `Authenticatable` contract. Remember, user providers should return implementations of this interface from the `retrieveById`, `retrieveByToken`, and `retrieveByCredentials` methods:

    <?php

    namespace Illuminate\Contracts\Auth;

    interface Authenticatable
    {
        public function getAuthIdentifierName();
        public function getAuthIdentifier();
        public function getAuthPasswordName();
        public function getAuthPassword();
        public function getRememberToken();
        public function setRememberToken($value);
        public function getRememberTokenName();
    }

This interface is simple. The `getAuthIdentifierName` method should return the name of the "primary key" column for the user and the `getAuthIdentifier` method should return the "primary key" of the user. When using a MySQL back-end, this would likely be the auto-incrementing primary key assigned to the user record. The `getAuthPasswordName` method should return the name of the user's password column. The `getAuthPassword` method should return the user's hashed password.

This interface allows the authentication system to work with any "user" class, regardless of what ORM or storage abstraction layer you are using. By default, Laravel includes an `App\Models\User` class in the `app/Models` directory which implements this interface.

<a name="automatic-password-rehashing"></a>
## Automatic Password Rehashing

Laravel's default password hashing algorithm is bcrypt. The "work factor" for bcrypt hashes can be adjusted via your application's `config/hashing.php` configuration file or the `BCRYPT_ROUNDS` environment variable.

Typically, the bcrypt work factor should be increased over time as CPU / GPU processing power increases. If you increase the bcrypt work factor for your application, Laravel will gracefully and automatically rehash user passwords as users authenticate with your application via Laravel's starter kits or when you [manually authenticate users](#authenticating-users) via the `attempt` method.

Typically, automatic password rehashing should not disrupt your application; however, you may disable this behavior by publishing the `hashing` configuration file:

```shell
php artisan config:publish hashing
```

Once the configuration file has been published, you may set the `rehash_on_login` configuration value to `false`:

```php
'rehash_on_login' => false,
```

<a name="events"></a>
## Events

Laravel dispatches a variety of [events](/docs/{{version}}/events) during the authentication process. You may [define listeners](/docs/{{version}}/events) for any of the following events:

<div class="overflow-auto">

| Event Name |
| --- |
| `Illuminate\Auth\Events\Registered` |
| `Illuminate\Auth\Events\Attempting` |
| `Illuminate\Auth\Events\Authenticated` |
| `Illuminate\Auth\Events\Login` |
| `Illuminate\Auth\Events\Failed` |
| `Illuminate\Auth\Events\Validated` |
| `Illuminate\Auth\Events\Verified` |
| `Illuminate\Auth\Events\Logout` |
| `Illuminate\Auth\Events\CurrentDeviceLogout` |
| `Illuminate\Auth\Events\OtherDeviceLogout` |
| `Illuminate\Auth\Events\Lockout` |
| `Illuminate\Auth\Events\PasswordReset` |

</div>



## Authorization

# Authorization

- [Introduction](#introduction)
- [Gates](#gates)
    - [Writing Gates](#writing-gates)
    - [Authorizing Actions](#authorizing-actions-via-gates)
    - [Gate Responses](#gate-responses)
    - [Intercepting Gate Checks](#intercepting-gate-checks)
    - [Inline Authorization](#inline-authorization)
- [Creating Policies](#creating-policies)
    - [Generating Policies](#generating-policies)
    - [Registering Policies](#registering-policies)
- [Writing Policies](#writing-policies)
    - [Policy Methods](#policy-methods)
    - [Policy Responses](#policy-responses)
    - [Methods Without Models](#methods-without-models)
    - [Guest Users](#guest-users)
    - [Policy Filters](#policy-filters)
- [Authorizing Actions Using Policies](#authorizing-actions-using-policies)
    - [Via the User Model](#via-the-user-model)
    - [Via the Gate Facade](#via-the-gate-facade)
    - [Via Middleware](#via-middleware)
    - [Via Blade Templates](#via-blade-templates)
    - [Supplying Additional Context](#supplying-additional-context)
- [Authorization & Inertia](#authorization-and-inertia)

<a name="introduction"></a>
## Introduction

In addition to providing built-in [authentication](/docs/{{version}}/authentication) services, Laravel also provides a simple way to authorize user actions against a given resource. For example, even though a user is authenticated, they may not be authorized to update or delete certain Eloquent models or database records managed by your application. Laravel's authorization features provide an easy, organized way of managing these types of authorization checks.

Laravel provides two primary ways of authorizing actions: [gates](#gates) and [policies](#creating-policies). Think of gates and policies like routes and controllers. Gates provide a simple, closure-based approach to authorization while policies, like controllers, group logic around a particular model or resource. In this documentation, we'll explore gates first and then examine policies.

You do not need to choose between exclusively using gates or exclusively using policies when building an application. Most applications will most likely contain some mixture of gates and policies, and that is perfectly fine! Gates are most applicable to actions that are not related to any model or resource, such as viewing an administrator dashboard. In contrast, policies should be used when you wish to authorize an action for a particular model or resource.

<a name="gates"></a>
## Gates

<a name="writing-gates"></a>
### Writing Gates

> [!WARNING]  
> Gates are a great way to learn the basics of Laravel's authorization features; however, when building robust Laravel applications you should consider using [policies](#creating-policies) to organize your authorization rules.

Gates are simply closures that determine if a user is authorized to perform a given action. Typically, gates are defined within the `boot` method of the `App\Providers\AppServiceProvider` class using the `Gate` facade. Gates always receive a user instance as their first argument and may optionally receive additional arguments such as a relevant Eloquent model.

In this example, we'll define a gate to determine if a user can update a given `App\Models\Post` model. The gate will accomplish this by comparing the user's `id` against the `user_id` of the user that created the post:

    use App\Models\Post;
    use App\Models\User;
    use Illuminate\Support\Facades\Gate;

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::define('update-post', function (User $user, Post $post) {
            return $user->id === $post->user_id;
        });
    }

Like controllers, gates may also be defined using a class callback array:

    use App\Policies\PostPolicy;
    use Illuminate\Support\Facades\Gate;

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::define('update-post', [PostPolicy::class, 'update']);
    }

<a name="authorizing-actions-via-gates"></a>
### Authorizing Actions

To authorize an action using gates, you should use the `allows` or `denies` methods provided by the `Gate` facade. Note that you are not required to pass the currently authenticated user to these methods. Laravel will automatically take care of passing the user into the gate closure. It is typical to call the gate authorization methods within your application's controllers before performing an action that requires authorization:

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Gate;

    class PostController extends Controller
    {
        /**
         * Update the given post.
         */
        public function update(Request $request, Post $post): RedirectResponse
        {
            if (! Gate::allows('update-post', $post)) {
                abort(403);
            }

            // Update the post...

            return redirect('/posts');
        }
    }

If you would like to determine if a user other than the currently authenticated user is authorized to perform an action, you may use the `forUser` method on the `Gate` facade:

    if (Gate::forUser($user)->allows('update-post', $post)) {
        // The user can update the post...
    }

    if (Gate::forUser($user)->denies('update-post', $post)) {
        // The user can't update the post...
    }

You may authorize multiple actions at a time using the `any` or `none` methods:

    if (Gate::any(['update-post', 'delete-post'], $post)) {
        // The user can update or delete the post...
    }

    if (Gate::none(['update-post', 'delete-post'], $post)) {
        // The user can't update or delete the post...
    }

<a name="authorizing-or-throwing-exceptions"></a>
#### Authorizing or Throwing Exceptions

If you would like to attempt to authorize an action and automatically throw an `Illuminate\Auth\Access\AuthorizationException` if the user is not allowed to perform the given action, you may use the `Gate` facade's `authorize` method. Instances of `AuthorizationException` are automatically converted to a 403 HTTP response by Laravel:

    Gate::authorize('update-post', $post);

    // The action is authorized...

<a name="gates-supplying-additional-context"></a>
#### Supplying Additional Context

The gate methods for authorizing abilities (`allows`, `denies`, `check`, `any`, `none`, `authorize`, `can`, `cannot`) and the authorization [Blade directives](#via-blade-templates) (`@can`, `@cannot`, `@canany`) can receive an array as their second argument. These array elements are passed as parameters to the gate closure, and can be used for additional context when making authorization decisions:

    use App\Models\Category;
    use App\Models\User;
    use Illuminate\Support\Facades\Gate;

    Gate::define('create-post', function (User $user, Category $category, bool $pinned) {
        if (! $user->canPublishToGroup($category->group)) {
            return false;
        } elseif ($pinned && ! $user->canPinPosts()) {
            return false;
        }

        return true;
    });

    if (Gate::check('create-post', [$category, $pinned])) {
        // The user can create the post...
    }

<a name="gate-responses"></a>
### Gate Responses

So far, we have only examined gates that return simple boolean values. However, sometimes you may wish to return a more detailed response, including an error message. To do so, you may return an `Illuminate\Auth\Access\Response` from your gate:

    use App\Models\User;
    use Illuminate\Auth\Access\Response;
    use Illuminate\Support\Facades\Gate;

    Gate::define('edit-settings', function (User $user) {
        return $user->isAdmin
            ? Response::allow()
            : Response::deny('You must be an administrator.');
    });

Even when you return an authorization response from your gate, the `Gate::allows` method will still return a simple boolean value; however, you may use the `Gate::inspect` method to get the full authorization response returned by the gate:

    $response = Gate::inspect('edit-settings');

    if ($response->allowed()) {
        // The action is authorized...
    } else {
        echo $response->message();
    }

When using the `Gate::authorize` method, which throws an `AuthorizationException` if the action is not authorized, the error message provided by the authorization response will be propagated to the HTTP response:

    Gate::authorize('edit-settings');

    // The action is authorized...

<a name="customizing-gate-response-status"></a>
#### Customizing The HTTP Response Status

When an action is denied via a Gate, a `403` HTTP response is returned; however, it can sometimes be useful to return an alternative HTTP status code. You may customize the HTTP status code returned for a failed authorization check using the `denyWithStatus` static constructor on the `Illuminate\Auth\Access\Response` class:

    use App\Models\User;
    use Illuminate\Auth\Access\Response;
    use Illuminate\Support\Facades\Gate;

    Gate::define('edit-settings', function (User $user) {
        return $user->isAdmin
            ? Response::allow()
            : Response::denyWithStatus(404);
    });

Because hiding resources via a `404` response is such a common pattern for web applications, the `denyAsNotFound` method is offered for convenience:

    use App\Models\User;
    use Illuminate\Auth\Access\Response;
    use Illuminate\Support\Facades\Gate;

    Gate::define('edit-settings', function (User $user) {
        return $user->isAdmin
            ? Response::allow()
            : Response::denyAsNotFound();
    });

<a name="intercepting-gate-checks"></a>
### Intercepting Gate Checks

Sometimes, you may wish to grant all abilities to a specific user. You may use the `before` method to define a closure that is run before all other authorization checks:

    use App\Models\User;
    use Illuminate\Support\Facades\Gate;

    Gate::before(function (User $user, string $ability) {
        if ($user->isAdministrator()) {
            return true;
        }
    });

If the `before` closure returns a non-null result that result will be considered the result of the authorization check.

You may use the `after` method to define a closure to be executed after all other authorization checks:

    use App\Models\User;

    Gate::after(function (User $user, string $ability, bool|null $result, mixed $arguments) {
        if ($user->isAdministrator()) {
            return true;
        }
    });

Values returned by `after` closures will not override the result of the authorization check unless the gate or policy returned `null`.

<a name="inline-authorization"></a>
### Inline Authorization

Occasionally, you may wish to determine if the currently authenticated user is authorized to perform a given action without writing a dedicated gate that corresponds to the action. Laravel allows you to perform these types of "inline" authorization checks via the `Gate::allowIf` and `Gate::denyIf` methods. Inline authorization does not execute any defined ["before" or "after" authorization hooks](#intercepting-gate-checks):

```php
use App\Models\User;
use Illuminate\Support\Facades\Gate;

Gate::allowIf(fn (User $user) => $user->isAdministrator());

Gate::denyIf(fn (User $user) => $user->banned());
```

If the action is not authorized or if no user is currently authenticated, Laravel will automatically throw an `Illuminate\Auth\Access\AuthorizationException` exception. Instances of `AuthorizationException` are automatically converted to a 403 HTTP response by Laravel's exception handler.

<a name="creating-policies"></a>
## Creating Policies

<a name="generating-policies"></a>
### Generating Policies

Policies are classes that organize authorization logic around a particular model or resource. For example, if your application is a blog, you may have an `App\Models\Post` model and a corresponding `App\Policies\PostPolicy` to authorize user actions such as creating or updating posts.

You may generate a policy using the `make:policy` Artisan command. The generated policy will be placed in the `app/Policies` directory. If this directory does not exist in your application, Laravel will create it for you:

```shell
php artisan make:policy PostPolicy
```

The `make:policy` command will generate an empty policy class. If you would like to generate a class with example policy methods related to viewing, creating, updating, and deleting the resource, you may provide a `--model` option when executing the command:

```shell
php artisan make:policy PostPolicy --model=Post
```

<a name="registering-policies"></a>
### Registering Policies

<a name="policy-discovery"></a>
#### Policy Discovery

By default, Laravel automatically discover policies as long as the model and policy follow standard Laravel naming conventions. Specifically, the policies must be in a `Policies` directory at or above the directory that contains your models. So, for example, the models may be placed in the `app/Models` directory while the policies may be placed in the `app/Policies` directory. In this situation, Laravel will check for policies in `app/Models/Policies` then `app/Policies`. In addition, the policy name must match the model name and have a `Policy` suffix. So, a `User` model would correspond to a `UserPolicy` policy class.

If you would like to define your own policy discovery logic, you may register a custom policy discovery callback using the `Gate::guessPolicyNamesUsing` method. Typically, this method should be called from the `boot` method of your application's `AppServiceProvider`:

    use Illuminate\Support\Facades\Gate;

    Gate::guessPolicyNamesUsing(function (string $modelClass) {
        // Return the name of the policy class for the given model...
    });

<a name="manually-registering-policies"></a>
#### Manually Registering Policies

Using the `Gate` facade, you may manually register policies and their corresponding models within the `boot` method of your application's `AppServiceProvider`:

    use App\Models\Order;
    use App\Policies\OrderPolicy;
    use Illuminate\Support\Facades\Gate;

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(Order::class, OrderPolicy::class);
    }

<a name="writing-policies"></a>
## Writing Policies

<a name="policy-methods"></a>
### Policy Methods

Once the policy class has been registered, you may add methods for each action it authorizes. For example, let's define an `update` method on our `PostPolicy` which determines if a given `App\Models\User` can update a given `App\Models\Post` instance.

The `update` method will receive a `User` and a `Post` instance as its arguments, and should return `true` or `false` indicating whether the user is authorized to update the given `Post`. So, in this example, we will verify that the user's `id` matches the `user_id` on the post:

    <?php

    namespace App\Policies;

    use App\Models\Post;
    use App\Models\User;

    class PostPolicy
    {
        /**
         * Determine if the given post can be updated by the user.
         */
        public function update(User $user, Post $post): bool
        {
            return $user->id === $post->user_id;
        }
    }

You may continue to define additional methods on the policy as needed for the various actions it authorizes. For example, you might define `view` or `delete` methods to authorize various `Post` related actions, but remember you are free to give your policy methods any name you like.

If you used the `--model` option when generating your policy via the Artisan console, it will already contain methods for the `viewAny`, `view`, `create`, `update`, `delete`, `restore`, and `forceDelete` actions.

> [!NOTE]  
> All policies are resolved via the Laravel [service container](/docs/{{version}}/container), allowing you to type-hint any needed dependencies in the policy's constructor to have them automatically injected.

<a name="policy-responses"></a>
### Policy Responses

So far, we have only examined policy methods that return simple boolean values. However, sometimes you may wish to return a more detailed response, including an error message. To do so, you may return an `Illuminate\Auth\Access\Response` instance from your policy method:

    use App\Models\Post;
    use App\Models\User;
    use Illuminate\Auth\Access\Response;

    /**
     * Determine if the given post can be updated by the user.
     */
    public function update(User $user, Post $post): Response
    {
        return $user->id === $post->user_id
            ? Response::allow()
            : Response::deny('You do not own this post.');
    }

When returning an authorization response from your policy, the `Gate::allows` method will still return a simple boolean value; however, you may use the `Gate::inspect` method to get the full authorization response returned by the gate:

    use Illuminate\Support\Facades\Gate;

    $response = Gate::inspect('update', $post);

    if ($response->allowed()) {
        // The action is authorized...
    } else {
        echo $response->message();
    }

When using the `Gate::authorize` method, which throws an `AuthorizationException` if the action is not authorized, the error message provided by the authorization response will be propagated to the HTTP response:

    Gate::authorize('update', $post);

    // The action is authorized...

<a name="customizing-policy-response-status"></a>
#### Customizing the HTTP Response Status

When an action is denied via a policy method, a `403` HTTP response is returned; however, it can sometimes be useful to return an alternative HTTP status code. You may customize the HTTP status code returned for a failed authorization check using the `denyWithStatus` static constructor on the `Illuminate\Auth\Access\Response` class:

    use App\Models\Post;
    use App\Models\User;
    use Illuminate\Auth\Access\Response;

    /**
     * Determine if the given post can be updated by the user.
     */
    public function update(User $user, Post $post): Response
    {
        return $user->id === $post->user_id
            ? Response::allow()
            : Response::denyWithStatus(404);
    }

Because hiding resources via a `404` response is such a common pattern for web applications, the `denyAsNotFound` method is offered for convenience:

    use App\Models\Post;
    use App\Models\User;
    use Illuminate\Auth\Access\Response;

    /**
     * Determine if the given post can be updated by the user.
     */
    public function update(User $user, Post $post): Response
    {
        return $user->id === $post->user_id
            ? Response::allow()
            : Response::denyAsNotFound();
    }

<a name="methods-without-models"></a>
### Methods Without Models

Some policy methods only receive an instance of the currently authenticated user. This situation is most common when authorizing `create` actions. For example, if you are creating a blog, you may wish to determine if a user is authorized to create any posts at all. In these situations, your policy method should only expect to receive a user instance:

    /**
     * Determine if the given user can create posts.
     */
    public function create(User $user): bool
    {
        return $user->role == 'writer';
    }

<a name="guest-users"></a>
### Guest Users

By default, all gates and policies automatically return `false` if the incoming HTTP request was not initiated by an authenticated user. However, you may allow these authorization checks to pass through to your gates and policies by declaring an "optional" type-hint or supplying a `null` default value for the user argument definition:

    <?php

    namespace App\Policies;

    use App\Models\Post;
    use App\Models\User;

    class PostPolicy
    {
        /**
         * Determine if the given post can be updated by the user.
         */
        public function update(?User $user, Post $post): bool
        {
            return $user?->id === $post->user_id;
        }
    }

<a name="policy-filters"></a>
### Policy Filters

For certain users, you may wish to authorize all actions within a given policy. To accomplish this, define a `before` method on the policy. The `before` method will be executed before any other methods on the policy, giving you an opportunity to authorize the action before the intended policy method is actually called. This feature is most commonly used for authorizing application administrators to perform any action:

    use App\Models\User;

    /**
     * Perform pre-authorization checks.
     */
    public function before(User $user, string $ability): bool|null
    {
        if ($user->isAdministrator()) {
            return true;
        }

        return null;
    }

If you would like to deny all authorization checks for a particular type of user then you may return `false` from the `before` method. If `null` is returned, the authorization check will fall through to the policy method.

> [!WARNING]  
> The `before` method of a policy class will not be called if the class doesn't contain a method with a name matching the name of the ability being checked.

<a name="authorizing-actions-using-policies"></a>
## Authorizing Actions Using Policies

<a name="via-the-user-model"></a>
### Via the User Model

The `App\Models\User` model that is included with your Laravel application includes two helpful methods for authorizing actions: `can` and `cannot`. The `can` and `cannot` methods receive the name of the action you wish to authorize and the relevant model. For example, let's determine if a user is authorized to update a given `App\Models\Post` model. Typically, this will be done within a controller method:

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;

    class PostController extends Controller
    {
        /**
         * Update the given post.
         */
        public function update(Request $request, Post $post): RedirectResponse
        {
            if ($request->user()->cannot('update', $post)) {
                abort(403);
            }

            // Update the post...

            return redirect('/posts');
        }
    }

If a [policy is registered](#registering-policies) for the given model, the `can` method will automatically call the appropriate policy and return the boolean result. If no policy is registered for the model, the `can` method will attempt to call the closure-based Gate matching the given action name.

<a name="user-model-actions-that-dont-require-models"></a>
#### Actions That Don't Require Models

Remember, some actions may correspond to policy methods like `create` that do not require a model instance. In these situations, you may pass a class name to the `can` method. The class name will be used to determine which policy to use when authorizing the action:

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;

    class PostController extends Controller
    {
        /**
         * Create a post.
         */
        public function store(Request $request): RedirectResponse
        {
            if ($request->user()->cannot('create', Post::class)) {
                abort(403);
            }

            // Create the post...

            return redirect('/posts');
        }
    }

<a name="via-the-gate-facade"></a>
### Via the `Gate` Facade

In addition to helpful methods provided to the `App\Models\User` model, you can always authorize actions via the `Gate` facade's `authorize` method.

Like the `can` method, this method accepts the name of the action you wish to authorize and the relevant model. If the action is not authorized, the `authorize` method will throw an `Illuminate\Auth\Access\AuthorizationException` exception which the Laravel exception handler will automatically convert to an HTTP response with a 403 status code:

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Gate;

    class PostController extends Controller
    {
        /**
         * Update the given blog post.
         *
         * @throws \Illuminate\Auth\Access\AuthorizationException
         */
        public function update(Request $request, Post $post): RedirectResponse
        {
            Gate::authorize('update', $post);

            // The current user can update the blog post...

            return redirect('/posts');
        }
    }

<a name="controller-actions-that-dont-require-models"></a>
#### Actions That Don't Require Models

As previously discussed, some policy methods like `create` do not require a model instance. In these situations, you should pass a class name to the `authorize` method. The class name will be used to determine which policy to use when authorizing the action:

    use App\Models\Post;
    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Gate;

    /**
     * Create a new blog post.
     *
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function create(Request $request): RedirectResponse
    {
        Gate::authorize('create', Post::class);

        // The current user can create blog posts...

        return redirect('/posts');
    }

<a name="via-middleware"></a>
### Via Middleware

Laravel includes a middleware that can authorize actions before the incoming request even reaches your routes or controllers. By default, the `Illuminate\Auth\Middleware\Authorize` middleware may be attached to a route using the `can` [middleware alias](/docs/{{version}}/middleware#middleware-aliases), which is automatically registered by Laravel. Let's explore an example of using the `can` middleware to authorize that a user can update a post:

    use App\Models\Post;

    Route::put('/post/{post}', function (Post $post) {
        // The current user may update the post...
    })->middleware('can:update,post');

In this example, we're passing the `can` middleware two arguments. The first is the name of the action we wish to authorize and the second is the route parameter we wish to pass to the policy method. In this case, since we are using [implicit model binding](/docs/{{version}}/routing#implicit-binding), an `App\Models\Post` model will be passed to the policy method. If the user is not authorized to perform the given action, an HTTP response with a 403 status code will be returned by the middleware.

For convenience, you may also attach the `can` middleware to your route using the `can` method:

    use App\Models\Post;

    Route::put('/post/{post}', function (Post $post) {
        // The current user may update the post...
    })->can('update', 'post');

<a name="middleware-actions-that-dont-require-models"></a>
#### Actions That Don't Require Models

Again, some policy methods like `create` do not require a model instance. In these situations, you may pass a class name to the middleware. The class name will be used to determine which policy to use when authorizing the action:

    Route::post('/post', function () {
        // The current user may create posts...
    })->middleware('can:create,App\Models\Post');

Specifying the entire class name within a string middleware definition can become cumbersome. For that reason, you may choose to attach the `can` middleware to your route using the `can` method:

    use App\Models\Post;

    Route::post('/post', function () {
        // The current user may create posts...
    })->can('create', Post::class);

<a name="via-blade-templates"></a>
### Via Blade Templates

When writing Blade templates, you may wish to display a portion of the page only if the user is authorized to perform a given action. For example, you may wish to show an update form for a blog post only if the user can actually update the post. In this situation, you may use the `@can` and `@cannot` directives:

```blade
@can('update', $post)
    <!-- The current user can update the post... -->
@elsecan('create', App\Models\Post::class)
    <!-- The current user can create new posts... -->
@else
    <!-- ... -->
@endcan

@cannot('update', $post)
    <!-- The current user cannot update the post... -->
@elsecannot('create', App\Models\Post::class)
    <!-- The current user cannot create new posts... -->
@endcannot
```

These directives are convenient shortcuts for writing `@if` and `@unless` statements. The `@can` and `@cannot` statements above are equivalent to the following statements:

```blade
@if (Auth::user()->can('update', $post))
    <!-- The current user can update the post... -->
@endif

@unless (Auth::user()->can('update', $post))
    <!-- The current user cannot update the post... -->
@endunless
```

You may also determine if a user is authorized to perform any action from a given array of actions. To accomplish this, use the `@canany` directive:

```blade
@canany(['update', 'view', 'delete'], $post)
    <!-- The current user can update, view, or delete the post... -->
@elsecanany(['create'], \App\Models\Post::class)
    <!-- The current user can create a post... -->
@endcanany
```

<a name="blade-actions-that-dont-require-models"></a>
#### Actions That Don't Require Models

Like most of the other authorization methods, you may pass a class name to the `@can` and `@cannot` directives if the action does not require a model instance:

```blade
@can('create', App\Models\Post::class)
    <!-- The current user can create posts... -->
@endcan

@cannot('create', App\Models\Post::class)
    <!-- The current user can't create posts... -->
@endcannot
```

<a name="supplying-additional-context"></a>
### Supplying Additional Context

When authorizing actions using policies, you may pass an array as the second argument to the various authorization functions and helpers. The first element in the array will be used to determine which policy should be invoked, while the rest of the array elements are passed as parameters to the policy method and can be used for additional context when making authorization decisions. For example, consider the following `PostPolicy` method definition which contains an additional `$category` parameter:

    /**
     * Determine if the given post can be updated by the user.
     */
    public function update(User $user, Post $post, int $category): bool
    {
        return $user->id === $post->user_id &&
               $user->canUpdateCategory($category);
    }

When attempting to determine if the authenticated user can update a given post, we can invoke this policy method like so:

    /**
     * Update the given blog post.
     *
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(Request $request, Post $post): RedirectResponse
    {
        Gate::authorize('update', [$post, $request->category]);

        // The current user can update the blog post...

        return redirect('/posts');
    }

<a name="authorization-and-inertia"></a>
## Authorization & Inertia

Although authorization must always be handled on the server, it can often be convenient to provide your frontend application with authorization data in order to properly render your application's UI. Laravel does not define a required convention for exposing authorization information to an Inertia powered frontend.

However, if you are using one of Laravel's Inertia-based [starter kits](/docs/{{version}}/starter-kits), your application already contains a `HandleInertiaRequests` middleware. Within this middleware's `share` method, you may return shared data that will be provided to all Inertia pages in your application. This shared data can serve as a convenient location to define authorization information for the user:

```php
<?php

namespace App\Http\Middleware;

use App\Models\Post;
use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    // ...

    /**
     * Define the props that are shared by default.
     *
     * @return array<string, mixed>
     */
    public function share(Request $request)
    {
        return [
            ...parent::share($request),
            'auth' => [
                'user' => $request->user(),
                'permissions' => [
                    'post' => [
                        'create' => $request->user()->can('create', Post::class),
                    ],
                ],
            ],
        ];
    }
}
```


