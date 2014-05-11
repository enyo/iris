library builder_tests;

import "dart:io";
import "dart:async";
import 'package:fixnum/fixnum.dart';

import "package:unittest/unittest.dart";


import "package:remote_services/client/client.dart" as client_lib;
import "package:remote_services/client/server_http_client.dart";

import "package:remote_services/remote/remote_services.dart" as remote;
import "package:remote_services/remote/error_code.dart";
import "package:remote_services/remote/annotations.dart" as annotation;

import "src/authentication.pb.dart";
import "src/user.pb.dart";


const int PORT = 8123;


Future<bool> authFilter(MyContext context) {
  return new Future.value(true);
}

Future<bool> unauthFilter(MyContext context) {
  return new Future.value(false);
}


class MyContext extends remote.Context {

  MyContext(req) : super(req);

}


class UserService extends remote.Service {

  @annotation.Procedure(filters: const [authFilter])
  Future<User> search(MyContext context, UserSearch req) {
    return new Future.value(
        new User()
            ..id = new Int64(234)
            ..email = "eee@mail.com"
            ..name = "test name"
        );
  }

  @annotation.Procedure(filters: const [unauthFilter])
  Future<User> unauthorized(MyContext context, UserSearch req) {
    return new Future.value(
        new User()
            ..id = new Int64(234)
            ..email = "eee@mail.com"
            ..name = "test name"
        );
  }

  @annotation.Procedure()
  Future<User> throws(MyContext context, UserSearch req) {
    throw new remote.ProcedureException(ErrorCode.ERROR_CODE_TEST, "Oh noes.");
  }

  Future<User> notAnnotated(MyContext context, UserSearch req) {
    throw new remote.ProcedureException(ErrorCode.ERROR_CODE_TEST, "Oh noes.");
  }

  @annotation.Procedure()
  Future<User> noMessage(MyContext context) {
    return new Future.value(
        new User()
            ..id = new Int64(234)
            ..email = "eee@mail.com"
            ..name = "test name"
        );
  }

  @annotation.Procedure()
  Future noReturnMessage(MyContext context, UserSearch req) {
    if (req.name != "no return message") {
      throw new Exception();
    }
    return null;
  }


  @annotation.Procedure()
  Future noMessages(MyContext context) {
    return new Future.value();
  }


}

Future<MyContext> contextInitializer(remote.ServiceRequest req) {
  var context = new MyContext(req);

  return new Future.value(context);
}

remote.ServiceDefinitions getServices() {
  return new remote.ServiceDefinitions(contextInitializer)
        ..addService(new UserService())
        ..addServer(new remote.HttpServiceServer("localhost", PORT, allowOrigin: "http://127.0.0.1:3030"));
}

class ClientUserService extends client_lib.Service {

  ClientUserService(client_lib.ServiceClient client) : super(client);

  Future<User> search(UserSearch requestMessage) => client.dispatch('/UserService.search', requestMessage, User);

  Future<User> unauthorized(UserSearch requestMessage) => client.dispatch('/UserService.unauthorized', requestMessage, User);

  Future<User> throws(UserSearch requestMessage) => client.dispatch('/UserService.throws', requestMessage, User);

  Future<User> notAnnotated(UserSearch requestMessage) => client.dispatch('/UserService.notAnnotated', requestMessage, User);

  Future<User> noMessage() => client.dispatch('/UserService.noMessage', null, User, false);

  Future noReturnMessage(UserSearch requestMessage) => client.dispatch('/UserService.noReturnMessage', requestMessage, null);

  Future noMessages() => client.dispatch('/UserService.noMessages', null, null, false);

}

class ErrorCode extends RemoteServicesErrorCode {

  static const ERROR_CODE_TEST = const ErrorCode._(19);

  const ErrorCode._(int value) : super(value);
}


main() {

  var services = getServices();

  var client = new HttpServiceClient(Uri.parse("http://localhost:$PORT"));
  var clientUserService = new ClientUserService(client);


  setUp(() {
    return services.startServers();
  });

  tearDown(() {
    return services.stopServers();
  });

  group("Integration", () {
    test("methods without the Procedure annotation get ignored", () {
      var future = clientUserService.notAnnotated(new UserSearch()..name = "TEST")
          .then((_) => fail("Shouldn't be reached"))
          .catchError((client_lib.ServiceClientException excp) {
            expect(excp.errorCode, equals(RemoteServicesErrorCode.RS_PROCEDURE_NOT_FOUND.value));
          });

      expect(future, completes);
    });
    test("serving normal message works()", () {
      var future = clientUserService.search(new UserSearch()..name = "TEST").then((User user) {
        expect(user.email, equals("eee@mail.com"));
        expect(user.name, equals("test name"));
      });
      expect(future, completes);
    });
    test("filters work properly", () {
      var future = clientUserService.unauthorized(new UserSearch()..name = "TEST")
          .then((_) => fail("Shouldn't be reached"))
          .catchError((client_lib.ServiceClientException excp) {
            expect(excp.errorCode, equals(RemoteServicesErrorCode.RS_REJECTED_BY_FILTER.value));
            expect(excp.internalMessage, equals("The filter 'unauthFilter' rejected the request."));
          });

      expect(future, completes);
    });
    test("ProcedureExceptions get transmitted properly", () {
      var future = clientUserService.throws(new UserSearch()..name = "TEST")
          .then((_) => fail("Shouldn't be reached"))
          .catchError((client_lib.ServiceClientException excp) {
            expect(excp.errorCode, equals(ErrorCode.ERROR_CODE_TEST.value));
            expect(excp.internalMessage, equals("Oh noes."));
          });

      expect(future, completes);
    });
    test("procedures can accept requests without pb messages", () {
      var future = clientUserService.noMessage()
          .then((User user) {
            expect(user.email, equals("eee@mail.com"));
            expect(user.name, equals("test name"));
          });

      expect(future, completes);
    });
    test("procedures can not return pb messages", () {
      var future = clientUserService.noReturnMessage(new UserSearch()..name = "no return message")
          .then((_) {
            expect(_, isNull);
          });

      expect(future, completes);
    });
    test("procedures can not require any pb messages", () {
      var future = clientUserService.noMessages()
          .then((_) {
        expect(_, isNull);
      });

      expect(future, completes);
    });
  });

}
