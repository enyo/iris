---
layout: default
---

# Remote Services

> The remote services library is a complete abstraction of client ↔ server
> communication.  
> It is basically a
> [remote procedure call](http://en.wikipedia.org/wiki/Remote_procedure_call)
> implementation in *dart*.

[Hosted on GitHub](https://github.com/enyo/remote-services)

## Introduction

When you're building web applications you nearly always have different parts of
your application communicating with one another (for example: the browser
requesting data from the server via AJAX).

Most commonly this communication is done by creating an HTTP server, defining an
API and sending JSON data.

There are multiple things wrong with this approach:

1. You need to think of your API *very carefully*. Changing your URL from
    `/user/create` to `/users/create` will break all clients **without them even
    knowing** until they experience the error.
2. The same goes for your JSON data. Consumers of your API will need to look at
    your documentation to know exactly what data will be submitted, and if you
    change something they will never know. A simple typo like `isDeleted` instead
    of `is_deleted` can potentially result in a broken app and it's very hard to
    find that error.
3. *Every client and server* needs to implement the communication (writing the AJAX call,
    handling errors, etc...).

> The *Remote Services library* solves all those problems.


## Dart

*Stop using JavaScript!* Don't get me wrong: I like JavaScript. I wrote two very
well known libraries ([dropzone](http://www.dropzonejs.com/) and
[opentip](http://www.opentip.org/)), a few lesser known libraries
([mongo-rest](https://github.com/enyo/mongo-rest) and
[node-tvdb](https://github.com/enyo/node-tvdb)) and countless servers and client
libraries for personal and professional use.

But when you work on bigger projects, where stability is an issue and when you
start working with bigger teams, using a language without types is just
incredibly painful! If you don't know a library well, you need to check the
documentation all the time (if there is one up to date), and spotting errors can
be very difficult.

So don't waste any more time and *check out dart*. Once you've started working
with it for a while, you really start to wonder how you were able to put up with
JavaScript when you have to work on some JS code again. Just clicking on a function
name and getting the declaration, having the dart editor tell you the second you
type a function name what parameters it accepts is just incredibly crucial to a
productive and stable workflow.

## Protocol buffers

Instead of using JSON, which is basically just a Map without any type or
structure information whatsoever, the *remote services* library uses
[protocol buffers](http://en.wikipedia.org/wiki/Protocol_Buffers).

Whenever you define a procedure, you specify what protocol buffer message you
are sending back, and which one you want to receive. The *remote services library*
automatically checks the type, makes sure that the message is well formatted, and
gives you a *dart* object of the proper type.

## Communication

All communication is handled by the *remote services library*. You don't ever
need to think about how the data is being transferred. All you need to think
about is: what message do I send to the remote service, and what message do I
want to get back.


## Error handling

The *remote services library* completely takes care of error handling for you.

Errors are sent using error codes that you define on your server. All clients
get access to that error codes and can handle errors appropriately.


## How does it work?

You write your services (classes that contain your *procedures*) on the server,
provide it to the library.

The library then does two things for you:

1. It generates the files for the client
2. It starts a server for you that listens for requests from the client

This is an example of a generated service class for the client:

<script src="https://gist.github.com/enyo/2a162ef9cf43ab042725.js"></script>

As you can see, it contains the generated path for the resources, and the request
as well as the return types for requests.

For a complete explanation and reference, please see the
[remote services README](https://github.com/enyo/remote-services/blob/master/README.md).
