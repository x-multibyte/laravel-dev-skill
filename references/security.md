# Security


## Csrf

# CSRF Protection

- [Introduction](#csrf-introduction)
- [Preventing CSRF Requests](#preventing-csrf-requests)
    - [Excluding URIs](#csrf-excluding-uris)
- [X-CSRF-Token](#csrf-x-csrf-token)
- [X-XSRF-Token](#csrf-x-xsrf-token)

<a name="csrf-introduction"></a>
## Introduction

Cross-site request forgeries are a type of malicious exploit whereby unauthorized commands are performed on behalf of an authenticated user. Thankfully, Laravel makes it easy to protect your application from [cross-site request forgery](https://en.wikipedia.org/wiki/Cross-site_request_forgery) (CSRF) attacks.

<a name="csrf-explanation"></a>
#### An Explanation of the Vulnerability

In case you're not familiar with cross-site request forgeries, let's discuss an example of how this vulnerability can be exploited. Imagine your application has a `/user/email` route that accepts a `POST` request to change the authenticated user's email address. Most likely, this route expects an `email` input field to contain the email address the user would like to begin using.

Without CSRF protection, a malicious website could create an HTML form that points to your application's `/user/email` route and submits the malicious user's own email address:

```blade
<form action="https://your-application.com/user/email" method="POST">
    <input type="email" value="malicious-email@example.com">
</form>

<script>
    document.forms[0].submit();
</script>
```

If the malicious website automatically submits the form when the page is loaded, the malicious user only needs to lure an unsuspecting user of your application to visit their website and their email address will be changed in your application.

To prevent this vulnerability, we need to inspect every incoming `POST`, `PUT`, `PATCH`, or `DELETE` request for a secret session value that the malicious application is unable to access.

<a name="preventing-csrf-requests"></a>
## Preventing CSRF Requests

Laravel automatically generates a CSRF "token" for each active [user session](/docs/{{version}}/session) managed by the application. This token is used to verify that the authenticated user is the person actually making the requests to the application. Since this token is stored in the user's session and changes each time the session is regenerated, a malicious application is unable to access it.

The current session's CSRF token can be accessed via the request's session or via the `csrf_token` helper function:

```php
use Illuminate\Http\Request;

Route::get('/token', function (Request $request) {
    $token = $request->session()->token();

    $token = csrf_token();

    // ...
});
```

Anytime you define a "POST", "PUT", "PATCH", or "DELETE" HTML form in your application, you should include a hidden CSRF `_token` field in the form so that the CSRF protection middleware can validate the request. For convenience, you may use the `@csrf` Blade directive to generate the hidden token input field:

```blade
<form method="POST" action="/profile">
    @csrf

    <!-- Equivalent to... -->
    <input type="hidden" name="_token" value="{{ csrf_token() }}" />
</form>
```

The `Illuminate\Foundation\Http\Middleware\ValidateCsrfToken` [middleware](/docs/{{version}}/middleware), which is included in the `web` middleware group by default, will automatically verify that the token in the request input matches the token stored in the session. When these two tokens match, we know that the authenticated user is the one initiating the request.

<a name="csrf-tokens-and-spas"></a>
### CSRF Tokens & SPAs

If you are building an SPA that is utilizing Laravel as an API backend, you should consult the [Laravel Sanctum documentation](/docs/{{version}}/sanctum) for information on authenticating with your API and protecting against CSRF vulnerabilities.

<a name="csrf-excluding-uris"></a>
### Excluding URIs From CSRF Protection

Sometimes you may wish to exclude a set of URIs from CSRF protection. For example, if you are using [Stripe](https://stripe.com) to process payments and are utilizing their webhook system, you will need to exclude your Stripe webhook handler route from CSRF protection since Stripe will not know what CSRF token to send to your routes.

Typically, you should place these kinds of routes outside of the `web` middleware group that Laravel applies to all routes in the `routes/web.php` file. However, you may also exclude specific routes by providing their URIs to the `validateCsrfTokens` method in your application's `bootstrap/app.php` file:

```php
->withMiddleware(function (Middleware $middleware): void {
    $middleware->validateCsrfTokens(except: [
        'stripe/*',
        'http://example.com/foo/bar',
        'http://example.com/foo/*',
    ]);
})
```

> [!NOTE]
> For convenience, the CSRF middleware is automatically disabled for all routes when [running tests](/docs/{{version}}/testing).

<a name="csrf-x-csrf-token"></a>
## X-CSRF-TOKEN

In addition to checking for the CSRF token as a POST parameter, the `Illuminate\Foundation\Http\Middleware\ValidateCsrfToken` middleware, which is included in the `web` middleware group by default, will also check for the `X-CSRF-TOKEN` request header. You could, for example, store the token in an HTML `meta` tag:

```blade
<meta name="csrf-token" content="{{ csrf_token() }}">
```

Then, you can instruct a library like jQuery to automatically add the token to all request headers. This provides simple, convenient CSRF protection for your AJAX based applications using legacy JavaScript technology:

```js
$.ajaxSetup({
    headers: {
        'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
    }
});
```

<a name="csrf-x-xsrf-token"></a>
## X-XSRF-TOKEN

Laravel stores the current CSRF token in an encrypted `XSRF-TOKEN` cookie that is included with each response generated by the framework. You can use the cookie value to set the `X-XSRF-TOKEN` request header.

This cookie is primarily sent as a developer convenience since some JavaScript frameworks and libraries, like Angular and Axios, automatically place its value in the `X-XSRF-TOKEN` header on same-origin requests.

> [!NOTE]
> By default, the `resources/js/bootstrap.js` file includes the Axios HTTP library which will automatically send the `X-XSRF-TOKEN` header for you.



## Encryption

# Encryption

- [Introduction](#introduction)
- [Configuration](#configuration)
    - [Gracefully Rotating Encryption Keys](#gracefully-rotating-encryption-keys)
- [Using the Encrypter](#using-the-encrypter)

<a name="introduction"></a>
## Introduction

Laravel's encryption services provide a simple, convenient interface for encrypting and decrypting text via OpenSSL using AES-256 and AES-128 encryption. All of Laravel's encrypted values are signed using a message authentication code (MAC) so that their underlying value cannot be modified or tampered with once encrypted.

<a name="configuration"></a>
## Configuration

Before using Laravel's encrypter, you must set the `key` configuration option in your `config/app.php` configuration file. This configuration value is driven by the `APP_KEY` environment variable. You should use the `php artisan key:generate` command to generate this variable's value since the `key:generate` command will use PHP's secure random bytes generator to build a cryptographically secure key for your application. Typically, the value of the `APP_KEY` environment variable will be generated for you during [Laravel's installation](/docs/{{version}}/installation).

<a name="gracefully-rotating-encryption-keys"></a>
### Gracefully Rotating Encryption Keys

If you change your application's encryption key, all authenticated user sessions will be logged out of your application. This is because every cookie, including session cookies, are encrypted by Laravel. In addition, it will no longer be possible to decrypt any data that was encrypted with your previous encryption key.

To mitigate this issue, Laravel allows you to list your previous encryption keys in your application's `APP_PREVIOUS_KEYS` environment variable. This variable may contain a comma-delimited list of all of your previous encryption keys:

```ini
APP_KEY="base64:J63qRTDLub5NuZvP+kb8YIorGS6qFYHKVo6u7179stY="
APP_PREVIOUS_KEYS="base64:2nLsGFGzyoae2ax3EF2Lyq/hH6QghBGLIq5uL+Gp8/w="
```

When you set this environment variable, Laravel will always use the "current" encryption key when encrypting values. However, when decrypting values, Laravel will first try the current key, and if decryption fails using the current key, Laravel will try all previous keys until one of the keys is able to decrypt the value.

This approach to graceful decryption allows users to keep using your application uninterrupted even if your encryption key is rotated.

<a name="using-the-encrypter"></a>
## Using the Encrypter

<a name="encrypting-a-value"></a>
#### Encrypting a Value

You may encrypt a value using the `encryptString` method provided by the `Crypt` facade. All encrypted values are encrypted using OpenSSL and the AES-256-CBC cipher. Furthermore, all encrypted values are signed with a message authentication code (MAC). The integrated message authentication code will prevent the decryption of any values that have been tampered with by malicious users:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;

class DigitalOceanTokenController extends Controller
{
    /**
     * Store a DigitalOcean API token for the user.
     */
    public function store(Request $request): RedirectResponse
    {
        $request->user()->fill([
            'token' => Crypt::encryptString($request->token),
        ])->save();

        return redirect('/secrets');
    }
}
```

<a name="decrypting-a-value"></a>
#### Decrypting a Value

You may decrypt values using the `decryptString` method provided by the `Crypt` facade. If the value cannot be properly decrypted, such as when the message authentication code is invalid, an `Illuminate\Contracts\Encryption\DecryptException` will be thrown:

```php
use Illuminate\Contracts\Encryption\DecryptException;
use Illuminate\Support\Facades\Crypt;

try {
    $decrypted = Crypt::decryptString($encryptedValue);
} catch (DecryptException $e) {
    // ...
}
```



## Hashing

# Hashing

- [Introduction](#introduction)
- [Configuration](#configuration)
- [Basic Usage](#basic-usage)
    - [Hashing Passwords](#hashing-passwords)
    - [Verifying That a Password Matches a Hash](#verifying-that-a-password-matches-a-hash)
    - [Determining if a Password Needs to be Rehashed](#determining-if-a-password-needs-to-be-rehashed)
- [Hash Algorithm Verification](#hash-algorithm-verification)

<a name="introduction"></a>
## Introduction

The Laravel `Hash` [facade](/docs/{{version}}/facades) provides secure Bcrypt and Argon2 hashing for storing user passwords. If you are using one of the [Laravel application starter kits](/docs/{{version}}/starter-kits), Bcrypt will be used for registration and authentication by default.

Bcrypt is a great choice for hashing passwords because its "work factor" is adjustable, which means that the time it takes to generate a hash can be increased as hardware power increases. When hashing passwords, slow is good. The longer an algorithm takes to hash a password, the longer it takes malicious users to generate "rainbow tables" of all possible string hash values that may be used in brute force attacks against applications.

<a name="configuration"></a>
## Configuration

By default, Laravel uses the `bcrypt` hashing driver when hashing data. However, several other hashing drivers are supported, including [argon](https://en.wikipedia.org/wiki/Argon2) and [argon2id](https://en.wikipedia.org/wiki/Argon2).

You may specify your application's hashing driver using the `HASH_DRIVER` environment variable. But, if you want to customize all of Laravel's hashing driver options, you should publish the complete `hashing` configuration file using the `config:publish` Artisan command:

```shell
php artisan config:publish hashing
```

<a name="basic-usage"></a>
## Basic Usage

<a name="hashing-passwords"></a>
### Hashing Passwords

You may hash a password by calling the `make` method on the `Hash` facade:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class PasswordController extends Controller
{
    /**
     * Update the password for the user.
     */
    public function update(Request $request): RedirectResponse
    {
        // Validate the new password length...

        $request->user()->fill([
            'password' => Hash::make($request->newPassword)
        ])->save();

        return redirect('/profile');
    }
}
```

<a name="adjusting-the-bcrypt-work-factor"></a>
#### Adjusting The Bcrypt Work Factor

If you are using the Bcrypt algorithm, the `make` method allows you to manage the work factor of the algorithm using the `rounds` option; however, the default work factor managed by Laravel is acceptable for most applications:

```php
$hashed = Hash::make('password', [
    'rounds' => 12,
]);
```

<a name="adjusting-the-argon2-work-factor"></a>
#### Adjusting The Argon2 Work Factor

If you are using the Argon2 algorithm, the `make` method allows you to manage the work factor of the algorithm using the `memory`, `time`, and `threads` options; however, the default values managed by Laravel are acceptable for most applications:

```php
$hashed = Hash::make('password', [
    'memory' => 1024,
    'time' => 2,
    'threads' => 2,
]);
```

> [!NOTE]
> For more information on these options, please refer to the [official PHP documentation regarding Argon hashing](https://secure.php.net/manual/en/function.password-hash.php).

<a name="verifying-that-a-password-matches-a-hash"></a>
### Verifying That a Password Matches a Hash

The `check` method provided by the `Hash` facade allows you to verify that a given plain-text string corresponds to a given hash:

```php
if (Hash::check('plain-text', $hashedPassword)) {
    // The passwords match...
}
```

<a name="determining-if-a-password-needs-to-be-rehashed"></a>
### Determining if a Password Needs to be Rehashed

The `needsRehash` method provided by the `Hash` facade allows you to determine if the work factor used by the hasher has changed since the password was hashed. Some applications choose to perform this check during the application's authentication process:

```php
if (Hash::needsRehash($hashed)) {
    $hashed = Hash::make('plain-text');
}
```

<a name="hash-algorithm-verification"></a>
## Hash Algorithm Verification

To prevent hash algorithm manipulation, Laravel's `Hash::check` method will first verify the given hash was generated using the application's selected hashing algorithm. If the algorithms are different, a `RuntimeException` exception will be thrown.

This is the expected behavior for most applications, where the hashing algorithm is not expected to change and different algorithms can be an indication of a malicious attack. However, if you need to support multiple hashing algorithms within your application, such as when migrating from one algorithm to another, you can disable hash algorithm verification by setting the `HASH_VERIFY` environment variable to `false`:

```ini
HASH_VERIFY=false
```


