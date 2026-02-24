# Requests


## Http-Client

# HTTP Client

- [Introduction](#introduction)
- [Making Requests](#making-requests)
    - [Request Data](#request-data)
    - [Headers](#headers)
    - [Authentication](#authentication)
    - [Timeout](#timeout)
    - [Retries](#retries)
    - [Error Handling](#error-handling)
    - [Guzzle Middleware](#guzzle-middleware)
    - [Guzzle Options](#guzzle-options)
- [Concurrent Requests](#concurrent-requests)
- [Macros](#macros)
- [Testing](#testing)
    - [Faking Responses](#faking-responses)
    - [Inspecting Requests](#inspecting-requests)
    - [Preventing Stray Requests](#preventing-stray-requests)
- [Events](#events)

<a name="introduction"></a>
## Introduction

Laravel provides an expressive, minimal API around the [Guzzle HTTP client](http://docs.guzzlephp.org/en/stable/), allowing you to quickly make outgoing HTTP requests to communicate with other web applications. Laravel's wrapper around Guzzle is focused on its most common use cases and a wonderful developer experience.

Before getting started, you should ensure that you have installed the Guzzle package as a dependency of your application. By default, Laravel automatically includes this dependency. However, if you have previously removed the package, you may install it again via Composer:

```shell
composer require guzzlehttp/guzzle
```

<a name="making-requests"></a>
## Making Requests

To make requests, you may use the `head`, `get`, `post`, `put`, `patch`, and `delete` methods provided by the `Http` facade. First, let's examine how to make a basic `GET` request to another URL:

    use Illuminate\Support\Facades\Http;

    $response = Http::get('http://example.com');

The `get` method returns an instance of `Illuminate\Http\Client\Response`, which provides a variety of methods that may be used to inspect the response:

    $response->body() : string;
    $response->json($key = null, $default = null) : array|mixed;
    $response->object() : object;
    $response->collect($key = null) : Illuminate\Support\Collection;
    $response->status() : int;
    $response->successful() : bool;
    $response->redirect(): bool;
    $response->failed() : bool;
    $response->clientError() : bool;
    $response->header($header) : string;
    $response->headers() : array;

The `Illuminate\Http\Client\Response` object also implements the PHP `ArrayAccess` interface, allowing you to access JSON response data directly on the response:

    return Http::get('http://example.com/users/1')['name'];

In addition to the response methods listed above, the following methods may be used to determine if the response has a given status code:

    $response->ok() : bool;                  // 200 OK
    $response->created() : bool;             // 201 Created
    $response->accepted() : bool;            // 202 Accepted
    $response->noContent() : bool;           // 204 No Content
    $response->movedPermanently() : bool;    // 301 Moved Permanently
    $response->found() : bool;               // 302 Found
    $response->badRequest() : bool;          // 400 Bad Request
    $response->unauthorized() : bool;        // 401 Unauthorized
    $response->paymentRequired() : bool;     // 402 Payment Required
    $response->forbidden() : bool;           // 403 Forbidden
    $response->notFound() : bool;            // 404 Not Found
    $response->requestTimeout() : bool;      // 408 Request Timeout
    $response->conflict() : bool;            // 409 Conflict
    $response->unprocessableEntity() : bool; // 422 Unprocessable Entity
    $response->tooManyRequests() : bool;     // 429 Too Many Requests
    $response->serverError() : bool;         // 500 Internal Server Error

<a name="uri-templates"></a>
#### URI Templates

The HTTP client also allows you to construct request URLs using the [URI template specification](https://www.rfc-editor.org/rfc/rfc6570). To define the URL parameters that can be expanded by your URI template, you may use the `withUrlParameters` method:

```php
Http::withUrlParameters([
    'endpoint' => 'https://laravel.com',
    'page' => 'docs',
    'version' => '9.x',
    'topic' => 'validation',
])->get('{+endpoint}/{page}/{version}/{topic}');
```

<a name="dumping-requests"></a>
#### Dumping Requests

If you would like to dump the outgoing request instance before it is sent and terminate the script's execution, you may add the `dd` method to the beginning of your request definition:

    return Http::dd()->get('http://example.com');

<a name="request-data"></a>
### Request Data

Of course, it is common when making `POST`, `PUT`, and `PATCH` requests to send additional data with your request, so these methods accept an array of data as their second argument. By default, data will be sent using the `application/json` content type:

    use Illuminate\Support\Facades\Http;

    $response = Http::post('http://example.com/users', [
        'name' => 'Steve',
        'role' => 'Network Administrator',
    ]);

<a name="get-request-query-parameters"></a>
#### GET Request Query Parameters

When making `GET` requests, you may either append a query string to the URL directly or pass an array of key / value pairs as the second argument to the `get` method:

    $response = Http::get('http://example.com/users', [
        'name' => 'Taylor',
        'page' => 1,
    ]);

Alternatively, the `withQueryParameters` method may be used:

    Http::retry(3, 100)->withQueryParameters([
        'name' => 'Taylor',
        'page' => 1,
    ])->get('http://example.com/users')

<a name="sending-form-url-encoded-requests"></a>
#### Sending Form URL Encoded Requests

If you would like to send data using the `application/x-www-form-urlencoded` content type, you should call the `asForm` method before making your request:

    $response = Http::asForm()->post('http://example.com/users', [
        'name' => 'Sara',
        'role' => 'Privacy Consultant',
    ]);

<a name="sending-a-raw-request-body"></a>
#### Sending a Raw Request Body

You may use the `withBody` method if you would like to provide a raw request body when making a request. The content type may be provided via the method's second argument:

    $response = Http::withBody(
        base64_encode($photo), 'image/jpeg'
    )->post('http://example.com/photo');

<a name="multi-part-requests"></a>
#### Multi-Part Requests

If you would like to send files as multi-part requests, you should call the `attach` method before making your request. This method accepts the name of the file and its contents. If needed, you may provide a third argument which will be considered the file's filename, while a fourth argument may be used to provide headers associated with the file:

    $response = Http::attach(
        'attachment', file_get_contents('photo.jpg'), 'photo.jpg', ['Content-Type' => 'image/jpeg']
    )->post('http://example.com/attachments');

Instead of passing the raw contents of a file, you may pass a stream resource:

    $photo = fopen('photo.jpg', 'r');

    $response = Http::attach(
        'attachment', $photo, 'photo.jpg'
    )->post('http://example.com/attachments');

<a name="headers"></a>
### Headers

Headers may be added to requests using the `withHeaders` method. This `withHeaders` method accepts an array of key / value pairs:

    $response = Http::withHeaders([
        'X-First' => 'foo',
        'X-Second' => 'bar'
    ])->post('http://example.com/users', [
        'name' => 'Taylor',
    ]);

You may use the `accept` method to specify the content type that your application is expecting in response to your request:

    $response = Http::accept('application/json')->get('http://example.com/users');

For convenience, you may use the `acceptJson` method to quickly specify that your application expects the `application/json` content type in response to your request:

    $response = Http::acceptJson()->get('http://example.com/users');

The `withHeaders` method merges new headers into the request's existing headers. If needed, you may replace all of the headers entirely using the `replaceHeaders` method:

```php
$response = Http::withHeaders([
    'X-Original' => 'foo',
])->replaceHeaders([
    'X-Replacement' => 'bar',
])->post('http://example.com/users', [
    'name' => 'Taylor',
]);
```

<a name="authentication"></a>
### Authentication

You may specify basic and digest authentication credentials using the `withBasicAuth` and `withDigestAuth` methods, respectively:

    // Basic authentication...
    $response = Http::withBasicAuth('taylor@laravel.com', 'secret')->post(/* ... */);

    // Digest authentication...
    $response = Http::withDigestAuth('taylor@laravel.com', 'secret')->post(/* ... */);

<a name="bearer-tokens"></a>
#### Bearer Tokens

If you would like to quickly add a bearer token to the request's `Authorization` header, you may use the `withToken` method:

    $response = Http::withToken('token')->post(/* ... */);

<a name="timeout"></a>
### Timeout

The `timeout` method may be used to specify the maximum number of seconds to wait for a response. By default, the HTTP client will timeout after 30 seconds:

    $response = Http::timeout(3)->get(/* ... */);

If the given timeout is exceeded, an instance of `Illuminate\Http\Client\ConnectionException` will  be thrown.

You may specify the maximum number of seconds to wait while trying to connect to a server using the `connectTimeout` method:

    $response = Http::connectTimeout(3)->get(/* ... */);

<a name="retries"></a>
### Retries

If you would like the HTTP client to automatically retry the request if a client or server error occurs, you may use the `retry` method. The `retry` method accepts the maximum number of times the request should be attempted and the number of milliseconds that Laravel should wait in between attempts:

    $response = Http::retry(3, 100)->post(/* ... */);

If you would like to manually calculate the number of milliseconds to sleep between attempts, you may pass a closure as the second argument to the `retry` method:

    use Exception;

    $response = Http::retry(3, function (int $attempt, Exception $exception) {
        return $attempt * 100;
    })->post(/* ... */);

For convenience, you may also provide an array as the first argument to the `retry` method. This array will be used to determine how many milliseconds to sleep between subsequent attempts:

    $response = Http::retry([100, 200])->post(/* ... */);

If needed, you may pass a third argument to the `retry` method. The third argument should be a callable that determines if the retries should actually be attempted. For example, you may wish to only retry the request if the initial request encounters an `ConnectionException`:

    use Exception;
    use Illuminate\Http\Client\PendingRequest;

    $response = Http::retry(3, 100, function (Exception $exception, PendingRequest $request) {
        return $exception instanceof ConnectionException;
    })->post(/* ... */);

If a request attempt fails, you may wish to make a change to the request before a new attempt is made. You can achieve this by modifying the request argument provided to the callable you provided to the `retry` method. For example, you might want to retry the request with a new authorization token if the first attempt returned an authentication error:

    use Exception;
    use Illuminate\Http\Client\PendingRequest;
    use Illuminate\Http\Client\RequestException;

    $response = Http::withToken($this->getToken())->retry(2, 0, function (Exception $exception, PendingRequest $request) {
        if (! $exception instanceof RequestException || $exception->response->status() !== 401) {
            return false;
        }

        $request->withToken($this->getNewToken());

        return true;
    })->post(/* ... */);

If all of the requests fail, an instance of `Illuminate\Http\Client\RequestException` will be thrown. If you would like to disable this behavior, you may provide a `throw` argument with a value of `false`. When disabled, the last response received by the client will be returned after all retries have been attempted:

    $response = Http::retry(3, 100, throw: false)->post(/* ... */);

> [!WARNING]  
> If all of the requests fail because of a connection issue, a `Illuminate\Http\Client\ConnectionException` will still be thrown even when the `throw` argument is set to `false`.

<a name="error-handling"></a>
### Error Handling

Unlike Guzzle's default behavior, Laravel's HTTP client wrapper does not throw exceptions on client or server errors (`400` and `500` level responses from servers). You may determine if one of these errors was returned using the `successful`, `clientError`, or `serverError` methods:

    // Determine if the status code is >= 200 and < 300...
    $response->successful();

    // Determine if the status code is >= 400...
    $response->failed();

    // Determine if the response has a 400 level status code...
    $response->clientError();

    // Determine if the response has a 500 level status code...
    $response->serverError();

    // Immediately execute the given callback if there was a client or server error...
    $response->onError(callable $callback);

<a name="throwing-exceptions"></a>
#### Throwing Exceptions

If you have a response instance and would like to throw an instance of `Illuminate\Http\Client\RequestException` if the response status code indicates a client or server error, you may use the `throw` or `throwIf` methods:

    use Illuminate\Http\Client\Response;

    $response = Http::post(/* ... */);

    // Throw an exception if a client or server error occurred...
    $response->throw();

    // Throw an exception if an error occurred and the given condition is true...
    $response->throwIf($condition);

    // Throw an exception if an error occurred and the given closure resolves to true...
    $response->throwIf(fn (Response $response) => true);

    // Throw an exception if an error occurred and the given condition is false...
    $response->throwUnless($condition);

    // Throw an exception if an error occurred and the given closure resolves to false...
    $response->throwUnless(fn (Response $response) => false);

    // Throw an exception if the response has a specific status code...
    $response->throwIfStatus(403);

    // Throw an exception unless the response has a specific status code...
    $response->throwUnlessStatus(200);

    return $response['user']['id'];

The `Illuminate\Http\Client\RequestException` instance has a public `$response` property which will allow you to inspect the returned response.

The `throw` method returns the response instance if no error occurred, allowing you to chain other operations onto the `throw` method:

    return Http::post(/* ... */)->throw()->json();

If you would like to perform some additional logic before the exception is thrown, you may pass a closure to the `throw` method. The exception will be thrown automatically after the closure is invoked, so you do not need to re-throw the exception from within the closure:

    use Illuminate\Http\Client\Response;
    use Illuminate\Http\Client\RequestException;

    return Http::post(/* ... */)->throw(function (Response $response, RequestException $e) {
        // ...
    })->json();

<a name="guzzle-middleware"></a>
### Guzzle Middleware

Since Laravel's HTTP client is powered by Guzzle, you may take advantage of [Guzzle Middleware](https://docs.guzzlephp.org/en/stable/handlers-and-middleware.html) to manipulate the outgoing request or inspect the incoming response. To manipulate the outgoing request, register a Guzzle middleware via the `withRequestMiddleware` method:

    use Illuminate\Support\Facades\Http;
    use Psr\Http\Message\RequestInterface;

    $response = Http::withRequestMiddleware(
        function (RequestInterface $request) {
            return $request->withHeader('X-Example', 'Value');
        }
    )->get('http://example.com');

Likewise, you can inspect the incoming HTTP response by registering a middleware via the `withResponseMiddleware` method:

    use Illuminate\Support\Facades\Http;
    use Psr\Http\Message\ResponseInterface;

    $response = Http::withResponseMiddleware(
        function (ResponseInterface $response) {
            $header = $response->getHeader('X-Example');

            // ...

            return $response;
        }
    )->get('http://example.com');

<a name="global-middleware"></a>
#### Global Middleware

Sometimes, you may want to register a middleware that applies to every outgoing request and incoming response. To accomplish this, you may use the `globalRequestMiddleware` and `globalResponseMiddleware` methods. Typically, these methods should be invoked in the `boot` method of your application's `AppServiceProvider`:

```php
use Illuminate\Support\Facades\Http;

Http::globalRequestMiddleware(fn ($request) => $request->withHeader(
    'User-Agent', 'Example Application/1.0'
));

Http::globalResponseMiddleware(fn ($response) => $response->withHeader(
    'X-Finished-At', now()->toDateTimeString()
));
```

<a name="guzzle-options"></a>
### Guzzle Options

You may specify additional [Guzzle request options](http://docs.guzzlephp.org/en/stable/request-options.html) using the `withOptions` method. The `withOptions` method accepts an array of key / value pairs:

    $response = Http::withOptions([
        'debug' => true,
    ])->get('http://example.com/users');

<a name="concurrent-requests"></a>
## Concurrent Requests

Sometimes, you may wish to make multiple HTTP requests concurrently. In other words, you want several requests to be dispatched at the same time instead of issuing the requests sequentially. This can lead to substantial performance improvements when interacting with slow HTTP APIs.

Thankfully, you may accomplish this using the `pool` method. The `pool` method accepts a closure which receives an `Illuminate\Http\Client\Pool` instance, allowing you to easily add requests to the request pool for dispatching:

    use Illuminate\Http\Client\Pool;
    use Illuminate\Support\Facades\Http;

    $responses = Http::pool(fn (Pool $pool) => [
        $pool->get('http://localhost/first'),
        $pool->get('http://localhost/second'),
        $pool->get('http://localhost/third'),
    ]);

    return $responses[0]->ok() &&
           $responses[1]->ok() &&
           $responses[2]->ok();

As you can see, each response instance can be accessed based on the order it was added to the pool. If you wish, you can name the requests using the `as` method, which allows you to access the corresponding responses by name:

    use Illuminate\Http\Client\Pool;
    use Illuminate\Support\Facades\Http;

    $responses = Http::pool(fn (Pool $pool) => [
        $pool->as('first')->get('http://localhost/first'),
        $pool->as('second')->get('http://localhost/second'),
        $pool->as('third')->get('http://localhost/third'),
    ]);

    return $responses['first']->ok();

<a name="customizing-concurrent-requests"></a>
#### Customizing Concurrent Requests

The `pool` method cannot be chained with other HTTP client methods such as the `withHeaders` or `middleware` methods. If you want to apply custom headers or middleware to pooled requests, you should configure those options on each request in the pool:

```php
use Illuminate\Http\Client\Pool;
use Illuminate\Support\Facades\Http;

$headers = [
    'X-Example' => 'example',
];

$responses = Http::pool(fn (Pool $pool) => [
    $pool->withHeaders($headers)->get('http://laravel.test/test'),
    $pool->withHeaders($headers)->get('http://laravel.test/test'),
    $pool->withHeaders($headers)->get('http://laravel.test/test'),
]);
```

<a name="macros"></a>
## Macros

The Laravel HTTP client allows you to define "macros", which can serve as a fluent, expressive mechanism to configure common request paths and headers when interacting with services throughout your application. To get started, you may define the macro within the `boot` method of your application's `App\Providers\AppServiceProvider` class:

```php
use Illuminate\Support\Facades\Http;

/**
 * Bootstrap any application services.
 */
public function boot(): void
{
    Http::macro('github', function () {
        return Http::withHeaders([
            'X-Example' => 'example',
        ])->baseUrl('https://github.com');
    });
}
```

Once your macro has been configured, you may invoke it from anywhere in your application to create a pending request with the specified configuration:

```php
$response = Http::github()->get('/');
```

<a name="testing"></a>
## Testing

Many Laravel services provide functionality to help you easily and expressively write tests, and Laravel's HTTP client is no exception. The `Http` facade's `fake` method allows you to instruct the HTTP client to return stubbed / dummy responses when requests are made.

<a name="faking-responses"></a>
### Faking Responses

For example, to instruct the HTTP client to return empty, `200` status code responses for every request, you may call the `fake` method with no arguments:

    use Illuminate\Support\Facades\Http;

    Http::fake();

    $response = Http::post(/* ... */);

<a name="faking-specific-urls"></a>
#### Faking Specific URLs

Alternatively, you may pass an array to the `fake` method. The array's keys should represent URL patterns that you wish to fake and their associated responses. The `*` character may be used as a wildcard character. Any requests made to URLs that have not been faked will actually be executed. You may use the `Http` facade's `response` method to construct stub / fake responses for these endpoints:

    Http::fake([
        // Stub a JSON response for GitHub endpoints...
        'github.com/*' => Http::response(['foo' => 'bar'], 200, $headers),

        // Stub a string response for Google endpoints...
        'google.com/*' => Http::response('Hello World', 200, $headers),
    ]);

If you would like to specify a fallback URL pattern that will stub all unmatched URLs, you may use a single `*` character:

    Http::fake([
        // Stub a JSON response for GitHub endpoints...
        'github.com/*' => Http::response(['foo' => 'bar'], 200, ['Headers']),

        // Stub a string response for all other endpoints...
        '*' => Http::response('Hello World', 200, ['Headers']),
    ]);

<a name="faking-response-sequences"></a>
#### Faking Response Sequences

Sometimes you may need to specify that a single URL should return a series of fake responses in a specific order. You may accomplish this using the `Http::sequence` method to build the responses:

    Http::fake([
        // Stub a series of responses for GitHub endpoints...
        'github.com/*' => Http::sequence()
                                ->push('Hello World', 200)
                                ->push(['foo' => 'bar'], 200)
                                ->pushStatus(404),
    ]);

When all the responses in a response sequence have been consumed, any further requests will cause the response sequence to throw an exception. If you would like to specify a default response that should be returned when a sequence is empty, you may use the `whenEmpty` method:

    Http::fake([
        // Stub a series of responses for GitHub endpoints...
        'github.com/*' => Http::sequence()
                                ->push('Hello World', 200)
                                ->push(['foo' => 'bar'], 200)
                                ->whenEmpty(Http::response()),
    ]);

If you would like to fake a sequence of responses but do not need to specify a specific URL pattern that should be faked, you may use the `Http::fakeSequence` method:

    Http::fakeSequence()
            ->push('Hello World', 200)
            ->whenEmpty(Http::response());

<a name="fake-callback"></a>
#### Fake Callback

If you require more complicated logic to determine what responses to return for certain endpoints, you may pass a closure to the `fake` method. This closure will receive an instance of `Illuminate\Http\Client\Request` as well as an array of options. The closure should return a response instance. Within your closure, you may perform whatever logic is necessary to determine what type of response to return:

    use Illuminate\Http\Client\Request;

    Http::fake(function (Request $request, array $options) {
        return Http::response('Hello World', 200);
    });

<a name="preventing-stray-requests"></a>
### Preventing Stray Requests

If you would like to ensure that all requests sent via the HTTP client have been faked throughout your individual test or complete test suite, you can call the `preventStrayRequests` method. After calling this method, any requests that do not have a corresponding fake response will throw an exception rather than making the actual HTTP request:

    use Illuminate\Support\Facades\Http;

    Http::preventStrayRequests();

    Http::fake([
        'github.com/*' => Http::response('ok'),
    ]);

    // An "ok" response is returned...
    Http::get('https://github.com/laravel/framework');

    // An exception is thrown...
    Http::get('https://laravel.com');

<a name="inspecting-requests"></a>
### Inspecting Requests

When faking responses, you may occasionally wish to inspect the requests the client receives in order to make sure your application is sending the correct data or headers. You may accomplish this by calling the `Http::assertSent` method after calling `Http::fake`.

The `assertSent` method accepts a closure which will receive an `Illuminate\Http\Client\Request` instance and should return a boolean value indicating if the request matches your expectations. In order for the test to pass, at least one request must have been issued matching the given expectations:

    use Illuminate\Http\Client\Request;
    use Illuminate\Support\Facades\Http;

    Http::fake();

    Http::withHeaders([
        'X-First' => 'foo',
    ])->post('http://example.com/users', [
        'name' => 'Taylor',
        'role' => 'Developer',
    ]);

    Http::assertSent(function (Request $request) {
        return $request->hasHeader('X-First', 'foo') &&
               $request->url() == 'http://example.com/users' &&
               $request['name'] == 'Taylor' &&
               $request['role'] == 'Developer';
    });

If needed, you may assert that a specific request was not sent using the `assertNotSent` method:

    use Illuminate\Http\Client\Request;
    use Illuminate\Support\Facades\Http;

    Http::fake();

    Http::post('http://example.com/users', [
        'name' => 'Taylor',
        'role' => 'Developer',
    ]);

    Http::assertNotSent(function (Request $request) {
        return $request->url() === 'http://example.com/posts';
    });

You may use the `assertSentCount` method to assert how many requests were "sent" during the test:

    Http::fake();

    Http::assertSentCount(5);

Or, you may use the `assertNothingSent` method to assert that no requests were sent during the test:

    Http::fake();

    Http::assertNothingSent();

<a name="recording-requests-and-responses"></a>
#### Recording Requests / Responses

You may use the `recorded` method to gather all requests and their corresponding responses. The `recorded` method returns a collection of arrays that contains instances of `Illuminate\Http\Client\Request` and `Illuminate\Http\Client\Response`:

```php
Http::fake([
    'https://laravel.com' => Http::response(status: 500),
    'https://nova.laravel.com/' => Http::response(),
]);

Http::get('https://laravel.com');
Http::get('https://nova.laravel.com/');

$recorded = Http::recorded();

[$request, $response] = $recorded[0];
```

Additionally, the `recorded` method accepts a closure which will receive an instance of `Illuminate\Http\Client\Request` and `Illuminate\Http\Client\Response` and may be used to filter request / response pairs based on your expectations:

```php
use Illuminate\Http\Client\Request;
use Illuminate\Http\Client\Response;

Http::fake([
    'https://laravel.com' => Http::response(status: 500),
    'https://nova.laravel.com/' => Http::response(),
]);

Http::get('https://laravel.com');
Http::get('https://nova.laravel.com/');

$recorded = Http::recorded(function (Request $request, Response $response) {
    return $request->url() !== 'https://laravel.com' &&
           $response->successful();
});
```

<a name="events"></a>
## Events

Laravel fires three events during the process of sending HTTP requests. The `RequestSending` event is fired prior to a request being sent, while the `ResponseReceived` event is fired after a response is received for a given request. The `ConnectionFailed` event is fired if no response is received for a given request.

The `RequestSending` and `ConnectionFailed` events both contain a public `$request` property that you may use to inspect the `Illuminate\Http\Client\Request` instance. Likewise, the `ResponseReceived` event contains a `$request` property as well as a `$response` property which may be used to inspect the `Illuminate\Http\Client\Response` instance. You may register event listeners for this event in your `App\Providers\EventServiceProvider` service provider:

    /**
     * The event listener mappings for the application.
     *
     * @var array
     */
    protected $listen = [
        'Illuminate\Http\Client\Events\RequestSending' => [
            'App\Listeners\LogRequestSending',
        ],
        'Illuminate\Http\Client\Events\ResponseReceived' => [
            'App\Listeners\LogResponseReceived',
        ],
        'Illuminate\Http\Client\Events\ConnectionFailed' => [
            'App\Listeners\LogConnectionFailed',
        ],
    ];



## Requests

# HTTP Requests

- [Introduction](#introduction)
- [Interacting With The Request](#interacting-with-the-request)
    - [Accessing the Request](#accessing-the-request)
    - [Request Path, Host, and Method](#request-path-and-method)
    - [Request Headers](#request-headers)
    - [Request IP Address](#request-ip-address)
    - [Content Negotiation](#content-negotiation)
    - [PSR-7 Requests](#psr7-requests)
- [Input](#input)
    - [Retrieving Input](#retrieving-input)
    - [Input Presence](#input-presence)
    - [Merging Additional Input](#merging-additional-input)
    - [Old Input](#old-input)
    - [Cookies](#cookies)
    - [Input Trimming and Normalization](#input-trimming-and-normalization)
- [Files](#files)
    - [Retrieving Uploaded Files](#retrieving-uploaded-files)
    - [Storing Uploaded Files](#storing-uploaded-files)
- [Configuring Trusted Proxies](#configuring-trusted-proxies)
- [Configuring Trusted Hosts](#configuring-trusted-hosts)

<a name="introduction"></a>
## Introduction

Laravel's `Illuminate\Http\Request` class provides an object-oriented way to interact with the current HTTP request being handled by your application as well as retrieve the input, cookies, and files that were submitted with the request.

<a name="interacting-with-the-request"></a>
## Interacting With The Request

<a name="accessing-the-request"></a>
### Accessing the Request

To obtain an instance of the current HTTP request via dependency injection, you should type-hint the `Illuminate\Http\Request` class on your route closure or controller method. The incoming request instance will automatically be injected by the Laravel [service container](/docs/{{version}}/container):

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * Store a new user.
         */
        public function store(Request $request): RedirectResponse
        {
            $name = $request->input('name');

            // Store the user...

            return redirect('/users');
        }
    }

As mentioned, you may also type-hint the `Illuminate\Http\Request` class on a route closure. The service container will automatically inject the incoming request into the closure when it is executed:

    use Illuminate\Http\Request;

    Route::get('/', function (Request $request) {
        // ...
    });

<a name="dependency-injection-route-parameters"></a>
#### Dependency Injection and Route Parameters

If your controller method is also expecting input from a route parameter you should list your route parameters after your other dependencies. For example, if your route is defined like so:

    use App\Http\Controllers\UserController;

    Route::put('/user/{id}', [UserController::class, 'update']);

You may still type-hint the `Illuminate\Http\Request` and access your `id` route parameter by defining your controller method as follows:

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * Update the specified user.
         */
        public function update(Request $request, string $id): RedirectResponse
        {
            // Update the user...

            return redirect('/users');
        }
    }

<a name="request-path-and-method"></a>
### Request Path, Host, and Method

The `Illuminate\Http\Request` instance provides a variety of methods for examining the incoming HTTP request and extends the `Symfony\Component\HttpFoundation\Request` class. We will discuss a few of the most important methods below.

<a name="retrieving-the-request-path"></a>
#### Retrieving the Request Path

The `path` method returns the request's path information. So, if the incoming request is targeted at `http://example.com/foo/bar`, the `path` method will return `foo/bar`:

    $uri = $request->path();

<a name="inspecting-the-request-path"></a>
#### Inspecting the Request Path / Route

The `is` method allows you to verify that the incoming request path matches a given pattern. You may use the `*` character as a wildcard when utilizing this method:

    if ($request->is('admin/*')) {
        // ...
    }

Using the `routeIs` method, you may determine if the incoming request has matched a [named route](/docs/{{version}}/routing#named-routes):

    if ($request->routeIs('admin.*')) {
        // ...
    }

<a name="retrieving-the-request-url"></a>
#### Retrieving the Request URL

To retrieve the full URL for the incoming request you may use the `url` or `fullUrl` methods. The `url` method will return the URL without the query string, while the `fullUrl` method includes the query string:

    $url = $request->url();

    $urlWithQueryString = $request->fullUrl();

If you would like to append query string data to the current URL, you may call the `fullUrlWithQuery` method. This method merges the given array of query string variables with the current query string:

    $request->fullUrlWithQuery(['type' => 'phone']);

If you would like to get the current URL without a given query string parameter, you may utilize the `fullUrlWithoutQuery` method:

```php
$request->fullUrlWithoutQuery(['type']);
```

<a name="retrieving-the-request-host"></a>
#### Retrieving the Request Host

You may retrieve the "host" of the incoming request via the `host`, `httpHost`, and `schemeAndHttpHost` methods:

    $request->host();
    $request->httpHost();
    $request->schemeAndHttpHost();

<a name="retrieving-the-request-method"></a>
#### Retrieving the Request Method

The `method` method will return the HTTP verb for the request. You may use the `isMethod` method to verify that the HTTP verb matches a given string:

    $method = $request->method();

    if ($request->isMethod('post')) {
        // ...
    }

<a name="request-headers"></a>
### Request Headers

You may retrieve a request header from the `Illuminate\Http\Request` instance using the `header` method. If the header is not present on the request, `null` will be returned. However, the `header` method accepts an optional second argument that will be returned if the header is not present on the request:

    $value = $request->header('X-Header-Name');

    $value = $request->header('X-Header-Name', 'default');

The `hasHeader` method may be used to determine if the request contains a given header:

    if ($request->hasHeader('X-Header-Name')) {
        // ...
    }

For convenience, the `bearerToken` method may be used to retrieve a bearer token from the `Authorization` header. If no such header is present, an empty string will be returned:

    $token = $request->bearerToken();

<a name="request-ip-address"></a>
### Request IP Address

The `ip` method may be used to retrieve the IP address of the client that made the request to your application:

    $ipAddress = $request->ip();

If you would like to retrieve an array of IP addresses, including all of the client IP addesses that were forwarded by proxies, you may use the `ips` method. The "original" client IP address will be at the end of the array:

    $ipAddresses = $request->ips();

In general, IP addresses should be considered untrusted, user-controlled input and be used for informational purposes only.

<a name="content-negotiation"></a>
### Content Negotiation

Laravel provides several methods for inspecting the incoming request's requested content types via the `Accept` header. First, the `getAcceptableContentTypes` method will return an array containing all of the content types accepted by the request:

    $contentTypes = $request->getAcceptableContentTypes();

The `accepts` method accepts an array of content types and returns `true` if any of the content types are accepted by the request. Otherwise, `false` will be returned:

    if ($request->accepts(['text/html', 'application/json'])) {
        // ...
    }

You may use the `prefers` method to determine which content type out of a given array of content types is most preferred by the request. If none of the provided content types are accepted by the request, `null` will be returned:

    $preferred = $request->prefers(['text/html', 'application/json']);

Since many applications only serve HTML or JSON, you may use the `expectsJson` method to quickly determine if the incoming request expects a JSON response:

    if ($request->expectsJson()) {
        // ...
    }

<a name="psr7-requests"></a>
### PSR-7 Requests

The [PSR-7 standard](https://www.php-fig.org/psr/psr-7/) specifies interfaces for HTTP messages, including requests and responses. If you would like to obtain an instance of a PSR-7 request instead of a Laravel request, you will first need to install a few libraries. Laravel uses the *Symfony HTTP Message Bridge* component to convert typical Laravel requests and responses into PSR-7 compatible implementations:

```shell
composer require symfony/psr-http-message-bridge
composer require nyholm/psr7
```

Once you have installed these libraries, you may obtain a PSR-7 request by type-hinting the request interface on your route closure or controller method:

    use Psr\Http\Message\ServerRequestInterface;

    Route::get('/', function (ServerRequestInterface $request) {
        // ...
    });

> [!NOTE]  
> If you return a PSR-7 response instance from a route or controller, it will automatically be converted back to a Laravel response instance and be displayed by the framework.

<a name="input"></a>
## Input

<a name="retrieving-input"></a>
### Retrieving Input

<a name="retrieving-all-input-data"></a>
#### Retrieving All Input Data

You may retrieve all of the incoming request's input data as an `array` using the `all` method. This method may be used regardless of whether the incoming request is from an HTML form or is an XHR request:

    $input = $request->all();

Using the `collect` method, you may retrieve all of the incoming request's input data as a [collection](/docs/{{version}}/collections):

    $input = $request->collect();

The `collect` method also allows you to retrieve a subset of the incoming request's input as a collection:

    $request->collect('users')->each(function (string $user) {
        // ...
    });

<a name="retrieving-an-input-value"></a>
#### Retrieving an Input Value

Using a few simple methods, you may access all of the user input from your `Illuminate\Http\Request` instance without worrying about which HTTP verb was used for the request. Regardless of the HTTP verb, the `input` method may be used to retrieve user input:

    $name = $request->input('name');

You may pass a default value as the second argument to the `input` method. This value will be returned if the requested input value is not present on the request:

    $name = $request->input('name', 'Sally');

When working with forms that contain array inputs, use "dot" notation to access the arrays:

    $name = $request->input('products.0.name');

    $names = $request->input('products.*.name');

You may call the `input` method without any arguments in order to retrieve all of the input values as an associative array:

    $input = $request->input();

<a name="retrieving-input-from-the-query-string"></a>
#### Retrieving Input From the Query String

While the `input` method retrieves values from the entire request payload (including the query string), the `query` method will only retrieve values from the query string:

    $name = $request->query('name');

If the requested query string value data is not present, the second argument to this method will be returned:

    $name = $request->query('name', 'Helen');

You may call the `query` method without any arguments in order to retrieve all of the query string values as an associative array:

    $query = $request->query();

<a name="retrieving-json-input-values"></a>
#### Retrieving JSON Input Values

When sending JSON requests to your application, you may access the JSON data via the `input` method as long as the `Content-Type` header of the request is properly set to `application/json`. You may even use "dot" syntax to retrieve values that are nested within JSON arrays / objects:

    $name = $request->input('user.name');

<a name="retrieving-stringable-input-values"></a>
#### Retrieving Stringable Input Values

Instead of retrieving the request's input data as a primitive `string`, you may use the `string` method to retrieve the request data as an instance of [`Illuminate\Support\Stringable`](/docs/{{version}}/helpers#fluent-strings):

    $name = $request->string('name')->trim();

<a name="retrieving-boolean-input-values"></a>
#### Retrieving Boolean Input Values

When dealing with HTML elements like checkboxes, your application may receive "truthy" values that are actually strings. For example, "true" or "on". For convenience, you may use the `boolean` method to retrieve these values as booleans. The `boolean` method returns `true` for 1, "1", true, "true", "on", and "yes". All other values will return `false`:

    $archived = $request->boolean('archived');

<a name="retrieving-date-input-values"></a>
#### Retrieving Date Input Values

For convenience, input values containing dates / times may be retrieved as Carbon instances using the `date` method. If the request does not contain an input value with the given name, `null` will be returned:

    $birthday = $request->date('birthday');

The second and third arguments accepted by the `date` method may be used to specify the date's format and timezone, respectively:

    $elapsed = $request->date('elapsed', '!H:i', 'Europe/Madrid');

If the input value is present but has an invalid format, an `InvalidArgumentException` will be thrown; therefore, it is recommended that you validate the input before invoking the `date` method.

<a name="retrieving-enum-input-values"></a>
#### Retrieving Enum Input Values

Input values that correspond to [PHP enums](https://www.php.net/manual/en/language.types.enumerations.php) may also be retrieved from the request. If the request does not contain an input value with the given name or the enum does not have a backing value that matches the input value, `null` will be returned. The `enum` method accepts the name of the input value and the enum class as its first and second arguments:

    use App\Enums\Status;

    $status = $request->enum('status', Status::class);

<a name="retrieving-input-via-dynamic-properties"></a>
#### Retrieving Input via Dynamic Properties

You may also access user input using dynamic properties on the `Illuminate\Http\Request` instance. For example, if one of your application's forms contains a `name` field, you may access the value of the field like so:

    $name = $request->name;

When using dynamic properties, Laravel will first look for the parameter's value in the request payload. If it is not present, Laravel will search for the field in the matched route's parameters.

<a name="retrieving-a-portion-of-the-input-data"></a>
#### Retrieving a Portion of the Input Data

If you need to retrieve a subset of the input data, you may use the `only` and `except` methods. Both of these methods accept a single `array` or a dynamic list of arguments:

    $input = $request->only(['username', 'password']);

    $input = $request->only('username', 'password');

    $input = $request->except(['credit_card']);

    $input = $request->except('credit_card');

> [!WARNING]  
> The `only` method returns all of the key / value pairs that you request; however, it will not return key / value pairs that are not present on the request.

<a name="input-presence"></a>
### Input Presence

You may use the `has` method to determine if a value is present on the request. The `has` method returns `true` if the value is present on the request:

    if ($request->has('name')) {
        // ...
    }

When given an array, the `has` method will determine if all of the specified values are present:

    if ($request->has(['name', 'email'])) {
        // ...
    }

The `hasAny` method returns `true` if any of the specified values are present:

    if ($request->hasAny(['name', 'email'])) {
        // ...
    }

The `whenHas` method will execute the given closure if a value is present on the request:

    $request->whenHas('name', function (string $input) {
        // ...
    });

A second closure may be passed to the `whenHas` method that will be executed if the specified value is not present on the request:

    $request->whenHas('name', function (string $input) {
        // The "name" value is present...
    }, function () {
        // The "name" value is not present...
    });

If you would like to determine if a value is present on the request and is not an empty string, you may use the `filled` method:

    if ($request->filled('name')) {
        // ...
    }

The `anyFilled` method returns `true` if any of the specified values is not an empty string:

    if ($request->anyFilled(['name', 'email'])) {
        // ...
    }

The `whenFilled` method will execute the given closure if a value is present on the request and is not an empty string:

    $request->whenFilled('name', function (string $input) {
        // ...
    });

A second closure may be passed to the `whenFilled` method that will be executed if the specified value is not "filled":

    $request->whenFilled('name', function (string $input) {
        // The "name" value is filled...
    }, function () {
        // The "name" value is not filled...
    });

To determine if a given key is absent from the request, you may use the `missing` and `whenMissing` methods:

    if ($request->missing('name')) {
        // ...
    }

    $request->whenMissing('name', function (array $input) {
        // The "name" value is missing...
    }, function () {
        // The "name" value is present...
    });

<a name="merging-additional-input"></a>
### Merging Additional Input

Sometimes you may need to manually merge additional input into the request's existing input data. To accomplish this, you may use the `merge` method. If a given input key already exists on the request, it will be overwritten by the data provided to the `merge` method:

    $request->merge(['votes' => 0]);

The `mergeIfMissing` method may be used to merge input into the request if the corresponding keys do not already exist within the request's input data:

    $request->mergeIfMissing(['votes' => 0]);

<a name="old-input"></a>
### Old Input

Laravel allows you to keep input from one request during the next request. This feature is particularly useful for re-populating forms after detecting validation errors. However, if you are using Laravel's included [validation features](/docs/{{version}}/validation), it is possible that you will not need to manually use these session input flashing methods directly, as some of Laravel's built-in validation facilities will call them automatically.

<a name="flashing-input-to-the-session"></a>
#### Flashing Input to the Session

The `flash` method on the `Illuminate\Http\Request` class will flash the current input to the [session](/docs/{{version}}/session) so that it is available during the user's next request to the application:

    $request->flash();

You may also use the `flashOnly` and `flashExcept` methods to flash a subset of the request data to the session. These methods are useful for keeping sensitive information such as passwords out of the session:

    $request->flashOnly(['username', 'email']);

    $request->flashExcept('password');

<a name="flashing-input-then-redirecting"></a>
#### Flashing Input Then Redirecting

Since you often will want to flash input to the session and then redirect to the previous page, you may easily chain input flashing onto a redirect using the `withInput` method:

    return redirect('form')->withInput();

    return redirect()->route('user.create')->withInput();

    return redirect('form')->withInput(
        $request->except('password')
    );

<a name="retrieving-old-input"></a>
#### Retrieving Old Input

To retrieve flashed input from the previous request, invoke the `old` method on an instance of `Illuminate\Http\Request`. The `old` method will pull the previously flashed input data from the [session](/docs/{{version}}/session):

    $username = $request->old('username');

Laravel also provides a global `old` helper. If you are displaying old input within a [Blade template](/docs/{{version}}/blade), it is more convenient to use the `old` helper to repopulate the form. If no old input exists for the given field, `null` will be returned:

    <input type="text" name="username" value="{{ old('username') }}">

<a name="cookies"></a>
### Cookies

<a name="retrieving-cookies-from-requests"></a>
#### Retrieving Cookies From Requests

All cookies created by the Laravel framework are encrypted and signed with an authentication code, meaning they will be considered invalid if they have been changed by the client. To retrieve a cookie value from the request, use the `cookie` method on an `Illuminate\Http\Request` instance:

    $value = $request->cookie('name');

<a name="input-trimming-and-normalization"></a>
## Input Trimming and Normalization

By default, Laravel includes the `App\Http\Middleware\TrimStrings` and `Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull` middleware in your application's global middleware stack. These middleware are listed in the global middleware stack by the `App\Http\Kernel` class. These middleware will automatically trim all incoming string fields on the request, as well as convert any empty string fields to `null`. This allows you to not have to worry about these normalization concerns in your routes and controllers.

#### Disabling Input Normalization

If you would like to disable this behavior for all requests, you may remove the two middleware from your application's middleware stack by removing them from the `$middleware` property of your `App\Http\Kernel` class.

If you would like to disable string trimming and empty string conversion for a subset of requests to your application, you may use the `skipWhen` method offered by both middleware. This method accepts a closure which should return `true` or `false` to indicate if input normalization should be skipped. Typically, the `skipWhen` method should be invoked in the `boot` method of your application's `AppServiceProvider`.

```php
use App\Http\Middleware\TrimStrings;
use Illuminate\Http\Request;
use Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull;

/**
 * Bootstrap any application services.
 */
public function boot(): void
{
    TrimStrings::skipWhen(function (Request $request) {
        return $request->is('admin/*');
    });

    ConvertEmptyStringsToNull::skipWhen(function (Request $request) {
        // ...
    });
}
```

<a name="files"></a>
## Files

<a name="retrieving-uploaded-files"></a>
### Retrieving Uploaded Files

You may retrieve uploaded files from an `Illuminate\Http\Request` instance using the `file` method or using dynamic properties. The `file` method returns an instance of the `Illuminate\Http\UploadedFile` class, which extends the PHP `SplFileInfo` class and provides a variety of methods for interacting with the file:

    $file = $request->file('photo');

    $file = $request->photo;

You may determine if a file is present on the request using the `hasFile` method:

    if ($request->hasFile('photo')) {
        // ...
    }

<a name="validating-successful-uploads"></a>
#### Validating Successful Uploads

In addition to checking if the file is present, you may verify that there were no problems uploading the file via the `isValid` method:

    if ($request->file('photo')->isValid()) {
        // ...
    }

<a name="file-paths-extensions"></a>
#### File Paths and Extensions

The `UploadedFile` class also contains methods for accessing the file's fully-qualified path and its extension. The `extension` method will attempt to guess the file's extension based on its contents. This extension may be different from the extension that was supplied by the client:

    $path = $request->photo->path();

    $extension = $request->photo->extension();

<a name="other-file-methods"></a>
#### Other File Methods

There are a variety of other methods available on `UploadedFile` instances. Check out the [API documentation for the class](https://github.com/symfony/symfony/blob/6.0/src/Symfony/Component/HttpFoundation/File/UploadedFile.php) for more information regarding these methods.

<a name="storing-uploaded-files"></a>
### Storing Uploaded Files

To store an uploaded file, you will typically use one of your configured [filesystems](/docs/{{version}}/filesystem). The `UploadedFile` class has a `store` method that will move an uploaded file to one of your disks, which may be a location on your local filesystem or a cloud storage location like Amazon S3.

The `store` method accepts the path where the file should be stored relative to the filesystem's configured root directory. This path should not contain a filename, since a unique ID will automatically be generated to serve as the filename.

The `store` method also accepts an optional second argument for the name of the disk that should be used to store the file. The method will return the path of the file relative to the disk's root:

    $path = $request->photo->store('images');

    $path = $request->photo->store('images', 's3');

If you do not want a filename to be automatically generated, you may use the `storeAs` method, which accepts the path, filename, and disk name as its arguments:

    $path = $request->photo->storeAs('images', 'filename.jpg');

    $path = $request->photo->storeAs('images', 'filename.jpg', 's3');

> [!NOTE]  
> For more information about file storage in Laravel, check out the complete [file storage documentation](/docs/{{version}}/filesystem).

<a name="configuring-trusted-proxies"></a>
## Configuring Trusted Proxies

When running your applications behind a load balancer that terminates TLS / SSL certificates, you may notice your application sometimes does not generate HTTPS links when using the `url` helper. Typically this is because your application is being forwarded traffic from your load balancer on port 80 and does not know it should generate secure links.

To solve this, you may use the `App\Http\Middleware\TrustProxies` middleware that is included in your Laravel application, which allows you to quickly customize the load balancers or proxies that should be trusted by your application. Your trusted proxies should be listed as an array on the `$proxies` property of this middleware. In addition to configuring the trusted proxies, you may configure the proxy `$headers` that should be trusted:

    <?php

    namespace App\Http\Middleware;

    use Illuminate\Http\Middleware\TrustProxies as Middleware;
    use Illuminate\Http\Request;

    class TrustProxies extends Middleware
    {
        /**
         * The trusted proxies for this application.
         *
         * @var string|array
         */
        protected $proxies = [
            '192.168.1.1',
            '192.168.1.2',
        ];

        /**
         * The headers that should be used to detect proxies.
         *
         * @var int
         */
        protected $headers = Request::HEADER_X_FORWARDED_FOR | Request::HEADER_X_FORWARDED_HOST | Request::HEADER_X_FORWARDED_PORT | Request::HEADER_X_FORWARDED_PROTO;
    }

> [!NOTE]  
> If you are using AWS Elastic Load Balancing, your `$headers` value should be `Request::HEADER_X_FORWARDED_AWS_ELB`. For more information on the constants that may be used in the `$headers` property, check out Symfony's documentation on [trusting proxies](https://symfony.com/doc/current/deployment/proxies.html).

<a name="trusting-all-proxies"></a>
#### Trusting All Proxies

If you are using Amazon AWS or another "cloud" load balancer provider, you may not know the IP addresses of your actual balancers. In this case, you may use `*` to trust all proxies:

    /**
     * The trusted proxies for this application.
     *
     * @var string|array
     */
    protected $proxies = '*';

<a name="configuring-trusted-hosts"></a>
## Configuring Trusted Hosts

By default, Laravel will respond to all requests it receives regardless of the content of the HTTP request's `Host` header. In addition, the `Host` header's value will be used when generating absolute URLs to your application during a web request.

Typically, you should configure your web server, such as Nginx or Apache, to only send requests to your application that match a given host name. However, if you do not have the ability to customize your web server directly and need to instruct Laravel to only respond to certain host names, you may do so by enabling the `App\Http\Middleware\TrustHosts` middleware for your application.

The `TrustHosts` middleware is already included in the `$middleware` stack of your application; however, you should uncomment it so that it becomes active. Within this middleware's `hosts` method, you may specify the host names that your application should respond to. Incoming requests with other `Host` value headers will be rejected:

    /**
     * Get the host patterns that should be trusted.
     *
     * @return array<int, string>
     */
    public function hosts(): array
    {
        return [
            'laravel.test',
            $this->allSubdomainsOfApplicationUrl(),
        ];
    }

The `allSubdomainsOfApplicationUrl` helper method will return a regular expression matching all subdomains of your application's `app.url` configuration value. This helper method provides a convenient way to allow all of your application's subdomains when building an application that utilizes wildcard subdomains.



## Responses

# HTTP Responses

- [Creating Responses](#creating-responses)
    - [Attaching Headers to Responses](#attaching-headers-to-responses)
    - [Attaching Cookies to Responses](#attaching-cookies-to-responses)
    - [Cookies and Encryption](#cookies-and-encryption)
- [Redirects](#redirects)
    - [Redirecting to Named Routes](#redirecting-named-routes)
    - [Redirecting to Controller Actions](#redirecting-controller-actions)
    - [Redirecting to External Domains](#redirecting-external-domains)
    - [Redirecting With Flashed Session Data](#redirecting-with-flashed-session-data)
- [Other Response Types](#other-response-types)
    - [View Responses](#view-responses)
    - [JSON Responses](#json-responses)
    - [File Downloads](#file-downloads)
    - [File Responses](#file-responses)
- [Response Macros](#response-macros)

<a name="creating-responses"></a>
## Creating Responses

<a name="strings-arrays"></a>
#### Strings and Arrays

All routes and controllers should return a response to be sent back to the user's browser. Laravel provides several different ways to return responses. The most basic response is returning a string from a route or controller. The framework will automatically convert the string into a full HTTP response:

    Route::get('/', function () {
        return 'Hello World';
    });

In addition to returning strings from your routes and controllers, you may also return arrays. The framework will automatically convert the array into a JSON response:

    Route::get('/', function () {
        return [1, 2, 3];
    });

> [!NOTE]  
> Did you know you can also return [Eloquent collections](/docs/{{version}}/eloquent-collections) from your routes or controllers? They will automatically be converted to JSON. Give it a shot!

<a name="response-objects"></a>
#### Response Objects

Typically, you won't just be returning simple strings or arrays from your route actions. Instead, you will be returning full `Illuminate\Http\Response` instances or [views](/docs/{{version}}/views).

Returning a full `Response` instance allows you to customize the response's HTTP status code and headers. A `Response` instance inherits from the `Symfony\Component\HttpFoundation\Response` class, which provides a variety of methods for building HTTP responses:

    Route::get('/home', function () {
        return response('Hello World', 200)
                      ->header('Content-Type', 'text/plain');
    });

<a name="eloquent-models-and-collections"></a>
#### Eloquent Models and Collections

You may also return [Eloquent ORM](/docs/{{version}}/eloquent) models and collections directly from your routes and controllers. When you do, Laravel will automatically convert the models and collections to JSON responses while respecting the model's [hidden attributes](/docs/{{version}}/eloquent-serialization#hiding-attributes-from-json):

    use App\Models\User;

    Route::get('/user/{user}', function (User $user) {
        return $user;
    });

<a name="attaching-headers-to-responses"></a>
### Attaching Headers to Responses

Keep in mind that most response methods are chainable, allowing for the fluent construction of response instances. For example, you may use the `header` method to add a series of headers to the response before sending it back to the user:

    return response($content)
                ->header('Content-Type', $type)
                ->header('X-Header-One', 'Header Value')
                ->header('X-Header-Two', 'Header Value');

Or, you may use the `withHeaders` method to specify an array of headers to be added to the response:

    return response($content)
                ->withHeaders([
                    'Content-Type' => $type,
                    'X-Header-One' => 'Header Value',
                    'X-Header-Two' => 'Header Value',
                ]);

<a name="cache-control-middleware"></a>
#### Cache Control Middleware

Laravel includes a `cache.headers` middleware, which may be used to quickly set the `Cache-Control` header for a group of routes. Directives should be provided using the "snake case" equivalent of the corresponding cache-control directive and should be separated by a semicolon. If `etag` is specified in the list of directives, an MD5 hash of the response content will automatically be set as the ETag identifier:

    Route::middleware('cache.headers:public;max_age=2628000;etag')->group(function () {
        Route::get('/privacy', function () {
            // ...
        });

        Route::get('/terms', function () {
            // ...
        });
    });

<a name="attaching-cookies-to-responses"></a>
### Attaching Cookies to Responses

You may attach a cookie to an outgoing `Illuminate\Http\Response` instance using the `cookie` method. You should pass the name, value, and the number of minutes the cookie should be considered valid to this method:

    return response('Hello World')->cookie(
        'name', 'value', $minutes
    );

The `cookie` method also accepts a few more arguments which are used less frequently. Generally, these arguments have the same purpose and meaning as the arguments that would be given to PHP's native [setcookie](https://secure.php.net/manual/en/function.setcookie.php) method:

    return response('Hello World')->cookie(
        'name', 'value', $minutes, $path, $domain, $secure, $httpOnly
    );

If you would like to ensure that a cookie is sent with the outgoing response but you do not yet have an instance of that response, you can use the `Cookie` facade to "queue" cookies for attachment to the response when it is sent. The `queue` method accepts the arguments needed to create a cookie instance. These cookies will be attached to the outgoing response before it is sent to the browser:

    use Illuminate\Support\Facades\Cookie;

    Cookie::queue('name', 'value', $minutes);

<a name="generating-cookie-instances"></a>
#### Generating Cookie Instances

If you would like to generate a `Symfony\Component\HttpFoundation\Cookie` instance that can be attached to a response instance at a later time, you may use the global `cookie` helper. This cookie will not be sent back to the client unless it is attached to a response instance:

    $cookie = cookie('name', 'value', $minutes);

    return response('Hello World')->cookie($cookie);

<a name="expiring-cookies-early"></a>
#### Expiring Cookies Early

You may remove a cookie by expiring it via the `withoutCookie` method of an outgoing response:

    return response('Hello World')->withoutCookie('name');

If you do not yet have an instance of the outgoing response, you may use the `Cookie` facade's `expire` method to expire a cookie:

    Cookie::expire('name');

<a name="cookies-and-encryption"></a>
### Cookies and Encryption

By default, all cookies generated by Laravel are encrypted and signed so that they can't be modified or read by the client. If you would like to disable encryption for a subset of cookies generated by your application, you may use the `$except` property of the `App\Http\Middleware\EncryptCookies` middleware, which is located in the `app/Http/Middleware` directory:

    /**
     * The names of the cookies that should not be encrypted.
     *
     * @var array
     */
    protected $except = [
        'cookie_name',
    ];

<a name="redirects"></a>
## Redirects

Redirect responses are instances of the `Illuminate\Http\RedirectResponse` class, and contain the proper headers needed to redirect the user to another URL. There are several ways to generate a `RedirectResponse` instance. The simplest method is to use the global `redirect` helper:

    Route::get('/dashboard', function () {
        return redirect('home/dashboard');
    });

Sometimes you may wish to redirect the user to their previous location, such as when a submitted form is invalid. You may do so by using the global `back` helper function. Since this feature utilizes the [session](/docs/{{version}}/session), make sure the route calling the `back` function is using the `web` middleware group:

    Route::post('/user/profile', function () {
        // Validate the request...

        return back()->withInput();
    });

<a name="redirecting-named-routes"></a>
### Redirecting to Named Routes

When you call the `redirect` helper with no parameters, an instance of `Illuminate\Routing\Redirector` is returned, allowing you to call any method on the `Redirector` instance. For example, to generate a `RedirectResponse` to a named route, you may use the `route` method:

    return redirect()->route('login');

If your route has parameters, you may pass them as the second argument to the `route` method:

    // For a route with the following URI: /profile/{id}

    return redirect()->route('profile', ['id' => 1]);

<a name="populating-parameters-via-eloquent-models"></a>
#### Populating Parameters via Eloquent Models

If you are redirecting to a route with an "ID" parameter that is being populated from an Eloquent model, you may pass the model itself. The ID will be extracted automatically:

    // For a route with the following URI: /profile/{id}

    return redirect()->route('profile', [$user]);

If you would like to customize the value that is placed in the route parameter, you can specify the column in the route parameter definition (`/profile/{id:slug}`) or you can override the `getRouteKey` method on your Eloquent model:

    /**
     * Get the value of the model's route key.
     */
    public function getRouteKey(): mixed
    {
        return $this->slug;
    }

<a name="redirecting-controller-actions"></a>
### Redirecting to Controller Actions

You may also generate redirects to [controller actions](/docs/{{version}}/controllers). To do so, pass the controller and action name to the `action` method:

    use App\Http\Controllers\UserController;

    return redirect()->action([UserController::class, 'index']);

If your controller route requires parameters, you may pass them as the second argument to the `action` method:

    return redirect()->action(
        [UserController::class, 'profile'], ['id' => 1]
    );

<a name="redirecting-external-domains"></a>
### Redirecting to External Domains

Sometimes you may need to redirect to a domain outside of your application. You may do so by calling the `away` method, which creates a `RedirectResponse` without any additional URL encoding, validation, or verification:

    return redirect()->away('https://www.google.com');

<a name="redirecting-with-flashed-session-data"></a>
### Redirecting With Flashed Session Data

Redirecting to a new URL and [flashing data to the session](/docs/{{version}}/session#flash-data) are usually done at the same time. Typically, this is done after successfully performing an action when you flash a success message to the session. For convenience, you may create a `RedirectResponse` instance and flash data to the session in a single, fluent method chain:

    Route::post('/user/profile', function () {
        // ...

        return redirect('dashboard')->with('status', 'Profile updated!');
    });

After the user is redirected, you may display the flashed message from the [session](/docs/{{version}}/session). For example, using [Blade syntax](/docs/{{version}}/blade):

    @if (session('status'))
        <div class="alert alert-success">
            {{ session('status') }}
        </div>
    @endif

<a name="redirecting-with-input"></a>
#### Redirecting With Input

You may use the `withInput` method provided by the `RedirectResponse` instance to flash the current request's input data to the session before redirecting the user to a new location. This is typically done if the user has encountered a validation error. Once the input has been flashed to the session, you may easily [retrieve it](/docs/{{version}}/requests#retrieving-old-input) during the next request to repopulate the form:

    return back()->withInput();

<a name="other-response-types"></a>
## Other Response Types

The `response` helper may be used to generate other types of response instances. When the `response` helper is called without arguments, an implementation of the `Illuminate\Contracts\Routing\ResponseFactory` [contract](/docs/{{version}}/contracts) is returned. This contract provides several helpful methods for generating responses.

<a name="view-responses"></a>
### View Responses

If you need control over the response's status and headers but also need to return a [view](/docs/{{version}}/views) as the response's content, you should use the `view` method:

    return response()
                ->view('hello', $data, 200)
                ->header('Content-Type', $type);

Of course, if you do not need to pass a custom HTTP status code or custom headers, you may use the global `view` helper function.

<a name="json-responses"></a>
### JSON Responses

The `json` method will automatically set the `Content-Type` header to `application/json`, as well as convert the given array to JSON using the `json_encode` PHP function:

    return response()->json([
        'name' => 'Abigail',
        'state' => 'CA',
    ]);

If you would like to create a JSONP response, you may use the `json` method in combination with the `withCallback` method:

    return response()
                ->json(['name' => 'Abigail', 'state' => 'CA'])
                ->withCallback($request->input('callback'));

<a name="file-downloads"></a>
### File Downloads

The `download` method may be used to generate a response that forces the user's browser to download the file at the given path. The `download` method accepts a filename as the second argument to the method, which will determine the filename that is seen by the user downloading the file. Finally, you may pass an array of HTTP headers as the third argument to the method:

    return response()->download($pathToFile);

    return response()->download($pathToFile, $name, $headers);

> [!WARNING]  
> Symfony HttpFoundation, which manages file downloads, requires the file being downloaded to have an ASCII filename.

<a name="streamed-downloads"></a>
#### Streamed Downloads

Sometimes you may wish to turn the string response of a given operation into a downloadable response without having to write the contents of the operation to disk. You may use the `streamDownload` method in this scenario. This method accepts a callback, filename, and an optional array of headers as its arguments:

    use App\Services\GitHub;

    return response()->streamDownload(function () {
        echo GitHub::api('repo')
                    ->contents()
                    ->readme('laravel', 'laravel')['contents'];
    }, 'laravel-readme.md');

<a name="file-responses"></a>
### File Responses

The `file` method may be used to display a file, such as an image or PDF, directly in the user's browser instead of initiating a download. This method accepts the absolute path to the file as its first argument and an array of headers as its second argument:

    return response()->file($pathToFile);

    return response()->file($pathToFile, $headers);

<a name="response-macros"></a>
## Response Macros

If you would like to define a custom response that you can re-use in a variety of your routes and controllers, you may use the `macro` method on the `Response` facade. Typically, you should call this method from the `boot` method of one of your application's [service providers](/docs/{{version}}/providers), such as the `App\Providers\AppServiceProvider` service provider:

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Response;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * Bootstrap any application services.
         */
        public function boot(): void
        {
            Response::macro('caps', function (string $value) {
                return Response::make(strtoupper($value));
            });
        }
    }

The `macro` function accepts a name as its first argument and a closure as its second argument. The macro's closure will be executed when calling the macro name from a `ResponseFactory` implementation or the `response` helper:

    return response()->caps('foo');



## Validation

# Validation

- [Introduction](#introduction)
- [Validation Quickstart](#validation-quickstart)
    - [Defining the Routes](#quick-defining-the-routes)
    - [Creating the Controller](#quick-creating-the-controller)
    - [Writing the Validation Logic](#quick-writing-the-validation-logic)
    - [Displaying the Validation Errors](#quick-displaying-the-validation-errors)
    - [Repopulating Forms](#repopulating-forms)
    - [A Note on Optional Fields](#a-note-on-optional-fields)
    - [Validation Error Response Format](#validation-error-response-format)
- [Form Request Validation](#form-request-validation)
    - [Creating Form Requests](#creating-form-requests)
    - [Authorizing Form Requests](#authorizing-form-requests)
    - [Customizing the Error Messages](#customizing-the-error-messages)
    - [Preparing Input for Validation](#preparing-input-for-validation)
- [Manually Creating Validators](#manually-creating-validators)
    - [Automatic Redirection](#automatic-redirection)
    - [Named Error Bags](#named-error-bags)
    - [Customizing the Error Messages](#manual-customizing-the-error-messages)
    - [Performing Additional Validation](#performing-additional-validation)
- [Working With Validated Input](#working-with-validated-input)
- [Working With Error Messages](#working-with-error-messages)
    - [Specifying Custom Messages in Language Files](#specifying-custom-messages-in-language-files)
    - [Specifying Attributes in Language Files](#specifying-attribute-in-language-files)
    - [Specifying Values in Language Files](#specifying-values-in-language-files)
- [Available Validation Rules](#available-validation-rules)
- [Conditionally Adding Rules](#conditionally-adding-rules)
- [Validating Arrays](#validating-arrays)
    - [Validating Nested Array Input](#validating-nested-array-input)
    - [Error Message Indexes and Positions](#error-message-indexes-and-positions)
- [Validating Files](#validating-files)
- [Validating Passwords](#validating-passwords)
- [Custom Validation Rules](#custom-validation-rules)
    - [Using Rule Objects](#using-rule-objects)
    - [Using Closures](#using-closures)
    - [Implicit Rules](#implicit-rules)

<a name="introduction"></a>
## Introduction

Laravel provides several different approaches to validate your application's incoming data. It is most common to use the `validate` method available on all incoming HTTP requests. However, we will discuss other approaches to validation as well.

Laravel includes a wide variety of convenient validation rules that you may apply to data, even providing the ability to validate if values are unique in a given database table. We'll cover each of these validation rules in detail so that you are familiar with all of Laravel's validation features.

<a name="validation-quickstart"></a>
## Validation Quickstart

To learn about Laravel's powerful validation features, let's look at a complete example of validating a form and displaying the error messages back to the user. By reading this high-level overview, you'll be able to gain a good general understanding of how to validate incoming request data using Laravel:

<a name="quick-defining-the-routes"></a>
### Defining the Routes

First, let's assume we have the following routes defined in our `routes/web.php` file:

    use App\Http\Controllers\PostController;

    Route::get('/post/create', [PostController::class, 'create']);
    Route::post('/post', [PostController::class, 'store']);

The `GET` route will display a form for the user to create a new blog post, while the `POST` route will store the new blog post in the database.

<a name="quick-creating-the-controller"></a>
### Creating the Controller

Next, let's take a look at a simple controller that handles incoming requests to these routes. We'll leave the `store` method empty for now:

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;
    use Illuminate\View\View;

    class PostController extends Controller
    {
        /**
         * Show the form to create a new blog post.
         */
        public function create(): View
        {
            return view('post.create');
        }

        /**
         * Store a new blog post.
         */
        public function store(Request $request): RedirectResponse
        {
            // Validate and store the blog post...

            $post = /** ... */

            return to_route('post.show', ['post' => $post->id]);
        }
    }

<a name="quick-writing-the-validation-logic"></a>
### Writing the Validation Logic

Now we are ready to fill in our `store` method with the logic to validate the new blog post. To do this, we will use the `validate` method provided by the `Illuminate\Http\Request` object. If the validation rules pass, your code will keep executing normally; however, if validation fails, an `Illuminate\Validation\ValidationException` exception will be thrown and the proper error response will automatically be sent back to the user.

If validation fails during a traditional HTTP request, a redirect response to the previous URL will be generated. If the incoming request is an XHR request, a [JSON response containing the validation error messages](#validation-error-response-format) will be returned.

To get a better understanding of the `validate` method, let's jump back into the `store` method:

    /**
     * Store a new blog post.
     */
    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'title' => 'required|unique:posts|max:255',
            'body' => 'required',
        ]);

        // The blog post is valid...

        return redirect('/posts');
    }

As you can see, the validation rules are passed into the `validate` method. Don't worry - all available validation rules are [documented](#available-validation-rules). Again, if the validation fails, the proper response will automatically be generated. If the validation passes, our controller will continue executing normally.

Alternatively, validation rules may be specified as arrays of rules instead of a single `|` delimited string:

    $validatedData = $request->validate([
        'title' => ['required', 'unique:posts', 'max:255'],
        'body' => ['required'],
    ]);

In addition, you may use the `validateWithBag` method to validate a request and store any error messages within a [named error bag](#named-error-bags):

    $validatedData = $request->validateWithBag('post', [
        'title' => ['required', 'unique:posts', 'max:255'],
        'body' => ['required'],
    ]);

<a name="stopping-on-first-validation-failure"></a>
#### Stopping on First Validation Failure

Sometimes you may wish to stop running validation rules on an attribute after the first validation failure. To do so, assign the `bail` rule to the attribute:

    $request->validate([
        'title' => 'bail|required|unique:posts|max:255',
        'body' => 'required',
    ]);

In this example, if the `unique` rule on the `title` attribute fails, the `max` rule will not be checked. Rules will be validated in the order they are assigned.

<a name="a-note-on-nested-attributes"></a>
#### A Note on Nested Attributes

If the incoming HTTP request contains "nested" field data, you may specify these fields in your validation rules using "dot" syntax:

    $request->validate([
        'title' => 'required|unique:posts|max:255',
        'author.name' => 'required',
        'author.description' => 'required',
    ]);

On the other hand, if your field name contains a literal period, you can explicitly prevent this from being interpreted as "dot" syntax by escaping the period with a backslash:

    $request->validate([
        'title' => 'required|unique:posts|max:255',
        'v1\.0' => 'required',
    ]);

<a name="quick-displaying-the-validation-errors"></a>
### Displaying the Validation Errors

So, what if the incoming request fields do not pass the given validation rules? As mentioned previously, Laravel will automatically redirect the user back to their previous location. In addition, all of the validation errors and [request input](/docs/{{version}}/requests#retrieving-old-input) will automatically be [flashed to the session](/docs/{{version}}/session#flash-data).

An `$errors` variable is shared with all of your application's views by the `Illuminate\View\Middleware\ShareErrorsFromSession` middleware, which is provided by the `web` middleware group. When this middleware is applied an `$errors` variable will always be available in your views, allowing you to conveniently assume the `$errors` variable is always defined and can be safely used. The `$errors` variable will be an instance of `Illuminate\Support\MessageBag`. For more information on working with this object, [check out its documentation](#working-with-error-messages).

So, in our example, the user will be redirected to our controller's `create` method when validation fails, allowing us to display the error messages in the view:

```blade
<!-- /resources/views/post/create.blade.php -->

<h1>Create Post</h1>

@if ($errors->any())
    <div class="alert alert-danger">
        <ul>
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<!-- Create Post Form -->
```

<a name="quick-customizing-the-error-messages"></a>
#### Customizing the Error Messages

Laravel's built-in validation rules each have an error message that is located in your application's `lang/en/validation.php` file. If your application does not have a `lang` directory, you may instruct Laravel to create it using the `lang:publish` Artisan command.

Within the `lang/en/validation.php` file, you will find a translation entry for each validation rule. You are free to change or modify these messages based on the needs of your application.

In addition, you may copy this file to another language directory to translate the messages for your application's language. To learn more about Laravel localization, check out the complete [localization documentation](/docs/{{version}}/localization).

> [!WARNING]  
> By default, the Laravel application skeleton does not include the `lang` directory. If you would like to customize Laravel's language files, you may publish them via the `lang:publish` Artisan command.

<a name="quick-xhr-requests-and-validation"></a>
#### XHR Requests and Validation

In this example, we used a traditional form to send data to the application. However, many applications receive XHR requests from a JavaScript powered frontend. When using the `validate` method during an XHR request, Laravel will not generate a redirect response. Instead, Laravel generates a [JSON response containing all of the validation errors](#validation-error-response-format). This JSON response will be sent with a 422 HTTP status code.

<a name="the-at-error-directive"></a>
#### The `@error` Directive

You may use the `@error` [Blade](/docs/{{version}}/blade) directive to quickly determine if validation error messages exist for a given attribute. Within an `@error` directive, you may echo the `$message` variable to display the error message:

```blade
<!-- /resources/views/post/create.blade.php -->

<label for="title">Post Title</label>

<input id="title"
    type="text"
    name="title"
    class="@error('title') is-invalid @enderror">

@error('title')
    <div class="alert alert-danger">{{ $message }}</div>
@enderror
```

If you are using [named error bags](#named-error-bags), you may pass the name of the error bag as the second argument to the `@error` directive:

```blade
<input ... class="@error('title', 'post') is-invalid @enderror">
```

<a name="repopulating-forms"></a>
### Repopulating Forms

When Laravel generates a redirect response due to a validation error, the framework will automatically [flash all of the request's input to the session](/docs/{{version}}/session#flash-data). This is done so that you may conveniently access the input during the next request and repopulate the form that the user attempted to submit.

To retrieve flashed input from the previous request, invoke the `old` method on an instance of `Illuminate\Http\Request`. The `old` method will pull the previously flashed input data from the [session](/docs/{{version}}/session):

    $title = $request->old('title');

Laravel also provides a global `old` helper. If you are displaying old input within a [Blade template](/docs/{{version}}/blade), it is more convenient to use the `old` helper to repopulate the form. If no old input exists for the given field, `null` will be returned:

```blade
<input type="text" name="title" value="{{ old('title') }}">
```

<a name="a-note-on-optional-fields"></a>
### A Note on Optional Fields

By default, Laravel includes the `TrimStrings` and `ConvertEmptyStringsToNull` middleware in your application's global middleware stack. These middleware are listed in the stack by the `App\Http\Kernel` class. Because of this, you will often need to mark your "optional" request fields as `nullable` if you do not want the validator to consider `null` values as invalid. For example:

    $request->validate([
        'title' => 'required|unique:posts|max:255',
        'body' => 'required',
        'publish_at' => 'nullable|date',
    ]);

In this example, we are specifying that the `publish_at` field may be either `null` or a valid date representation. If the `nullable` modifier is not added to the rule definition, the validator would consider `null` an invalid date.

<a name="validation-error-response-format"></a>
### Validation Error Response Format

When your application throws a `Illuminate\Validation\ValidationException` exception and the incoming HTTP request is expecting a JSON response, Laravel will automatically format the error messages for you and return a `422 Unprocessable Entity` HTTP response.

Below, you can review an example of the JSON response format for validation errors. Note that nested error keys are flattened into "dot" notation format:

```json
{
    "message": "The team name must be a string. (and 4 more errors)",
    "errors": {
        "team_name": [
            "The team name must be a string.",
            "The team name must be at least 1 characters."
        ],
        "authorization.role": [
            "The selected authorization.role is invalid."
        ],
        "users.0.email": [
            "The users.0.email field is required."
        ],
        "users.2.email": [
            "The users.2.email must be a valid email address."
        ]
    }
}
```

<a name="form-request-validation"></a>
## Form Request Validation

<a name="creating-form-requests"></a>
### Creating Form Requests

For more complex validation scenarios, you may wish to create a "form request". Form requests are custom request classes that encapsulate their own validation and authorization logic. To create a form request class, you may use the `make:request` Artisan CLI command:

```shell
php artisan make:request StorePostRequest
```

The generated form request class will be placed in the `app/Http/Requests` directory. If this directory does not exist, it will be created when you run the `make:request` command. Each form request generated by Laravel has two methods: `authorize` and `rules`.

As you might have guessed, the `authorize` method is responsible for determining if the currently authenticated user can perform the action represented by the request, while the `rules` method returns the validation rules that should apply to the request's data:

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\Rule|array|string>
     */
    public function rules(): array
    {
        return [
            'title' => 'required|unique:posts|max:255',
            'body' => 'required',
        ];
    }

> [!NOTE]  
> You may type-hint any dependencies you require within the `rules` method's signature. They will automatically be resolved via the Laravel [service container](/docs/{{version}}/container).

So, how are the validation rules evaluated? All you need to do is type-hint the request on your controller method. The incoming form request is validated before the controller method is called, meaning you do not need to clutter your controller with any validation logic:

    /**
     * Store a new blog post.
     */
    public function store(StorePostRequest $request): RedirectResponse
    {
        // The incoming request is valid...

        // Retrieve the validated input data...
        $validated = $request->validated();

        // Retrieve a portion of the validated input data...
        $validated = $request->safe()->only(['name', 'email']);
        $validated = $request->safe()->except(['name', 'email']);

        // Store the blog post...

        return redirect('/posts');
    }

If validation fails, a redirect response will be generated to send the user back to their previous location. The errors will also be flashed to the session so they are available for display. If the request was an XHR request, an HTTP response with a 422 status code will be returned to the user including a [JSON representation of the validation errors](#validation-error-response-format).

> [!NOTE]  
> Need to add real-time form request validation to your Inertia powered Laravel frontend? Check out [Laravel Precognition](/docs/{{version}}/precognition).

<a name="performing-additional-validation-on-form-requests"></a>
#### Performing Additional Validation

Sometimes you need to perform additional validation after your initial validation is complete. You can accomplish this using the form request's `after` method.

The `after` method should return an array of callables or closures which will be invoked after validation is complete. The given callables will receive an `Illuminate\Validation\Validator` instance, allowing you to raise additional error messages if necessary:

    use Illuminate\Validation\Validator;

    /**
     * Get the "after" validation callables for the request.
     */
    public function after(): array
    {
        return [
            function (Validator $validator) {
                if ($this->somethingElseIsInvalid()) {
                    $validator->errors()->add(
                        'field',
                        'Something is wrong with this field!'
                    );
                }
            }
        ];
    }

As noted, the array returned by the `after` method may also contain invokable classes. The `__invoke` method of these classes will receive an `Illuminate\Validation\Validator` instance:

```php
use App\Validation\ValidateShippingTime;
use App\Validation\ValidateUserStatus;
use Illuminate\Validation\Validator;

/**
 * Get the "after" validation callables for the request.
 */
public function after(): array
{
    return [
        new ValidateUserStatus,
        new ValidateShippingTime,
        function (Validator $validator) {
            //
        }
    ];
}
```

<a name="request-stopping-on-first-validation-rule-failure"></a>
#### Stopping on the First Validation Failure

By adding a `stopOnFirstFailure` property to your request class, you may inform the validator that it should stop validating all attributes once a single validation failure has occurred:

    /**
     * Indicates if the validator should stop on the first rule failure.
     *
     * @var bool
     */
    protected $stopOnFirstFailure = true;

<a name="customizing-the-redirect-location"></a>
#### Customizing the Redirect Location

As previously discussed, a redirect response will be generated to send the user back to their previous location when form request validation fails. However, you are free to customize this behavior. To do so, define a `$redirect` property on your form request:

    /**
     * The URI that users should be redirected to if validation fails.
     *
     * @var string
     */
    protected $redirect = '/dashboard';

Or, if you would like to redirect users to a named route, you may define a `$redirectRoute` property instead:

    /**
     * The route that users should be redirected to if validation fails.
     *
     * @var string
     */
    protected $redirectRoute = 'dashboard';

<a name="authorizing-form-requests"></a>
### Authorizing Form Requests

The form request class also contains an `authorize` method. Within this method, you may determine if the authenticated user actually has the authority to update a given resource. For example, you may determine if a user actually owns a blog comment they are attempting to update. Most likely, you will interact with your [authorization gates and policies](/docs/{{version}}/authorization) within this method:

    use App\Models\Comment;

    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $comment = Comment::find($this->route('comment'));

        return $comment && $this->user()->can('update', $comment);
    }

Since all form requests extend the base Laravel request class, we may use the `user` method to access the currently authenticated user. Also, note the call to the `route` method in the example above. This method grants you access to the URI parameters defined on the route being called, such as the `{comment}` parameter in the example below:

    Route::post('/comment/{comment}');

Therefore, if your application is taking advantage of [route model binding](/docs/{{version}}/routing#route-model-binding), your code may be made even more succinct by accessing the resolved model as a property of the request:

    return $this->user()->can('update', $this->comment);

If the `authorize` method returns `false`, an HTTP response with a 403 status code will automatically be returned and your controller method will not execute.

If you plan to handle authorization logic for the request in another part of your application, you may remove the `authorize` method completely, or simply return `true`:

    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

> [!NOTE]  
> You may type-hint any dependencies you need within the `authorize` method's signature. They will automatically be resolved via the Laravel [service container](/docs/{{version}}/container).

<a name="customizing-the-error-messages"></a>
### Customizing the Error Messages

You may customize the error messages used by the form request by overriding the `messages` method. This method should return an array of attribute / rule pairs and their corresponding error messages:

    /**
     * Get the error messages for the defined validation rules.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'title.required' => 'A title is required',
            'body.required' => 'A message is required',
        ];
    }

<a name="customizing-the-validation-attributes"></a>
#### Customizing the Validation Attributes

Many of Laravel's built-in validation rule error messages contain an `:attribute` placeholder. If you would like the `:attribute` placeholder of your validation message to be replaced with a custom attribute name, you may specify the custom names by overriding the `attributes` method. This method should return an array of attribute / name pairs:

    /**
     * Get custom attributes for validator errors.
     *
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'email' => 'email address',
        ];
    }

<a name="preparing-input-for-validation"></a>
### Preparing Input for Validation

If you need to prepare or sanitize any data from the request before you apply your validation rules, you may use the `prepareForValidation` method:

    use Illuminate\Support\Str;

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        $this->merge([
            'slug' => Str::slug($this->slug),
        ]);
    }

Likewise, if you need to normalize any request data after validation is complete, you may use the `passedValidation` method:

    /**
     * Handle a passed validation attempt.
     */
    protected function passedValidation(): void
    {
        $this->replace(['name' => 'Taylor']);
    }

<a name="manually-creating-validators"></a>
## Manually Creating Validators

If you do not want to use the `validate` method on the request, you may create a validator instance manually using the `Validator` [facade](/docs/{{version}}/facades). The `make` method on the facade generates a new validator instance:

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\RedirectResponse;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Validator;

    class PostController extends Controller
    {
        /**
         * Store a new blog post.
         */
        public function store(Request $request): RedirectResponse
        {
            $validator = Validator::make($request->all(), [
                'title' => 'required|unique:posts|max:255',
                'body' => 'required',
            ]);

            if ($validator->fails()) {
                return redirect('post/create')
                            ->withErrors($validator)
                            ->withInput();
            }

            // Retrieve the validated input...
            $validated = $validator->validated();

            // Retrieve a portion of the validated input...
            $validated = $validator->safe()->only(['name', 'email']);
            $validated = $validator->safe()->except(['name', 'email']);

            // Store the blog post...

            return redirect('/posts');
        }
    }

The first argument passed to the `make` method is the data under validation. The second argument is an array of the validation rules that should be applied to the data.

After determining whether the request validation failed, you may use the `withErrors` method to flash the error messages to the session. When using this method, the `$errors` variable will automatically be shared with your views after redirection, allowing you to easily display them back to the user. The `withErrors` method accepts a validator, a `MessageBag`, or a PHP `array`.

#### Stopping on First Validation Failure

The `stopOnFirstFailure` method will inform the validator that it should stop validating all attributes once a single validation failure has occurred:

    if ($validator->stopOnFirstFailure()->fails()) {
        // ...
    }

<a name="automatic-redirection"></a>
### Automatic Redirection

If you would like to create a validator instance manually but still take advantage of the automatic redirection offered by the HTTP request's `validate` method, you may call the `validate` method on an existing validator instance. If validation fails, the user will automatically be redirected or, in the case of an XHR request, a [JSON response will be returned](#validation-error-response-format):

    Validator::make($request->all(), [
        'title' => 'required|unique:posts|max:255',
        'body' => 'required',
    ])->validate();

You may use the `validateWithBag` method to store the error messages in a [named error bag](#named-error-bags) if validation fails:

    Validator::make($request->all(), [
        'title' => 'required|unique:posts|max:255',
        'body' => 'required',
    ])->validateWithBag('post');

<a name="named-error-bags"></a>
### Named Error Bags

If you have multiple forms on a single page, you may wish to name the `MessageBag` containing the validation errors, allowing you to retrieve the error messages for a specific form. To achieve this, pass a name as the second argument to `withErrors`:

    return redirect('register')->withErrors($validator, 'login');

You may then access the named `MessageBag` instance from the `$errors` variable:

```blade
{{ $errors->login->first('email') }}
```

<a name="manual-customizing-the-error-messages"></a>
### Customizing the Error Messages

If needed, you may provide custom error messages that a validator instance should use instead of the default error messages provided by Laravel. There are several ways to specify custom messages. First, you may pass the custom messages as the third argument to the `Validator::make` method:

    $validator = Validator::make($input, $rules, $messages = [
        'required' => 'The :attribute field is required.',
    ]);

In this example, the `:attribute` placeholder will be replaced by the actual name of the field under validation. You may also utilize other placeholders in validation messages. For example:

    $messages = [
        'same' => 'The :attribute and :other must match.',
        'size' => 'The :attribute must be exactly :size.',
        'between' => 'The :attribute value :input is not between :min - :max.',
        'in' => 'The :attribute must be one of the following types: :values',
    ];

<a name="specifying-a-custom-message-for-a-given-attribute"></a>
#### Specifying a Custom Message for a Given Attribute

Sometimes you may wish to specify a custom error message only for a specific attribute. You may do so using "dot" notation. Specify the attribute's name first, followed by the rule:

    $messages = [
        'email.required' => 'We need to know your email address!',
    ];

<a name="specifying-custom-attribute-values"></a>
#### Specifying Custom Attribute Values

Many of Laravel's built-in error messages include an `:attribute` placeholder that is replaced with the name of the field or attribute under validation. To customize the values used to replace these placeholders for specific fields, you may pass an array of custom attributes as the fourth argument to the `Validator::make` method:

    $validator = Validator::make($input, $rules, $messages, [
        'email' => 'email address',
    ]);

<a name="performing-additional-validation"></a>
### Performing Additional Validation

Sometimes you need to perform additional validation after your initial validation is complete. You can accomplish this using the validator's `after` method. The `after` method accepts a closure or an array of callables which will be invoked after validation is complete. The given callables will receive an `Illuminate\Validation\Validator` instance, allowing you to raise additional error messages if necessary:

    use Illuminate\Support\Facades\Validator;

    $validator = Validator::make(/* ... */);

    $validator->after(function ($validator) {
        if ($this->somethingElseIsInvalid()) {
            $validator->errors()->add(
                'field', 'Something is wrong with this field!'
            );
        }
    });

    if ($validator->fails()) {
        // ...
    }

As noted, the `after` method also accepts an array of callables, which is particularly convenient if your "after validation" logic is encapsulated in invokable classes, which will receive an `Illuminate\Validation\Validator` instance via their `__invoke` method:

```php
use App\Validation\ValidateShippingTime;
use App\Validation\ValidateUserStatus;

$validator->after([
    new ValidateUserStatus,
    new ValidateShippingTime,
    function ($validator) {
        // ...
    },
]);
```

<a name="working-with-validated-input"></a>
## Working With Validated Input

After validating incoming request data using a form request or a manually created validator instance, you may wish to retrieve the incoming request data that actually underwent validation. This can be accomplished in several ways. First, you may call the `validated` method on a form request or validator instance. This method returns an array of the data that was validated:

    $validated = $request->validated();

    $validated = $validator->validated();

Alternatively, you may call the `safe` method on a form request or validator instance. This method returns an instance of `Illuminate\Support\ValidatedInput`. This object exposes `only`, `except`, and `all` methods to retrieve a subset of the validated data or the entire array of validated data:

    $validated = $request->safe()->only(['name', 'email']);

    $validated = $request->safe()->except(['name', 'email']);

    $validated = $request->safe()->all();

In addition, the `Illuminate\Support\ValidatedInput` instance may be iterated over and accessed like an array:

    // Validated data may be iterated...
    foreach ($request->safe() as $key => $value) {
        // ...
    }

    // Validated data may be accessed as an array...
    $validated = $request->safe();

    $email = $validated['email'];

If you would like to add additional fields to the validated data, you may call the `merge` method:

    $validated = $request->safe()->merge(['name' => 'Taylor Otwell']);

If you would like to retrieve the validated data as a [collection](/docs/{{version}}/collections) instance, you may call the `collect` method:

    $collection = $request->safe()->collect();

<a name="working-with-error-messages"></a>
## Working With Error Messages

After calling the `errors` method on a `Validator` instance, you will receive an `Illuminate\Support\MessageBag` instance, which has a variety of convenient methods for working with error messages. The `$errors` variable that is automatically made available to all views is also an instance of the `MessageBag` class.

<a name="retrieving-the-first-error-message-for-a-field"></a>
#### Retrieving the First Error Message for a Field

To retrieve the first error message for a given field, use the `first` method:

    $errors = $validator->errors();

    echo $errors->first('email');

<a name="retrieving-all-error-messages-for-a-field"></a>
#### Retrieving All Error Messages for a Field

If you need to retrieve an array of all the messages for a given field, use the `get` method:

    foreach ($errors->get('email') as $message) {
        // ...
    }

If you are validating an array form field, you may retrieve all of the messages for each of the array elements using the `*` character:

    foreach ($errors->get('attachments.*') as $message) {
        // ...
    }

<a name="retrieving-all-error-messages-for-all-fields"></a>
#### Retrieving All Error Messages for All Fields

To retrieve an array of all messages for all fields, use the `all` method:

    foreach ($errors->all() as $message) {
        // ...
    }

<a name="determining-if-messages-exist-for-a-field"></a>
#### Determining if Messages Exist for a Field

The `has` method may be used to determine if any error messages exist for a given field:

    if ($errors->has('email')) {
        // ...
    }

<a name="specifying-custom-messages-in-language-files"></a>
### Specifying Custom Messages in Language Files

Laravel's built-in validation rules each have an error message that is located in your application's `lang/en/validation.php` file. If your application does not have a `lang` directory, you may instruct Laravel to create it using the `lang:publish` Artisan command.

Within the `lang/en/validation.php` file, you will find a translation entry for each validation rule. You are free to change or modify these messages based on the needs of your application.

In addition, you may copy this file to another language directory to translate the messages for your application's language. To learn more about Laravel localization, check out the complete [localization documentation](/docs/{{version}}/localization).

> [!WARNING]  
> By default, the Laravel application skeleton does not include the `lang` directory. If you would like to customize Laravel's language files, you may publish them via the `lang:publish` Artisan command.

<a name="custom-messages-for-specific-attributes"></a>
#### Custom Messages for Specific Attributes

You may customize the error messages used for specified attribute and rule combinations within your application's validation language files. To do so, add your message customizations to the `custom` array of your application's `lang/xx/validation.php` language file:

    'custom' => [
        'email' => [
            'required' => 'We need to know your email address!',
            'max' => 'Your email address is too long!'
        ],
    ],

<a name="specifying-attribute-in-language-files"></a>
### Specifying Attributes in Language Files

Many of Laravel's built-in error messages include an `:attribute` placeholder that is replaced with the name of the field or attribute under validation. If you would like the `:attribute` portion of your validation message to be replaced with a custom value, you may specify the custom attribute name in the `attributes` array of your `lang/xx/validation.php` language file:

    'attributes' => [
        'email' => 'email address',
    ],

> [!WARNING]  
> By default, the Laravel application skeleton does not include the `lang` directory. If you would like to customize Laravel's language files, you may publish them via the `lang:publish` Artisan command.

<a name="specifying-values-in-language-files"></a>
### Specifying Values in Language Files

Some of Laravel's built-in validation rule error messages contain a `:value` placeholder that is replaced with the current value of the request attribute. However, you may occasionally need the `:value` portion of your validation message to be replaced with a custom representation of the value. For example, consider the following rule that specifies that a credit card number is required if the `payment_type` has a value of `cc`:

    Validator::make($request->all(), [
        'credit_card_number' => 'required_if:payment_type,cc'
    ]);

If this validation rule fails, it will produce the following error message:

```none
The credit card number field is required when payment type is cc.
```

Instead of displaying `cc` as the payment type value, you may specify a more user-friendly value representation in your `lang/xx/validation.php` language file by defining a `values` array:

    'values' => [
        'payment_type' => [
            'cc' => 'credit card'
        ],
    ],

> [!WARNING]  
> By default, the Laravel application skeleton does not include the `lang` directory. If you would like to customize Laravel's language files, you may publish them via the `lang:publish` Artisan command.

After defining this value, the validation rule will produce the following error message:

```none
The credit card number field is required when payment type is credit card.
```

<a name="available-validation-rules"></a>
## Available Validation Rules

Below is a list of all available validation rules and their function:

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
</style>

<div class="collection-method-list" markdown="1">

[Accepted](#rule-accepted)
[Accepted If](#rule-accepted-if)
[Active URL](#rule-active-url)
[After (Date)](#rule-after)
[After Or Equal (Date)](#rule-after-or-equal)
[Alpha](#rule-alpha)
[Alpha Dash](#rule-alpha-dash)
[Alpha Numeric](#rule-alpha-num)
[Array](#rule-array)
[Ascii](#rule-ascii)
[Bail](#rule-bail)
[Before (Date)](#rule-before)
[Before Or Equal (Date)](#rule-before-or-equal)
[Between](#rule-between)
[Boolean](#rule-boolean)
[Confirmed](#rule-confirmed)
[Current Password](#rule-current-password)
[Date](#rule-date)
[Date Equals](#rule-date-equals)
[Date Format](#rule-date-format)
[Decimal](#rule-decimal)
[Declined](#rule-declined)
[Declined If](#rule-declined-if)
[Different](#rule-different)
[Digits](#rule-digits)
[Digits Between](#rule-digits-between)
[Dimensions (Image Files)](#rule-dimensions)
[Distinct](#rule-distinct)
[Doesnt Start With](#rule-doesnt-start-with)
[Doesnt End With](#rule-doesnt-end-with)
[Email](#rule-email)
[Ends With](#rule-ends-with)
[Enum](#rule-enum)
[Exclude](#rule-exclude)
[Exclude If](#rule-exclude-if)
[Exclude Unless](#rule-exclude-unless)
[Exclude With](#rule-exclude-with)
[Exclude Without](#rule-exclude-without)
[Exists (Database)](#rule-exists)
[Extensions](#rule-extensions)
[File](#rule-file)
[Filled](#rule-filled)
[Greater Than](#rule-gt)
[Greater Than Or Equal](#rule-gte)
[Hex Color](#rule-hex-color)
[Image (File)](#rule-image)
[In](#rule-in)
[In Array](#rule-in-array)
[Integer](#rule-integer)
[IP Address](#rule-ip)
[JSON](#rule-json)
[Less Than](#rule-lt)
[Less Than Or Equal](#rule-lte)
[Lowercase](#rule-lowercase)
[MAC Address](#rule-mac)
[Max](#rule-max)
[Max Digits](#rule-max-digits)
[MIME Types](#rule-mimetypes)
[MIME Type By File Extension](#rule-mimes)
[Min](#rule-min)
[Min Digits](#rule-min-digits)
[Missing](#rule-missing)
[Missing If](#rule-missing-if)
[Missing Unless](#rule-missing-unless)
[Missing With](#rule-missing-with)
[Missing With All](#rule-missing-with-all)
[Multiple Of](#rule-multiple-of)
[Not In](#rule-not-in)
[Not Regex](#rule-not-regex)
[Nullable](#rule-nullable)
[Numeric](#rule-numeric)
[Present](#rule-present)
[Present If](#rule-present-if)
[Present Unless](#rule-present-unless)
[Present With](#rule-present-with)
[Present With All](#rule-present-with-all)
[Prohibited](#rule-prohibited)
[Prohibited If](#rule-prohibited-if)
[Prohibited Unless](#rule-prohibited-unless)
[Prohibits](#rule-prohibits)
[Regular Expression](#rule-regex)
[Required](#rule-required)
[Required If](#rule-required-if)
[Required If Accepted](#rule-required-if-accepted)
[Required Unless](#rule-required-unless)
[Required With](#rule-required-with)
[Required With All](#rule-required-with-all)
[Required Without](#rule-required-without)
[Required Without All](#rule-required-without-all)
[Required Array Keys](#rule-required-array-keys)
[Same](#rule-same)
[Size](#rule-size)
[Sometimes](#validating-when-present)
[Starts With](#rule-starts-with)
[String](#rule-string)
[Timezone](#rule-timezone)
[Unique (Database)](#rule-unique)
[Uppercase](#rule-uppercase)
[URL](#rule-url)
[ULID](#rule-ulid)
[UUID](#rule-uuid)

</div>

<a name="rule-accepted"></a>
#### accepted

The field under validation must be `"yes"`, `"on"`, `1`, `"1"`, `true`, or `"true"`. This is useful for validating "Terms of Service" acceptance or similar fields.

<a name="rule-accepted-if"></a>
#### accepted_if:anotherfield,value,...

The field under validation must be `"yes"`, `"on"`, `1`, `"1"`, `true`, or `"true"` if another field under validation is equal to a specified value. This is useful for validating "Terms of Service" acceptance or similar fields.

<a name="rule-active-url"></a>
#### active_url

The field under validation must have a valid A or AAAA record according to the `dns_get_record` PHP function. The hostname of the provided URL is extracted using the `parse_url` PHP function before being passed to `dns_get_record`.

<a name="rule-after"></a>
#### after:_date_

The field under validation must be a value after a given date. The dates will be passed into the `strtotime` PHP function in order to be converted to a valid `DateTime` instance:

    'start_date' => 'required|date|after:tomorrow'

Instead of passing a date string to be evaluated by `strtotime`, you may specify another field to compare against the date:

    'finish_date' => 'required|date|after:start_date'

<a name="rule-after-or-equal"></a>
#### after\_or\_equal:_date_

The field under validation must be a value after or equal to the given date. For more information, see the [after](#rule-after) rule.

<a name="rule-alpha"></a>
#### alpha

The field under validation must be entirely Unicode alphabetic characters contained in [`\p{L}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AL%3A%5D&g=&i=) and [`\p{M}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AM%3A%5D&g=&i=).

To restrict this validation rule to characters in the ASCII range (`a-z` and `A-Z`), you may provide the `ascii` option to the validation rule:

```php
'username' => 'alpha:ascii',
```

<a name="rule-alpha-dash"></a>
#### alpha_dash

The field under validation must be entirely Unicode alpha-numeric characters contained in [`\p{L}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AL%3A%5D&g=&i=), [`\p{M}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AM%3A%5D&g=&i=), [`\p{N}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AN%3A%5D&g=&i=), as well as ASCII dashes (`-`) and ASCII underscores (`_`).

To restrict this validation rule to characters in the ASCII range (`a-z` and `A-Z`), you may provide the `ascii` option to the validation rule:

```php
'username' => 'alpha_dash:ascii',
```

<a name="rule-alpha-num"></a>
#### alpha_num

The field under validation must be entirely Unicode alpha-numeric characters contained in [`\p{L}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AL%3A%5D&g=&i=), [`\p{M}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AM%3A%5D&g=&i=), and [`\p{N}`](https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AN%3A%5D&g=&i=).

To restrict this validation rule to characters in the ASCII range (`a-z` and `A-Z`), you may provide the `ascii` option to the validation rule:

```php
'username' => 'alpha_num:ascii',
```

<a name="rule-array"></a>
#### array

The field under validation must be a PHP `array`.

When additional values are provided to the `array` rule, each key in the input array must be present within the list of values provided to the rule. In the following example, the `admin` key in the input array is invalid since it is not contained in the list of values provided to the `array` rule:

    use Illuminate\Support\Facades\Validator;

    $input = [
        'user' => [
            'name' => 'Taylor Otwell',
            'username' => 'taylorotwell',
            'admin' => true,
        ],
    ];

    Validator::make($input, [
        'user' => 'array:name,username',
    ]);

In general, you should always specify the array keys that are allowed to be present within your array.

<a name="rule-ascii"></a>
#### ascii

The field under validation must be entirely 7-bit ASCII characters.

<a name="rule-bail"></a>
#### bail

Stop running validation rules for the field after the first validation failure.

While the `bail` rule will only stop validating a specific field when it encounters a validation failure, the `stopOnFirstFailure` method will inform the validator that it should stop validating all attributes once a single validation failure has occurred:

    if ($validator->stopOnFirstFailure()->fails()) {
        // ...
    }

<a name="rule-before"></a>
#### before:_date_

The field under validation must be a value preceding the given date. The dates will be passed into the PHP `strtotime` function in order to be converted into a valid `DateTime` instance. In addition, like the [`after`](#rule-after) rule, the name of another field under validation may be supplied as the value of `date`.

<a name="rule-before-or-equal"></a>
#### before\_or\_equal:_date_

The field under validation must be a value preceding or equal to the given date. The dates will be passed into the PHP `strtotime` function in order to be converted into a valid `DateTime` instance. In addition, like the [`after`](#rule-after) rule, the name of another field under validation may be supplied as the value of `date`.

<a name="rule-between"></a>
#### between:_min_,_max_

The field under validation must have a size between the given _min_ and _max_ (inclusive). Strings, numerics, arrays, and files are evaluated in the same fashion as the [`size`](#rule-size) rule.

<a name="rule-boolean"></a>
#### boolean

The field under validation must be able to be cast as a boolean. Accepted input are `true`, `false`, `1`, `0`, `"1"`, and `"0"`.

<a name="rule-confirmed"></a>
#### confirmed

The field under validation must have a matching field of `{field}_confirmation`. For example, if the field under validation is `password`, a matching `password_confirmation` field must be present in the input.

<a name="rule-current-password"></a>
#### current_password

The field under validation must match the authenticated user's password. You may specify an [authentication guard](/docs/{{version}}/authentication) using the rule's first parameter:

    'password' => 'current_password:api'

<a name="rule-date"></a>
#### date

The field under validation must be a valid, non-relative date according to the `strtotime` PHP function.

<a name="rule-date-equals"></a>
#### date_equals:_date_

The field under validation must be equal to the given date. The dates will be passed into the PHP `strtotime` function in order to be converted into a valid `DateTime` instance.

<a name="rule-date-format"></a>
#### date_format:_format_,...

The field under validation must match one of the given _formats_. You should use **either** `date` or `date_format` when validating a field, not both. This validation rule supports all formats supported by PHP's [DateTime](https://www.php.net/manual/en/class.datetime.php) class.

<a name="rule-decimal"></a>
#### decimal:_min_,_max_

The field under validation must be numeric and must contain the specified number of decimal places:

    // Must have exactly two decimal places (9.99)...
    'price' => 'decimal:2'

    // Must have between 2 and 4 decimal places...
    'price' => 'decimal:2,4'

<a name="rule-declined"></a>
#### declined

The field under validation must be `"no"`, `"off"`, `0`, `"0"`, `false`, or `"false"`.

<a name="rule-declined-if"></a>
#### declined_if:anotherfield,value,...

The field under validation must be `"no"`, `"off"`, `0`, `"0"`, `false`, or `"false"` if another field under validation is equal to a specified value.

<a name="rule-different"></a>
#### different:_field_

The field under validation must have a different value than _field_.

<a name="rule-digits"></a>
#### digits:_value_

The integer under validation must have an exact length of _value_.

<a name="rule-digits-between"></a>
#### digits_between:_min_,_max_

The integer validation must have a length between the given _min_ and _max_.

<a name="rule-dimensions"></a>
#### dimensions

The file under validation must be an image meeting the dimension constraints as specified by the rule's parameters:

    'avatar' => 'dimensions:min_width=100,min_height=200'

Available constraints are: _min\_width_, _max\_width_, _min\_height_, _max\_height_, _width_, _height_, _ratio_.

A _ratio_ constraint should be represented as width divided by height. This can be specified either by a fraction like `3/2` or a float like `1.5`:

    'avatar' => 'dimensions:ratio=3/2'

Since this rule requires several arguments, you may use the `Rule::dimensions` method to fluently construct the rule:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'avatar' => [
            'required',
            Rule::dimensions()->maxWidth(1000)->maxHeight(500)->ratio(3 / 2),
        ],
    ]);

<a name="rule-distinct"></a>
#### distinct

When validating arrays, the field under validation must not have any duplicate values:

    'foo.*.id' => 'distinct'

Distinct uses loose variable comparisons by default. To use strict comparisons, you may add the `strict` parameter to your validation rule definition:

    'foo.*.id' => 'distinct:strict'

You may add `ignore_case` to the validation rule's arguments to make the rule ignore capitalization differences:

    'foo.*.id' => 'distinct:ignore_case'

<a name="rule-doesnt-start-with"></a>
#### doesnt_start_with:_foo_,_bar_,...

The field under validation must not start with one of the given values.

<a name="rule-doesnt-end-with"></a>
#### doesnt_end_with:_foo_,_bar_,...

The field under validation must not end with one of the given values.

<a name="rule-email"></a>
#### email

The field under validation must be formatted as an email address. This validation rule utilizes the [`egulias/email-validator`](https://github.com/egulias/EmailValidator) package for validating the email address. By default, the `RFCValidation` validator is applied, but you can apply other validation styles as well:

    'email' => 'email:rfc,dns'

The example above will apply the `RFCValidation` and `DNSCheckValidation` validations. Here's a full list of validation styles you can apply:

<div class="content-list" markdown="1">

- `rfc`: `RFCValidation`
- `strict`: `NoRFCWarningsValidation`
- `dns`: `DNSCheckValidation`
- `spoof`: `SpoofCheckValidation`
- `filter`: `FilterEmailValidation`
- `filter_unicode`: `FilterEmailValidation::unicode()`

</div>

The `filter` validator, which uses PHP's `filter_var` function, ships with Laravel and was Laravel's default email validation behavior prior to Laravel version 5.8.

> [!WARNING]  
> The `dns` and `spoof` validators require the PHP `intl` extension.

<a name="rule-ends-with"></a>
#### ends_with:_foo_,_bar_,...

The field under validation must end with one of the given values.

<a name="rule-enum"></a>
#### enum

The `Enum` rule is a class based rule that validates whether the field under validation contains a valid enum value. The `Enum` rule accepts the name of the enum as its only constructor argument. When validating primitive values, a backed Enum should be provided to the `Enum` rule:

    use App\Enums\ServerStatus;
    use Illuminate\Validation\Rule;

    $request->validate([
        'status' => [Rule::enum(ServerStatus::class)],
    ]);

The `Enum` rule's `only` and `except` methods may be used to limit which enum cases should be considered valid:

    Rule::enum(ServerStatus::class)
        ->only([ServerStatus::Pending, ServerStatus::Active]);

    Rule::enum(ServerStatus::class)
        ->except([ServerStatus::Pending, ServerStatus::Active]);

The `when` method may be used to conditionally modify the `Enum` rule:

```php
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

Rule::enum(ServerStatus::class)
    ->when(
        Auth::user()->isAdmin(),
        fn ($rule) => $rule->only(...),
        fn ($rule) => $rule->only(...),
    );
```

<a name="rule-exclude"></a>
#### exclude

The field under validation will be excluded from the request data returned by the `validate` and `validated` methods.

<a name="rule-exclude-if"></a>
#### exclude_if:_anotherfield_,_value_

The field under validation will be excluded from the request data returned by the `validate` and `validated` methods if the _anotherfield_ field is equal to _value_.

If complex conditional exclusion logic is required, you may utilize the `Rule::excludeIf` method. This method accepts a boolean or a closure. When given a closure, the closure should return `true` or `false` to indicate if the field under validation should be excluded:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($request->all(), [
        'role_id' => Rule::excludeIf($request->user()->is_admin),
    ]);

    Validator::make($request->all(), [
        'role_id' => Rule::excludeIf(fn () => $request->user()->is_admin),
    ]);

<a name="rule-exclude-unless"></a>
#### exclude_unless:_anotherfield_,_value_

The field under validation will be excluded from the request data returned by the `validate` and `validated` methods unless _anotherfield_'s field is equal to _value_. If _value_ is `null` (`exclude_unless:name,null`), the field under validation will be excluded unless the comparison field is `null` or the comparison field is missing from the request data.

<a name="rule-exclude-with"></a>
#### exclude_with:_anotherfield_

The field under validation will be excluded from the request data returned by the `validate` and `validated` methods if the _anotherfield_ field is present.

<a name="rule-exclude-without"></a>
#### exclude_without:_anotherfield_

The field under validation will be excluded from the request data returned by the `validate` and `validated` methods if the _anotherfield_ field is not present.

<a name="rule-exists"></a>
#### exists:_table_,_column_

The field under validation must exist in a given database table.

<a name="basic-usage-of-exists-rule"></a>
#### Basic Usage of Exists Rule

    'state' => 'exists:states'

If the `column` option is not specified, the field name will be used. So, in this case, the rule will validate that the `states` database table contains a record with a `state` column value matching the request's `state` attribute value.

<a name="specifying-a-custom-column-name"></a>
#### Specifying a Custom Column Name

You may explicitly specify the database column name that should be used by the validation rule by placing it after the database table name:

    'state' => 'exists:states,abbreviation'

Occasionally, you may need to specify a specific database connection to be used for the `exists` query. You can accomplish this by prepending the connection name to the table name:

    'email' => 'exists:connection.staff,email'

Instead of specifying the table name directly, you may specify the Eloquent model which should be used to determine the table name:

    'user_id' => 'exists:App\Models\User,id'

If you would like to customize the query executed by the validation rule, you may use the `Rule` class to fluently define the rule. In this example, we'll also specify the validation rules as an array instead of using the `|` character to delimit them:

    use Illuminate\Database\Query\Builder;
    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'email' => [
            'required',
            Rule::exists('staff')->where(function (Builder $query) {
                return $query->where('account_id', 1);
            }),
        ],
    ]);

You may explicitly specify the database column name that should be used by the `exists` rule generated by the `Rule::exists` method by providing the column name as the second argument to the `exists` method:

    'state' => Rule::exists('states', 'abbreviation'),

<a name="rule-extensions"></a>
#### extensions:_foo_,_bar_,...

The file under validation must have a user-assigned extension corresponding to one of the listed extensions:

    'photo' => ['required', 'extensions:jpg,png'],

> [!WARNING]  
> You should never rely on validating a file by its user-assigned extension alone. This rule should typically always be used in combination with the [`mimes`](#rule-mimes) or [`mimetypes`](#rule-mimetypes) rules.

<a name="rule-file"></a>
#### file

The field under validation must be a successfully uploaded file.

<a name="rule-filled"></a>
#### filled

The field under validation must not be empty when it is present.

<a name="rule-gt"></a>
#### gt:_field_

The field under validation must be greater than the given _field_ or _value_. The two fields must be of the same type. Strings, numerics, arrays, and files are evaluated using the same conventions as the [`size`](#rule-size) rule.

<a name="rule-gte"></a>
#### gte:_field_

The field under validation must be greater than or equal to the given _field_ or _value_. The two fields must be of the same type. Strings, numerics, arrays, and files are evaluated using the same conventions as the [`size`](#rule-size) rule.

<a name="rule-hex-color"></a>
#### hex_color

The field under validation must contain a valid color value in [hexadecimal](https://developer.mozilla.org/en-US/docs/Web/CSS/hex-color) format.

<a name="rule-image"></a>
#### image

The file under validation must be an image (jpg, jpeg, png, bmp, gif, svg, or webp).

<a name="rule-in"></a>
#### in:_foo_,_bar_,...

The field under validation must be included in the given list of values. Since this rule often requires you to `implode` an array, the `Rule::in` method may be used to fluently construct the rule:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'zones' => [
            'required',
            Rule::in(['first-zone', 'second-zone']),
        ],
    ]);

When the `in` rule is combined with the `array` rule, each value in the input array must be present within the list of values provided to the `in` rule. In the following example, the `LAS` airport code in the input array is invalid since it is not contained in the list of airports provided to the `in` rule:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    $input = [
        'airports' => ['NYC', 'LAS'],
    ];

    Validator::make($input, [
        'airports' => [
            'required',
            'array',
        ],
        'airports.*' => Rule::in(['NYC', 'LIT']),
    ]);

<a name="rule-in-array"></a>
#### in_array:_anotherfield_.*

The field under validation must exist in _anotherfield_'s values.

<a name="rule-integer"></a>
#### integer

The field under validation must be an integer.

> [!WARNING]  
> This validation rule does not verify that the input is of the "integer" variable type, only that the input is of a type accepted by PHP's `FILTER_VALIDATE_INT` rule. If you need to validate the input as being a number please use this rule in combination with [the `numeric` validation rule](#rule-numeric).

<a name="rule-ip"></a>
#### ip

The field under validation must be an IP address.

<a name="ipv4"></a>
#### ipv4

The field under validation must be an IPv4 address.

<a name="ipv6"></a>
#### ipv6

The field under validation must be an IPv6 address.

<a name="rule-json"></a>
#### json

The field under validation must be a valid JSON string.

<a name="rule-lt"></a>
#### lt:_field_

The field under validation must be less than the given _field_. The two fields must be of the same type. Strings, numerics, arrays, and files are evaluated using the same conventions as the [`size`](#rule-size) rule.

<a name="rule-lte"></a>
#### lte:_field_

The field under validation must be less than or equal to the given _field_. The two fields must be of the same type. Strings, numerics, arrays, and files are evaluated using the same conventions as the [`size`](#rule-size) rule.

<a name="rule-lowercase"></a>
#### lowercase

The field under validation must be lowercase.

<a name="rule-mac"></a>
#### mac_address

The field under validation must be a MAC address.

<a name="rule-max"></a>
#### max:_value_

The field under validation must be less than or equal to a maximum _value_. Strings, numerics, arrays, and files are evaluated in the same fashion as the [`size`](#rule-size) rule.

<a name="rule-max-digits"></a>
#### max_digits:_value_

The integer under validation must have a maximum length of _value_.

<a name="rule-mimetypes"></a>
#### mimetypes:_text/plain_,...

The file under validation must match one of the given MIME types:

    'video' => 'mimetypes:video/avi,video/mpeg,video/quicktime'

To determine the MIME type of the uploaded file, the file's contents will be read and the framework will attempt to guess the MIME type, which may be different from the client's provided MIME type.

<a name="rule-mimes"></a>
#### mimes:_foo_,_bar_,...

The file under validation must have a MIME type corresponding to one of the listed extensions:

    'photo' => 'mimes:jpg,bmp,png'

Even though you only need to specify the extensions, this rule actually validates the MIME type of the file by reading the file's contents and guessing its MIME type. A full listing of MIME types and their corresponding extensions may be found at the following location:

[https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types](https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types)

<a name="mime-types-and-extensions"></a>
#### MIME Types and Extensions

This validation rule does not verify agreement between the MIME type and the extension the user assigned to the file. For example, the `mimes:png` validation rule would consider a file containing valid PNG content to be a valid PNG image, even if the file is named `photo.txt`. If you would like to validate the user-assigned extension of the file, you may use the [`extensions`](#rule-extensions) rule.

<a name="rule-min"></a>
#### min:_value_

The field under validation must have a minimum _value_. Strings, numerics, arrays, and files are evaluated in the same fashion as the [`size`](#rule-size) rule.

<a name="rule-min-digits"></a>
#### min_digits:_value_

The integer under validation must have a minimum length of _value_.

<a name="rule-multiple-of"></a>
#### multiple_of:_value_

The field under validation must be a multiple of _value_.

<a name="rule-missing"></a>
#### missing

The field under validation must not be present in the input data.

 <a name="rule-missing-if"></a>
 #### missing_if:_anotherfield_,_value_,...

 The field under validation must not be present if the _anotherfield_ field is equal to any _value_.

 <a name="rule-missing-unless"></a>
 #### missing_unless:_anotherfield_,_value_

The field under validation must not be present unless the _anotherfield_ field is equal to any _value_.

 <a name="rule-missing-with"></a>
 #### missing_with:_foo_,_bar_,...

 The field under validation must not be present _only if_ any of the other specified fields are present.

 <a name="rule-missing-with-all"></a>
 #### missing_with_all:_foo_,_bar_,...

 The field under validation must not be present _only if_ all of the other specified fields are present.

<a name="rule-not-in"></a>
#### not_in:_foo_,_bar_,...

The field under validation must not be included in the given list of values. The `Rule::notIn` method may be used to fluently construct the rule:

    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'toppings' => [
            'required',
            Rule::notIn(['sprinkles', 'cherries']),
        ],
    ]);

<a name="rule-not-regex"></a>
#### not_regex:_pattern_

The field under validation must not match the given regular expression.

Internally, this rule uses the PHP `preg_match` function. The pattern specified should obey the same formatting required by `preg_match` and thus also include valid delimiters. For example: `'email' => 'not_regex:/^.+$/i'`.

> [!WARNING]  
> When using the `regex` / `not_regex` patterns, it may be necessary to specify your validation rules using an array instead of using `|` delimiters, especially if the regular expression contains a `|` character.

<a name="rule-nullable"></a>
#### nullable

The field under validation may be `null`.

<a name="rule-numeric"></a>
#### numeric

The field under validation must be [numeric](https://www.php.net/manual/en/function.is-numeric.php).

<a name="rule-present"></a>
#### present

The field under validation must exist in the input data.

<a name="rule-present-if"></a>
#### present_if:_anotherfield_,_value_,...

The field under validation must be present if the _anotherfield_ field is equal to any _value_.

<a name="rule-present-unless"></a>
#### present_unless:_anotherfield_,_value_

The field under validation must be present unless the _anotherfield_ field is equal to any _value_.

<a name="rule-present-with"></a>
#### present_with:_foo_,_bar_,...

The field under validation must be present _only if_ any of the other specified fields are present.

<a name="rule-present-with-all"></a>
#### present_with_all:_foo_,_bar_,...

The field under validation must be present _only if_ all of the other specified fields are present.

<a name="rule-prohibited"></a>
#### prohibited

The field under validation must be missing or empty. A field is "empty" if it meets one of the following criteria:

<div class="content-list" markdown="1">

- The value is `null`.
- The value is an empty string.
- The value is an empty array or empty `Countable` object.
- The value is an uploaded file with an empty path.

</div>

<a name="rule-prohibited-if"></a>
#### prohibited_if:_anotherfield_,_value_,...

The field under validation must be missing or empty if the _anotherfield_ field is equal to any _value_. A field is "empty" if it meets one of the following criteria:

<div class="content-list" markdown="1">

- The value is `null`.
- The value is an empty string.
- The value is an empty array or empty `Countable` object.
- The value is an uploaded file with an empty path.

</div>

If complex conditional prohibition logic is required, you may utilize the `Rule::prohibitedIf` method. This method accepts a boolean or a closure. When given a closure, the closure should return `true` or `false` to indicate if the field under validation should be prohibited:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($request->all(), [
        'role_id' => Rule::prohibitedIf($request->user()->is_admin),
    ]);

    Validator::make($request->all(), [
        'role_id' => Rule::prohibitedIf(fn () => $request->user()->is_admin),
    ]);

<a name="rule-prohibited-unless"></a>
#### prohibited_unless:_anotherfield_,_value_,...

The field under validation must be missing or empty unless the _anotherfield_ field is equal to any _value_. A field is "empty" if it meets one of the following criteria:

<div class="content-list" markdown="1">

- The value is `null`.
- The value is an empty string.
- The value is an empty array or empty `Countable` object.
- The value is an uploaded file with an empty path.

</div>

<a name="rule-prohibits"></a>
#### prohibits:_anotherfield_,...

If the field under validation is not missing or empty, all fields in _anotherfield_ must be missing or empty. A field is "empty" if it meets one of the following criteria:

<div class="content-list" markdown="1">

- The value is `null`.
- The value is an empty string.
- The value is an empty array or empty `Countable` object.
- The value is an uploaded file with an empty path.

</div>

<a name="rule-regex"></a>
#### regex:_pattern_

The field under validation must match the given regular expression.

Internally, this rule uses the PHP `preg_match` function. The pattern specified should obey the same formatting required by `preg_match` and thus also include valid delimiters. For example: `'email' => 'regex:/^.+@.+$/i'`.

> [!WARNING]  
> When using the `regex` / `not_regex` patterns, it may be necessary to specify rules in an array instead of using `|` delimiters, especially if the regular expression contains a `|` character.

<a name="rule-required"></a>
#### required

The field under validation must be present in the input data and not empty. A field is "empty" if it meets one of the following criteria:

<div class="content-list" markdown="1">

- The value is `null`.
- The value is an empty string.
- The value is an empty array or empty `Countable` object.
- The value is an uploaded file with no path.

</div>

<a name="rule-required-if"></a>
#### required_if:_anotherfield_,_value_,...

The field under validation must be present and not empty if the _anotherfield_ field is equal to any _value_.

If you would like to construct a more complex condition for the `required_if` rule, you may use the `Rule::requiredIf` method. This method accepts a boolean or a closure. When passed a closure, the closure should return `true` or `false` to indicate if the field under validation is required:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($request->all(), [
        'role_id' => Rule::requiredIf($request->user()->is_admin),
    ]);

    Validator::make($request->all(), [
        'role_id' => Rule::requiredIf(fn () => $request->user()->is_admin),
    ]);

<a name="rule-required-if-accepted"></a>
#### required_if_accepted:_anotherfield_,...

The field under validation must be present and not empty if the _anotherfield_ field is equal to `"yes"`, `"on"`, `1`, `"1"`, `true`, or `"true"`.

<a name="rule-required-unless"></a>
#### required_unless:_anotherfield_,_value_,...

The field under validation must be present and not empty unless the _anotherfield_ field is equal to any _value_. This also means _anotherfield_ must be present in the request data unless _value_ is `null`. If _value_ is `null` (`required_unless:name,null`), the field under validation will be required unless the comparison field is `null` or the comparison field is missing from the request data.

<a name="rule-required-with"></a>
#### required_with:_foo_,_bar_,...

The field under validation must be present and not empty _only if_ any of the other specified fields are present and not empty.

<a name="rule-required-with-all"></a>
#### required_with_all:_foo_,_bar_,...

The field under validation must be present and not empty _only if_ all of the other specified fields are present and not empty.

<a name="rule-required-without"></a>
#### required_without:_foo_,_bar_,...

The field under validation must be present and not empty _only when_ any of the other specified fields are empty or not present.

<a name="rule-required-without-all"></a>
#### required_without_all:_foo_,_bar_,...

The field under validation must be present and not empty _only when_ all of the other specified fields are empty or not present.

<a name="rule-required-array-keys"></a>
#### required_array_keys:_foo_,_bar_,...

The field under validation must be an array and must contain at least the specified keys.

<a name="rule-same"></a>
#### same:_field_

The given _field_ must match the field under validation.

<a name="rule-size"></a>
#### size:_value_

The field under validation must have a size matching the given _value_. For string data, _value_ corresponds to the number of characters. For numeric data, _value_ corresponds to a given integer value (the attribute must also have the `numeric` or `integer` rule). For an array, _size_ corresponds to the `count` of the array. For files, _size_ corresponds to the file size in kilobytes. Let's look at some examples:

    // Validate that a string is exactly 12 characters long...
    'title' => 'size:12';

    // Validate that a provided integer equals 10...
    'seats' => 'integer|size:10';

    // Validate that an array has exactly 5 elements...
    'tags' => 'array|size:5';

    // Validate that an uploaded file is exactly 512 kilobytes...
    'image' => 'file|size:512';

<a name="rule-starts-with"></a>
#### starts_with:_foo_,_bar_,...

The field under validation must start with one of the given values.

<a name="rule-string"></a>
#### string

The field under validation must be a string. If you would like to allow the field to also be `null`, you should assign the `nullable` rule to the field.

<a name="rule-timezone"></a>
#### timezone

The field under validation must be a valid timezone identifier according to the `DateTimeZone::listIdentifiers` method.

The arguments [accepted by the `DateTimeZone::listIdentifiers` method](https://www.php.net/manual/en/datetimezone.listidentifiers.php) may also be provided to this validation rule:

    'timezone' => 'required|timezone:all';

    'timezone' => 'required|timezone:Africa';

    'timezone' => 'required|timezone:per_country,US';

<a name="rule-unique"></a>
#### unique:_table_,_column_

The field under validation must not exist within the given database table.

**Specifying a Custom Table / Column Name:**

Instead of specifying the table name directly, you may specify the Eloquent model which should be used to determine the table name:

    'email' => 'unique:App\Models\User,email_address'

The `column` option may be used to specify the field's corresponding database column. If the `column` option is not specified, the name of the field under validation will be used.

    'email' => 'unique:users,email_address'

**Specifying a Custom Database Connection**

Occasionally, you may need to set a custom connection for database queries made by the Validator. To accomplish this, you may prepend the connection name to the table name:

    'email' => 'unique:connection.users,email_address'

**Forcing a Unique Rule to Ignore a Given ID:**

Sometimes, you may wish to ignore a given ID during unique validation. For example, consider an "update profile" screen that includes the user's name, email address, and location. You will probably want to verify that the email address is unique. However, if the user only changes the name field and not the email field, you do not want a validation error to be thrown because the user is already the owner of the email address in question.

To instruct the validator to ignore the user's ID, we'll use the `Rule` class to fluently define the rule. In this example, we'll also specify the validation rules as an array instead of using the `|` character to delimit the rules:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'email' => [
            'required',
            Rule::unique('users')->ignore($user->id),
        ],
    ]);

> [!WARNING]  
> You should never pass any user controlled request input into the `ignore` method. Instead, you should only pass a system generated unique ID such as an auto-incrementing ID or UUID from an Eloquent model instance. Otherwise, your application will be vulnerable to an SQL injection attack.

Instead of passing the model key's value to the `ignore` method, you may also pass the entire model instance. Laravel will automatically extract the key from the model:

    Rule::unique('users')->ignore($user)

If your table uses a primary key column name other than `id`, you may specify the name of the column when calling the `ignore` method:

    Rule::unique('users')->ignore($user->id, 'user_id')

By default, the `unique` rule will check the uniqueness of the column matching the name of the attribute being validated. However, you may pass a different column name as the second argument to the `unique` method:

    Rule::unique('users', 'email_address')->ignore($user->id)

**Adding Additional Where Clauses:**

You may specify additional query conditions by customizing the query using the `where` method. For example, let's add a query condition that scopes the query to only search records that have an `account_id` column value of `1`:

    'email' => Rule::unique('users')->where(fn (Builder $query) => $query->where('account_id', 1))

<a name="rule-uppercase"></a>
#### uppercase

The field under validation must be uppercase.

<a name="rule-url"></a>
#### url

The field under validation must be a valid URL.

If you would like to specify the URL protocols that should be considered valid, you may pass the protocols as validation rule parameters:

```php
'url' => 'url:http,https',

'game' => 'url:minecraft,steam',
```

<a name="rule-ulid"></a>
#### ulid

The field under validation must be a valid [Universally Unique Lexicographically Sortable Identifier](https://github.com/ulid/spec) (ULID).

<a name="rule-uuid"></a>
#### uuid

The field under validation must be a valid RFC 4122 (version 1, 3, 4, or 5) universally unique identifier (UUID).

<a name="conditionally-adding-rules"></a>
## Conditionally Adding Rules

<a name="skipping-validation-when-fields-have-certain-values"></a>
#### Skipping Validation When Fields Have Certain Values

You may occasionally wish to not validate a given field if another field has a given value. You may accomplish this using the `exclude_if` validation rule. In this example, the `appointment_date` and `doctor_name` fields will not be validated if the `has_appointment` field has a value of `false`:

    use Illuminate\Support\Facades\Validator;

    $validator = Validator::make($data, [
        'has_appointment' => 'required|boolean',
        'appointment_date' => 'exclude_if:has_appointment,false|required|date',
        'doctor_name' => 'exclude_if:has_appointment,false|required|string',
    ]);

Alternatively, you may use the `exclude_unless` rule to not validate a given field unless another field has a given value:

    $validator = Validator::make($data, [
        'has_appointment' => 'required|boolean',
        'appointment_date' => 'exclude_unless:has_appointment,true|required|date',
        'doctor_name' => 'exclude_unless:has_appointment,true|required|string',
    ]);

<a name="validating-when-present"></a>
#### Validating When Present

In some situations, you may wish to run validation checks against a field **only** if that field is present in the data being validated. To quickly accomplish this, add the `sometimes` rule to your rule list:

    $v = Validator::make($data, [
        'email' => 'sometimes|required|email',
    ]);

In the example above, the `email` field will only be validated if it is present in the `$data` array.

> [!NOTE]  
> If you are attempting to validate a field that should always be present but may be empty, check out [this note on optional fields](#a-note-on-optional-fields).

<a name="complex-conditional-validation"></a>
#### Complex Conditional Validation

Sometimes you may wish to add validation rules based on more complex conditional logic. For example, you may wish to require a given field only if another field has a greater value than 100. Or, you may need two fields to have a given value only when another field is present. Adding these validation rules doesn't have to be a pain. First, create a `Validator` instance with your _static rules_ that never change:

    use Illuminate\Support\Facades\Validator;

    $validator = Validator::make($request->all(), [
        'email' => 'required|email',
        'games' => 'required|numeric',
    ]);

Let's assume our web application is for game collectors. If a game collector registers with our application and they own more than 100 games, we want them to explain why they own so many games. For example, perhaps they run a game resale shop, or maybe they just enjoy collecting games. To conditionally add this requirement, we can use the `sometimes` method on the `Validator` instance.

    use Illuminate\Support\Fluent;

    $validator->sometimes('reason', 'required|max:500', function (Fluent $input) {
        return $input->games >= 100;
    });

The first argument passed to the `sometimes` method is the name of the field we are conditionally validating. The second argument is a list of the rules we want to add. If the closure passed as the third argument returns `true`, the rules will be added. This method makes it a breeze to build complex conditional validations. You may even add conditional validations for several fields at once:

    $validator->sometimes(['reason', 'cost'], 'required', function (Fluent $input) {
        return $input->games >= 100;
    });

> [!NOTE]  
> The `$input` parameter passed to your closure will be an instance of `Illuminate\Support\Fluent` and may be used to access your input and files under validation.

<a name="complex-conditional-array-validation"></a>
#### Complex Conditional Array Validation

Sometimes you may want to validate a field based on another field in the same nested array whose index you do not know. In these situations, you may allow your closure to receive a second argument which will be the current individual item in the array being validated:

    $input = [
        'channels' => [
            [
                'type' => 'email',
                'address' => 'abigail@example.com',
            ],
            [
                'type' => 'url',
                'address' => 'https://example.com',
            ],
        ],
    ];

    $validator->sometimes('channels.*.address', 'email', function (Fluent $input, Fluent $item) {
        return $item->type === 'email';
    });

    $validator->sometimes('channels.*.address', 'url', function (Fluent $input, Fluent $item) {
        return $item->type !== 'email';
    });

Like the `$input` parameter passed to the closure, the `$item` parameter is an instance of `Illuminate\Support\Fluent` when the attribute data is an array; otherwise, it is a string.

<a name="validating-arrays"></a>
## Validating Arrays

As discussed in the [`array` validation rule documentation](#rule-array), the `array` rule accepts a list of allowed array keys. If any additional keys are present within the array, validation will fail:

    use Illuminate\Support\Facades\Validator;

    $input = [
        'user' => [
            'name' => 'Taylor Otwell',
            'username' => 'taylorotwell',
            'admin' => true,
        ],
    ];

    Validator::make($input, [
        'user' => 'array:name,username',
    ]);

In general, you should always specify the array keys that are allowed to be present within your array. Otherwise, the validator's `validate` and `validated` methods will return all of the validated data, including the array and all of its keys, even if those keys were not validated by other nested array validation rules.

<a name="validating-nested-array-input"></a>
### Validating Nested Array Input

Validating nested array based form input fields doesn't have to be a pain. You may use "dot notation" to validate attributes within an array. For example, if the incoming HTTP request contains a `photos[profile]` field, you may validate it like so:

    use Illuminate\Support\Facades\Validator;

    $validator = Validator::make($request->all(), [
        'photos.profile' => 'required|image',
    ]);

You may also validate each element of an array. For example, to validate that each email in a given array input field is unique, you may do the following:

    $validator = Validator::make($request->all(), [
        'person.*.email' => 'email|unique:users',
        'person.*.first_name' => 'required_with:person.*.last_name',
    ]);

Likewise, you may use the `*` character when specifying [custom validation messages in your language files](#custom-messages-for-specific-attributes), making it a breeze to use a single validation message for array based fields:

    'custom' => [
        'person.*.email' => [
            'unique' => 'Each person must have a unique email address',
        ]
    ],

<a name="accessing-nested-array-data"></a>
#### Accessing Nested Array Data

Sometimes you may need to access the value for a given nested array element when assigning validation rules to the attribute. You may accomplish this using the `Rule::forEach` method. The `forEach` method accepts a closure that will be invoked for each iteration of the array attribute under validation and will receive the attribute's value and explicit, fully-expanded attribute name. The closure should return an array of rules to assign to the array element:

    use App\Rules\HasPermission;
    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    $validator = Validator::make($request->all(), [
        'companies.*.id' => Rule::forEach(function (string|null $value, string $attribute) {
            return [
                Rule::exists(Company::class, 'id'),
                new HasPermission('manage-company', $value),
            ];
        }),
    ]);

<a name="error-message-indexes-and-positions"></a>
### Error Message Indexes and Positions

When validating arrays, you may want to reference the index or position of a particular item that failed validation within the error message displayed by your application. To accomplish this, you may include the `:index` (starts from `0`) and `:position` (starts from `1`) placeholders within your [custom validation message](#manual-customizing-the-error-messages):

    use Illuminate\Support\Facades\Validator;

    $input = [
        'photos' => [
            [
                'name' => 'BeachVacation.jpg',
                'description' => 'A photo of my beach vacation!',
            ],
            [
                'name' => 'GrandCanyon.jpg',
                'description' => '',
            ],
        ],
    ];

    Validator::validate($input, [
        'photos.*.description' => 'required',
    ], [
        'photos.*.description.required' => 'Please describe photo #:position.',
    ]);

Given the example above, validation will fail and the user will be presented with the following error of _"Please describe photo #2."_

If necessary, you may reference more deeply nested indexes and positions via `second-index`, `second-position`, `third-index`, `third-position`, etc.

    'photos.*.attributes.*.string' => 'Invalid attribute for photo #:second-position.',

<a name="validating-files"></a>
## Validating Files

Laravel provides a variety of validation rules that may be used to validate uploaded files, such as `mimes`, `image`, `min`, and `max`. While you are free to specify these rules individually when validating files, Laravel also offers a fluent file validation rule builder that you may find convenient:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rules\File;

    Validator::validate($input, [
        'attachment' => [
            'required',
            File::types(['mp3', 'wav'])
                ->min(1024)
                ->max(12 * 1024),
        ],
    ]);

If your application accepts images uploaded by your users, you may use the `File` rule's `image` constructor method to indicate that the uploaded file should be an image. In addition, the `dimensions` rule may be used to limit the dimensions of the image:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;
    use Illuminate\Validation\Rules\File;

    Validator::validate($input, [
        'photo' => [
            'required',
            File::image()
                ->min(1024)
                ->max(12 * 1024)
                ->dimensions(Rule::dimensions()->maxWidth(1000)->maxHeight(500)),
        ],
    ]);

> [!NOTE]  
> More information regarding validating image dimensions may be found in the [dimension rule documentation](#rule-dimensions).

<a name="validating-files-file-sizes"></a>
#### File Sizes

For convenience, minimum and maximum file sizes may be specified as a string with a suffix indicating the file size units. The `kb`, `mb`, `gb`, and `tb` suffixes are supported:

```php
File::image()
    ->min('1kb')
    ->max('10mb')
```

<a name="validating-files-file-types"></a>
#### File Types

Even though you only need to specify the extensions when invoking the `types` method, this method actually validates the MIME type of the file by reading the file's contents and guessing its MIME type. A full listing of MIME types and their corresponding extensions may be found at the following location:

[https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types](https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types)

<a name="validating-passwords"></a>
## Validating Passwords

To ensure that passwords have an adequate level of complexity, you may use Laravel's `Password` rule object:

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rules\Password;

    $validator = Validator::make($request->all(), [
        'password' => ['required', 'confirmed', Password::min(8)],
    ]);

The `Password` rule object allows you to easily customize the password complexity requirements for your application, such as specifying that passwords require at least one letter, number, symbol, or characters with mixed casing:

    // Require at least 8 characters...
    Password::min(8)

    // Require at least one letter...
    Password::min(8)->letters()

    // Require at least one uppercase and one lowercase letter...
    Password::min(8)->mixedCase()

    // Require at least one number...
    Password::min(8)->numbers()

    // Require at least one symbol...
    Password::min(8)->symbols()

In addition, you may ensure that a password has not been compromised in a public password data breach leak using the `uncompromised` method:

    Password::min(8)->uncompromised()

Internally, the `Password` rule object uses the [k-Anonymity](https://en.wikipedia.org/wiki/K-anonymity) model to determine if a password has been leaked via the [haveibeenpwned.com](https://haveibeenpwned.com) service without sacrificing the user's privacy or security.

By default, if a password appears at least once in a data leak, it will be considered compromised. You can customize this threshold using the first argument of the `uncompromised` method:

    // Ensure the password appears less than 3 times in the same data leak...
    Password::min(8)->uncompromised(3);

Of course, you may chain all the methods in the examples above:

    Password::min(8)
        ->letters()
        ->mixedCase()
        ->numbers()
        ->symbols()
        ->uncompromised()

<a name="defining-default-password-rules"></a>
#### Defining Default Password Rules

You may find it convenient to specify the default validation rules for passwords in a single location of your application. You can easily accomplish this using the `Password::defaults` method, which accepts a closure. The closure given to the `defaults` method should return the default configuration of the Password rule. Typically, the `defaults` rule should be called within the `boot` method of one of your application's service providers:

```php
use Illuminate\Validation\Rules\Password;

/**
 * Bootstrap any application services.
 */
public function boot(): void
{
    Password::defaults(function () {
        $rule = Password::min(8);

        return $this->app->isProduction()
                    ? $rule->mixedCase()->uncompromised()
                    : $rule;
    });
}
```

Then, when you would like to apply the default rules to a particular password undergoing validation, you may invoke the `defaults` method with no arguments:

    'password' => ['required', Password::defaults()],

Occasionally, you may want to attach additional validation rules to your default password validation rules. You may use the `rules` method to accomplish this:

    use App\Rules\ZxcvbnRule;

    Password::defaults(function () {
        $rule = Password::min(8)->rules([new ZxcvbnRule]);

        // ...
    });

<a name="custom-validation-rules"></a>
## Custom Validation Rules

<a name="using-rule-objects"></a>
### Using Rule Objects

Laravel provides a variety of helpful validation rules; however, you may wish to specify some of your own. One method of registering custom validation rules is using rule objects. To generate a new rule object, you may use the `make:rule` Artisan command. Let's use this command to generate a rule that verifies a string is uppercase. Laravel will place the new rule in the `app/Rules` directory. If this directory does not exist, Laravel will create it when you execute the Artisan command to create your rule:

```shell
php artisan make:rule Uppercase
```

Once the rule has been created, we are ready to define its behavior. A rule object contains a single method: `validate`. This method receives the attribute name, its value, and a callback that should be invoked on failure with the validation error message:

    <?php

    namespace App\Rules;

    use Closure;
    use Illuminate\Contracts\Validation\ValidationRule;

    class Uppercase implements ValidationRule
    {
        /**
         * Run the validation rule.
         */
        public function validate(string $attribute, mixed $value, Closure $fail): void
        {
            if (strtoupper($value) !== $value) {
                $fail('The :attribute must be uppercase.');
            }
        }
    }

Once the rule has been defined, you may attach it to a validator by passing an instance of the rule object with your other validation rules:

    use App\Rules\Uppercase;

    $request->validate([
        'name' => ['required', 'string', new Uppercase],
    ]);

#### Translating Validation Messages

Instead of providing a literal error message to the `$fail` closure, you may also provide a [translation string key](/docs/{{version}}/localization) and instruct Laravel to translate the error message:

    if (strtoupper($value) !== $value) {
        $fail('validation.uppercase')->translate();
    }

If necessary, you may provide placeholder replacements and the preferred language as the first and second arguments to the `translate` method:

    $fail('validation.location')->translate([
        'value' => $this->value,
    ], 'fr')

#### Accessing Additional Data

If your custom validation rule class needs to access all of the other data undergoing validation, your rule class may implement the `Illuminate\Contracts\Validation\DataAwareRule` interface. This interface requires your class to define a `setData` method. This method will automatically be invoked by Laravel (before validation proceeds) with all of the data under validation:

    <?php

    namespace App\Rules;

    use Illuminate\Contracts\Validation\DataAwareRule;
    use Illuminate\Contracts\Validation\ValidationRule;

    class Uppercase implements DataAwareRule, ValidationRule
    {
        /**
         * All of the data under validation.
         *
         * @var array<string, mixed>
         */
        protected $data = [];

        // ...

        /**
         * Set the data under validation.
         *
         * @param  array<string, mixed>  $data
         */
        public function setData(array $data): static
        {
            $this->data = $data;

            return $this;
        }
    }

Or, if your validation rule requires access to the validator instance performing the validation, you may implement the `ValidatorAwareRule` interface:

    <?php

    namespace App\Rules;

    use Illuminate\Contracts\Validation\ValidationRule;
    use Illuminate\Contracts\Validation\ValidatorAwareRule;
    use Illuminate\Validation\Validator;

    class Uppercase implements ValidationRule, ValidatorAwareRule
    {
        /**
         * The validator instance.
         *
         * @var \Illuminate\Validation\Validator
         */
        protected $validator;

        // ...

        /**
         * Set the current validator.
         */
        public function setValidator(Validator $validator): static
        {
            $this->validator = $validator;

            return $this;
        }
    }

<a name="using-closures"></a>
### Using Closures

If you only need the functionality of a custom rule once throughout your application, you may use a closure instead of a rule object. The closure receives the attribute's name, the attribute's value, and a `$fail` callback that should be called if validation fails:

    use Illuminate\Support\Facades\Validator;
    use Closure;

    $validator = Validator::make($request->all(), [
        'title' => [
            'required',
            'max:255',
            function (string $attribute, mixed $value, Closure $fail) {
                if ($value === 'foo') {
                    $fail("The {$attribute} is invalid.");
                }
            },
        ],
    ]);

<a name="implicit-rules"></a>
### Implicit Rules

By default, when an attribute being validated is not present or contains an empty string, normal validation rules, including custom rules, are not run. For example, the [`unique`](#rule-unique) rule will not be run against an empty string:

    use Illuminate\Support\Facades\Validator;

    $rules = ['name' => 'unique:users,name'];

    $input = ['name' => ''];

    Validator::make($input, $rules)->passes(); // true

For a custom rule to run even when an attribute is empty, the rule must imply that the attribute is required. To quickly generate a new implicit rule object, you may use the `make:rule` Artisan command with the `--implicit` option:

```shell
php artisan make:rule Uppercase --implicit
```

> [!WARNING]  
> An "implicit" rule only _implies_ that the attribute is required. Whether it actually invalidates a missing or empty attribute is up to you.


