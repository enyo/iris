# Iris

[![Build Status](https://drone.io/github.com/enyo/iris/status.png)](https://drone.io/github.com/enyo/iris/latest)

A complete abstraction of client ↔ server communication.

It is basically a [remote procedure call](http://en.wikipedia.org/wiki/Remote_procedure_call)
implementation in dart. You can call the methods on your remotes and get the
result back in futures without having to think about the communication.

## Usage


You can look at the [example repository](https://github.com/enyo/iris-example)
for an implementation.

The typical setup is as follows:


1. [Setup your server to generate protocol buffer messages](#setup-protocol-buffers)
2. [Write your procedures](#write-procedures-on-server) that handle the
   requests.
3. [Create an iris object](#create-an-iris-object) that group your
   remotes together and setup a server.
4. [Create a server binary](#create-a-server-binary) which you can then execute
   to start your iris server.
5. [Setup the build.dart file](#setup-builddart) to generate the client library.
6. [Use the library on the client](#on-the-client)

As you go along you will need more control over your configuration:

- [Use error codes](#error-codes) to tell the client what went wrong.
- [Write a context initializer](#context-initializers) to add additional
  information (eg: session information) to the `Context` received by *filters*
  and *procedures*.
- [Write filters for your remotes and procedures](#filters) to reject requests
  on certain conditions (eg: **authentication**).
- [Release the generated files as standalone library](#standalone-library)

### Setup protocol buffers

[Protocol buffers](http://en.wikipedia.org/wiki/Protocol_Buffers) are a method
of serializing structured data. They are fast and performant, developed and
used by *Google*, and are a great way to define the data being passed between
remotes (in contrast to JSON where you have to take care of validating the data
yourself, and always need to look at the documentation to see what you actually
receive).

The way they work in dart is: you define your messages in `.proto` files and a
library converts them to `dart` classes (subclasses of `GeneratedMessage`) which
are typed and allow for auto completion and type checking.

Whenever a message in `iris` is sent or received, it is an instance
of `GeneratedMessage`.


### Write procedures on server

Remotes basically are bundles of `Procedures`. If you have a remote class
named `RemoteUser` with a *procedure* (a method on this class, with the
`Procedure` annotation) named `create`, then you will be able to call this
remote procedure from the client with `remoteUser.create()`.

Every *procedure* receives a `Context` as first parameter and *can* accept a
`GeneratedMessage` (protocol buffer message) as a second parameter.  
The `Context` contains basic request information (like cookies). If you want to
add additional information to the `Context` object, see the
[context initializers](#context-initializers) section.


This is a simple *remote* example:

```dart
class RemoteUser extends Remote {

  /**
   * This procedure has both, a return type ([CreateUserResponse]) and an
   * expected request message ([CreateUserRequest]).
   */
  @Procedure()
  Future<CreateUserResponse> create(Context context, CreateUserRequest request) {
    // Create the user, and return a CreateUserResponse
  }

  /**
   * This procedure has no return type, so `iris` will assume that  nothing will
   * be sent back to the client. It will just await the execution.
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
not. `Iris` understands this, and builds your client library
accordingly so you have proper auto completion when writing your client library.


### Create an iris object

In a separate file you create a function that returns an `Iris` object. This
object will be used to start the server, and to build the files for the client.

Example `lib/iris.dart`:

```dart
library remote_definitions;

import "package:iris/remote/iris.dart";

// This is the file that contains all your remotes
import "remotes/remotes.dart";

Iris getIris() {
  return new Iris()
        // Add the remotes you want to be served
        ..addRemote(new RemoteUser())
        ..addRemote(new RemoteAuthentication())
        // Add the servers you want to use
        ..addServer(new HttpIrisServer("localhost", 8088, allowOrigins: const ['http://127.0.0.1:3030']));
}
```

### Create a server binary

To actually start the iris server which will listen on incoming connections,
you simply include `Iris` and call `.startServers()` on it.

Example `bin/start_server.dart`:

```dart
import "../lib/iris.dart";

main() {
  // Starts all servers that have been added with `.addServer()`.
  getIris().startServers();
}
```


### Setup build.dart

Now everything on your server is ready! The remotes are served automatically
and are listening for incoming requests.

To use these remotes on the client, `iris` generates a library
to be used on the client. This allows you to have completely typed classes that
you can use, with autocompletion and request / return types.

To let `iris` build your client libraries, you need to edit your
`build.dart` and add this build command:

```dart
library build;

import 'package:iris/builder/builder.dart' as iris_builder;

import "lib/iris.dart";


const IRIS_TARGET = "lib/client_remotes";

const IRIS_PROTO_BUFFER_MESSAGES = "lib/proto/messages.dart";

const IRIS_REMOTES_DIR = "lib/remotes/";

void main(List<String> args) {

  iris_builder.build(getIris(), IRIS_TARGET, IRIS_PROTO_BUFFER_MESSAGES, args: args, includePbMessages: true, remotesDirectory: IRIS_REMOTES_DIR);

}
```

The builder will now rebuild your client library every time either your protocol
buffer messages or your remotes (only if you specify `remotesDirectory`) change.

See the [standalone library](#standalone-library) section for more information
on how to setup your `build.dart` file to create a standalone library that can
be distributed separately.

### On the client

`Iris` provides two types of client libraries: one is meant to be
used on a server, and one for the browser.

Here's an example of using the remotes in a browser:

```dart
import "package:iris/client/browser_http_client.dart";

// This includes your generated library
import "package:my-generated-lib/remotes.dart";

main() {
  var client = new HttpIrisClient(Uri.parse("http://localhost:8088"));

  // Create an instance of your remotes
  var remotes = new Remotes(client);

  // And you're good to go!

  AuthenticationRequest req = new AuthenticationRequest()
      ..email = "e@mail.com"
      ..password = "password";

  remotes.remoteUser.auth(req).then((User user) => doSomething(user));

}
```

## Advanced configuration

### Error codes

If an error occurs anywhere in a remote request you **always**
get an `IrisException` on the client. This `IrisException` has an
`errorCode` and an `internalMessage`.

> **Never show the `internalMessage` to the user!** It is only meant to be logged
> or inspected by developers.

`errorCode`s are all you need to tell the client what's wrong. Every time you
encounter a problem in your remote, think about what you want to tell the client
and create an error code for it.

This is how you setup error codes on the server:

```dart
class ErrorCode extends IrisErrorCode {

  static const INVALID_USERNAME_OR_PASSWORD = const ErrorCode._(0);

  static const INVALID_EMAIL = const ErrorCode._(1);

  const ErrorCode._(int value) : super(value);

}
```

and this is how you would throw an error code in a *procedure*:

```dart
class RemoteUser extends Remote {

  @Procedure()
  Future create(MyContext context) {
    throw new ProcedureException(ErrorCode.INVALID_EMAIL, "Oh noes.");
  }

}
```

on your client:

```dart
remotes.remoteUser.create().then(print)
    .catchError((IrisException ex) {
      if (ex.errorCode == ErrorCode.INVALID_EMAIL) {
        alert("Please provide a valid email address");
      }
      log.info(ex.internalMessage);
    });
```

There are several *internal* error codes that you can receive on the client as
well. Look at the `IrisErrorCode` class to see what they are.

> If you provide this `ErrorCode` class to the `build` function of the builder,
> an `error_code.dart` file is generated, containing all error codes as integers
> to be used on the client.


### Context initializers

Every *procedure* and *procedure filter* receives a `Context` object that gets
instantiated for every request. If you don't define a `ContextInitializer`
yourself, you will always receive the default `Context` implementation, which
only holds the `IrisRequest` object.

If you want to have additional information in you context (like session data),
you can define your own context class and provide a `ContextInitializer` to
create that object for you.

> `ContextInitializer`s are the first thing called when a request comes in.
> After that all filters are called sequentially, and then your procedure with
> the initialized `Context`.

This is the `typedef` for `ContextInitializer`s:

```dart
typedef Future<Context> ContextInitializer(IrisRequest req);
```

and here an example implementation:

```dart
/**
 * Your own `Context` class
 */
class MyContext extends Context {

  /// An additional field in your context to hold the session information.
  final Session session;

  MyContext(IrisRequest req, this.session) : super(req);
}

/**
 * Now define your context initializer
 */
Future<MyContext> myContextInitializer(IrisRequest req) {
  // This can do anything needed for context initialization. Example:

  // Load session info from the memory cache
  myMemoryCache.loadSession(req.cookies["sessionId"])
      .then((Session session) {
        // And return your context, *with* a session
        return new MyContext(req, session);
      })

}


Iris getIris() {
  // And where you create you remote definitions, you now pass the context
  // initializer
  return new Iris(myContextInitializer)
      ..addRemote(RemoteUser)
      ..etc...
}
```

So, every time you receive a `Context` object, it is now a `MyContext` instance.



### Filters

Often you need your procedures to be filtered, for example if you need authentication.

Filters are defined with the `Remote` or the `Procedure` annotation and this is
their `typedef`:

```dart
typedef Future<bool> FilterFunction(Context context);
```

You can define filters in your remote like this:


```dart
Future<bool> authenticationFilter(Context context) {
  // Make sure the user is authenticated.
  return new Future.value(true);
}

Future<bool> adminRightsFilter(Context context) {
  // Make sure the user has admin rights
  return new Future.value(true);
}


/// All procedures in this remote will have the `authenticationFilter`.
@Remote(filters: const [authenticationFilter])
class RemoteUser extends Remote {

  /// In addition to the `authenticationFilter` this procedure also has the
  /// `adminRightsFilter`.
  @Procedure(filters: const [adminRightsFilter])
  Future<CreateUserResponse> create(Context context, CreateUserRequest request) => new Future.value();

}
```

If a filter returns `false`, the procedure will *not* be called, and an error
will be sent to the client. If you want the client to receive a specific error
code, then you can use the `ProcedureException` for that.

> After the `ContextInitializer` function, all defined filters will be called
> **sequentially and in the defined order** and processing the request is
> immediately stopped when one filter returns `false`.  
> **Remote filters are always the first filters to run.**

If you have set a `ContextInitializer` all filter functions will receive the
context returned by this function.

### Standalone library

There are two ways you can distribute your remote remotes:

1. As part of your server library
2. As a separate, standalone library

Releasing the remotes as part of your library is easier. You can just
let the build script create the necessary client files in your `lib/` directory,
and users can use your server as a dependency, and import the generated *iris*
files. This means that the user has access to your protocol buffer and
`ErrorCode` files (since they are already in your server library).

The disadvantage of this approach is, of course, that your whole server needs to
be exposed. This is fine if your library is only used internally (since you can
have a dependency on a private repository), but if you want to distribute the
generated client library to other users this won't be working anymore.

This is why `iris` has the ability to include all necessary resources
in the generated library so it can be shipped as a separate library, namely:

- All protocol buffer messages
- The error codes

When invoking the `build` function of the builder, you can additionally pass
the `ErrorCode` class with the `errorCodes` parameter. `Iris` will
then generate a `error_code.dart` file with an `ErrorCode` class that contains
*all* error codes.

If you set the `includePbMessages` option to `true`, `iris` will also
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
