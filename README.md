# Remote services

[![Build Status](https://drone.io/github.com/enyo/remote-services/status.png)](https://drone.io/github.com/enyo/remote-services/latest)

A complete abstraction of client ↔ server communication.

It is basically a [remote procedure call](http://en.wikipedia.org/wiki/Remote_procedure_call)
implementation in dart. You can call the methods on your services and get the
result back in futures without having to think about the communication.

## Usage


You can look at the [example repository](https://github.com/enyo/remote-services-example)
for an implementation.

The typical setup is as follows:


1. [Setup your server to generate protocol buffer messages](#setup-protocol-buffers)
2. [Write your services & procedures](#write-services-on-server) that handle the
   requests.
3. [Create the service definitions](#create-service-definitions) that group your
   services together and setup a server.
4. [Create a server binary](#create-a-server-binary) which you can then execute
   to start your remote server.
5. [Setup the build.dart file](#setup-builddart) to generate the client library.
6. [Use the library on the client](#on-the-client)

As you go along you will need more control over your configuration:

- [Use error codes](#error-codes) to tell the client what went wrong.
- [Write a context initializer](#context-initializers) to add additional
  information (eg: session information) to the `Context` received by *filters*
  and *procedures*.
- [Write filters for your services and procedures](#filters) to reject requests
  on certain conditions (eg: **authentication**).
- [Release the generated files as standalone library](#standalone-library)

### Setup protocol buffers

[Protocol buffers](http://en.wikipedia.org/wiki/Protocol_Buffers) are a method
of serializing structured data. They are fast and performant, developed and
used by *Google*, and are a great way to define the data being passed between
services (in contrast to JSON where you have to take care of validating the data
yourself, and always need to look at the documentation to see what you actually
receive).

The way they work in dart is: you define your messages in `.proto` files and a
library converts them to `dart` classes (subclasses of `GeneratedMessage`) which
are typed and allow for auto completion and type checking.

Whenever a message in `remote_services` is sent or received, it is an instance
of `GeneratedMessage`.


### Write services on server

Services basically are bundles of `Procedures`. If you have a service class
named `UserService` with a *procedure* (a method on this class, with the
`Procedure` annotation) named `create`, then you will be able to call this
remote procedure from the client with `userService.create()`.

Every *procedure* receives a `Context` as first parameter and *can* accept a
`GeneratedMessage` (protocol buffer message) as a second parameter.  
The `Context` contains basic request information (like cookies). If you want to
add additional information to the `Context` object, see the
[context initializers](#context-initializers) section.


This is a simple *service* example:

```dart
class UserService extends Service {

  /**
   * This procedure has both, a return type ([CreateUserResponse]) and an
   * expected request message ([CreateUserRequest]).
   */
  @Procedure()
  Future<CreateUserResponse> create(Context context, CreateUserRequest request) {
    // Create the user, and return a CreateUserResponse
  }

  /**
   * This procedure has no return type, so `remote_services` will assume that
   * nothing will be sent back to the client. It will just await the execution.
   */
  @Procedure()
  Future delete(Context context, DeleteUserRequest request) {
      // Delete the user, and return a resolved Future
  }

  /**
   * This is an example procedure that receives and returns no message.
   */
  @Procedure()
  Future ping(Context context) => new Future.value();

}
```

As you can see, procedures can either accept and return `GeneratedMessage`s or
not. `remote_services` understands this, and builds your client library
accordingly so you have proper auto completion when writing your client library.


### Create service definitions

In a separate file you create a `getServiceDefinitions()` function that returns
a `ServiceDefinitions` object. This object will be used to start the server, and
to build the files for the client.

Example `lib/service_definitions.dart`:

```dart
library service_definitions;

import "package:remote_services/remote/remote_services.dart";

// This is the file that contains all your services
import "services/services.dart";

ServiceDefinitions getServices() {
  return new ServiceDefinitions()
        // Add the services you want to be served
        ..addService(new UserService())
        ..addService(new AuthenticationService())
        // Add the servers you want to use
        ..addServer(new HttpServiceServer("localhost", 8088, allowOrigin: "http://127.0.0.1:3030"));
}
```

### Create a server binary

To actually start the remote server which will listen on incoming connections,
you simply include those `ServiceDefinitions` and call `.startServers()` on it.

Example `bin/start_server.dart`:

```dart
import "../lib/service_definitions.dart";

main() {
  // Starts all servers that have been added with `.addServer()`.
  getServiceDefinitions().startServers();
}
```


### Setup build.dart

Now everything on your server is ready! The services are served automatically
and are listening for incoming requests.

To use this remote services on the client, `remote_services` generates a library
to be used on the client. This allows you to have completely typed classes that
you can use, with autocompletion and request / return types.

To let `remote_services` build your client libraries, you need to edit your
`build.dart` and add this build command:

```dart
library build;

import 'package:remote_services/builder/builder.dart' as remote_services;

import "lib/service_definitions.dart";


const RS_TARGET = "lib/client_services";

const RS_PROTO_BUFFER_MESSAGES = "lib/proto/messages.dart";

const RS_SERVICES_DIR = "lib/services/";

void main(List<String> args) {

  remote_services.build(getServices(), RS_TARGET, RS_PROTO_BUFFER_MESSAGES, args: args, includePbMessages: true, servicesDirectory: RS_SERVICES_DIR);

}
```

See the [standalone library](#standalone-library) section for more information
on how to setup your `build.dart` file to create a standalone library that can
be distributed separately.

### On the client

`remote_services` provides two types of client libraries: one is meant to be
used on a server, and one for the browser.

Here's an example of using the remote services in a browser:

```dart
import "package:remote_services/client/browser_http_client.dart";

// This includes your generated library
import "package:my-generated-remote-services/services.dart";

main() {
  var client = new HttpServiceClient(Uri.parse("http://localhost:8088"));

  // Create an instance of your services
  var services = new Services(client);

  // And you're good to go!

  AuthenticationRequest req = new AuthenticationRequest()
      ..email = "e@mail.com"
      ..password = "password";

  services.userService.auth(req).then((User user) => doSomething(user));

}
```

## Advanced configuration

### Error codes

If an error occurs anywhere in a remote service request you **always** get a
`ServiceClientException`. This `ServiceClientException` has an `errorCode` and
an `internalMessage`.

> **Never show the `internalMessage` to the user!** It is only meant to be logged
> or inspected by developers.

`errorCode`s are all you need to tell the client what's wrong. Every time you
encounter a problem in your service, think about what you want to tell the client
and create an error code for it.

This is how you setup error codes on the server:

```dart
class ErrorCode extends RemoteServicesErrorCode {

  static const INVALID_USERNAME_OR_PASSWORD = const ErrorCode._(0);

  static const INVALID_EMAIL = const ErrorCode._(1);

  const ErrorCode._(int value) : super(value);

}
```

and this is how you would throw an error code in a *procedure*:

```dart
class UserService extends Service {

  @Procedure()
  Future create(MyContext context) {
    throw new ProcedureException(ErrorCode.INVALID_EMAIL, "Oh noes.");
  }

}
```

on your client:

```dart
services.userService.create().then(print)
    .catchError((ServiceClientException ex) {
      if (ex.errorCode == ErrorCode.INVALID_EMAIL) {
        alert("Please provide a valid email address");
      }
      log.info(ex.internalMessage);
    });
```

There are several *internal* error codes that you can receive on the client as
well. Look at the `RemoteServicesErrorCode` class to see what they are.

> If you provide this `ErrorCode` class to the `build` function of the builder,
> an `error_code.dart` file is generated, containing all error codes as integers
> to be used on the client.


### Context initializers

Every *procedure* and *procedure filter* receives a `Context` object that gets
instantiated for every request. If you don't define a `ContextInitializer`
yourself, you will always receive the default `Context` implementation, which
only holds the `ServiceRequest` object.

If you want to have additional information in you context (like session data),
you can define your own context class and provide a `ContextInitializer` to
create that object for you.

> `ContextInitializers` are the first thing called when a request comes in.
> After that all filters are called sequentially, and then your procedure with
> the initialized `Context`.

This is the `typedef` for `ContextInitializer`s:

```dart
typedef Future<Context> ContextInitializer(ServiceRequest req);
```

and here an example implementation:

```dart
/**
 * Your own `Context` class
 */
class MyContext extends Context {

  /// An additional field in your context to hold the session information.
  final Session session;

  MyContext(ServiceRequest req, this.session) : super(req);
}

/**
 * Now define your context initializer
 */
Future<MyContext> myContextInitializer(ServiceRequest req) {
  // This can do anything needed for context initialization. Example:

  // Load session info from the memory cache
  myMemoryCache.loadSession(req.cookies["sessionId"])
      .then((Session session) {
        // And return your context, *with* a session
        return new MyContext(req, session);
      })

}


ServiceDefinitions getServiceDefinitions() {
  // And where you create you service definitions, you now pass the context
  // initializer
  return new ServiceDefinitions(myContextInitializer)
      ..addService(UserService)
      ..etc...
}
```

So, every time you receive a `Context` object, it is now a `MyContext` instance.



### Filters

Often you need your procedures to be filtered, for example if you need authentication.

Filters are defined with the `Service` or the `Procedure` annotation and this is
their `typedef`:

```dart
typedef Future<bool> FilterFunction(Context context);
```

You can define filters in your service like this:


```dart
Future<bool> authenticationFilter(Context context) {
  // Make sure the user is authenticated.
  return new Future.value(true);
}

Future<bool> adminRightsFilter(Context context) {
  // Make sure the user has admin rights
  return new Future.value(true);
}


/// All procedures in this service will have the `authenticationFilter`.
@Service(filters: const [authenticationFilter])
class UserService extends Service {

  /// In addition to the `authenticationFilter` this procedure also has the
  /// `adminRightsFilter`.
  @Procedure(filters: const [adminRightsFilter])
  Future<CreateUserResponse> create(Context context, CreateUserRequest request) => new Future.value();

}
```

If a filter returns `false`, the procedure will *not* be called, and an error
will be sent to the client.

> After the `ContextInitializer` function, all defined filters will be called
> **sequentially and in the defined order** and processing the request is
> immediately stopped when one filter returns `false`.  
> **Service filters are always the first filters to run.**

If you have set a `ContextInitializer` all filter functions will receive the
context returned by this function.

### Standalone library

There are two ways you can distribute your remote services:

1. As part of your server library
2. As a separate, standalone library

Releasing the remote services as part of your library is easier. You can just
let the build script create the necessary client files in your `lib/` directory,
and users can use your server as a dependency, and import the generated *remote
service* files. This means that the user has access to your protocol buffer and
`ErrorCode` files (since they are already in your server library).

The disadvantage of this approach is, of course, that your whole server needs to
be exposed. This is fine if your library is only used internally (since you can
have a dependency on a private repository), but if you want to distribute the
generated client library to other users this won't be working anymore.

This is why `remote_services` has the ability to include all necessary resources
in the generated library so it can be shipped as a separate library, namely:

- All protocol buffer messages
- The error codes.

When invoking the `build` function of the builder, you can additionally pass
the `ErrorCode` class with the `errorCodes` parameter. `remote_services` will
then generate a `error_code.dart` file with an `ErrorCode` class that contains
*all* error codes.

If you set the `includePbMessages` option to `true`, `remote_services` will also
copy over all protocol buffer messages, and put them in the `proto/` folder.

With the `targetDirectory` argument (the second positional argument), you can
define a directory *outside* your server directory, which is the library that
you can ship without having to worry about leaking sensitive code.




# License

(The MIT License)

Copyright (c) 2014 Matias Meno &lt;m@tias.me&gt;<br>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
