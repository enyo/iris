# Remote services

[![Build Status](https://drone.io/github.com/enyo/remote-services/status.png)](https://drone.io/github.com/enyo/remote-services/latest)

A complete abstraction of client <-> server communication


## Usage


### On the server

Define your services:

```dart
Future<bool> authenticationFilter(Context context) {
  // Make sure the user is authenticated.
}

@service
class UserService extends Service {
  
  @Route(filters: [authenticationFilter])
  Future<CreateUserResponse> create(Context context, CreateUserRequest request) {
  
  }

}

RemoteServices getServices() {
  return new RemoteServices()
      ..addService(UserService)
      ..addService(AccountService)
      ..addServer(new HttpServiceServer())
      ..addServer(new SocketServiceServer());
}
```

Then in your `/bin/` folder you have a script that calls:

```dart
import "my_services.dart";

getServices().start();
```

And in you `build.dart` you set the script to generate the client classes:


```dart
// TODO
```

### On the client


You import the generated classes from the server, and use the services like this:



```dart
import "package:my_server/services.dart" as remote_services;

CreateUserRequest createUserRequest = getMessage();
remote_services.userService.create(createUserRequest);
```
