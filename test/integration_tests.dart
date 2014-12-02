library integration_tests;

import "dart:async";
import 'package:fixnum/fixnum.dart';

import "package:unittest/unittest.dart";


import "package:iris/client/client.dart" as client_lib;
import "package:iris/client/server_http_client.dart";

import "package:iris/remote/iris.dart" as remote;
import "package:iris/remote/error_code.dart";
import "package:iris/remote/annotations.dart" as annotation;

import "src/authentication.pb.dart";
import "src/user.pb.dart";
import 'dart:io';


const int PORT = 8123;


Future<bool> authFilter(MyContext context) {
  return new Future.value(true);
}

Future<bool> unauthFilter(MyContext context) {
  return new Future.value(false);
}

Future throwingFilter (MyContext context) {
  throw new remote.ProcedureException(ErrorCode.FILTER_ERROR_CODE, "Filter error message");
}

class MyContext extends remote.Context {

  MyContext(req) : super(req);

}


class RemoteUser extends remote.Remote {

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

  @annotation.Procedure()
  Future throwsRandomException(MyContext context) {
    throw new Exception("Oups, something went through.");
  }

  Future<User> notAnnotated(MyContext context, UserSearch req) => null;

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

  @annotation.Procedure()
  Future throwsProcedureException(MyContext context) {
    throw new remote.ProcedureException(ErrorCode.ERROR_CODE_TEST, "Test message");
  }

  @annotation.Procedure(filters: const[throwingFilter])
  Future filterThrows(MyContext context) => new Future.value();


}

Future<MyContext> contextInitializer(remote.IrisRequest req) {
  var context = new MyContext(req);

  return new Future.value(context);
}

remote.Iris getRemotes() {
  return new remote.Iris(new remote.IrisHttpServer("localhost", PORT, allowOrigins: const["http://127.0.0.1:3030"]), contextInitializer: contextInitializer)
        ..addRemote(new RemoteUser());
}

class RemoteClientUser extends client_lib.Remote {

  RemoteClientUser(client_lib.IrisClient client) : super(client);

  Future<User> search(UserSearch requestMessage) => client.dispatch('/RemoteUser.search', requestMessage, (bytes) => new User.fromBuffer(bytes));

  Future<User> unauthorized(UserSearch requestMessage) => client.dispatch('/RemoteUser.unauthorized', requestMessage, (bytes) => new User.fromBuffer(bytes));

  Future<User> throws(UserSearch requestMessage) => client.dispatch('/RemoteUser.throws', requestMessage, (bytes) => new User.fromBuffer(bytes));

  Future throwsRandomException() => client.dispatch('/RemoteUser.throwsRandomException', null, (bytes) => new User.fromBuffer(bytes), false);

  Future<User> notAnnotated(UserSearch requestMessage) => client.dispatch('/RemoteUser.notAnnotated', requestMessage, (bytes) => new User.fromBuffer(bytes));

  Future<User> noMessage() => client.dispatch('/RemoteUser.noMessage', null, (bytes) => new User.fromBuffer(bytes), false);

  Future noReturnMessage(UserSearch requestMessage) => client.dispatch('/RemoteUser.noReturnMessage', requestMessage, null);

  Future noMessages() => client.dispatch('/RemoteUser.noMessages', null, null, false);

  Future throwsProcedureException() => client.dispatch('/RemoteUser.throwsProcedureException', null, null, false);

  Future filterThrows() => client.dispatch('/RemoteUser.filterThrows', null, null, false);

}

class ErrorCode extends IrisErrorCode {

  static const ERROR_CODE_TEST = const ErrorCode._(19);

  static const FILTER_ERROR_CODE = const ErrorCode._(20);

  const ErrorCode._(int value) : super(value);
}


main() {

  var remotes = getRemotes();

  var client = new HttpIrisClient(Uri.parse("http://localhost:$PORT"));
  var remoteClientUser = new RemoteClientUser(client);


  setUp(() {
    return remotes.startServer();
  });

  tearDown(() {
    return remotes.stopServer();
  });

  group("Integration", () {
    test("methods without the Procedure annotation get ignored", () {
      var future = remoteClientUser.notAnnotated(new UserSearch()..name = "TEST")
          .then((_) => fail("Shouldn't be reached"))
          .catchError((client_lib.IrisException excp) {
            expect(excp.errorCode, equals(IrisErrorCode.IRIS_PROCEDURE_NOT_FOUND.value));
          });

      expect(future, completes);
    });
    test("serving normal message works()", () {
      var future = remoteClientUser.search(new UserSearch()..name = "TEST").then((User user) {
        expect(user.email, equals("eee@mail.com"));
        expect(user.name, equals("test name"));
      });
      expect(future, completes);
    });
    test("filters work properly", () {
      var future = remoteClientUser.unauthorized(new UserSearch()..name = "TEST")
          .then((_) => fail("Shouldn't be reached"))
          .catchError((client_lib.IrisException excp) {
            expect(excp.errorCode, equals(IrisErrorCode.IRIS_REJECTED_BY_FILTER.value));
            expect(excp.internalMessage, equals("The filter 'unauthFilter' rejected the request."));
          });

      expect(future, completes);
    });
    test("ProcedureExceptions get transmitted properly", () {
      var future = remoteClientUser.throws(new UserSearch()..name = "TEST")
          .then((_) => fail("Shouldn't be reached"))
          .catchError((client_lib.IrisException excp) {
            expect(excp.errorCode, equals(ErrorCode.ERROR_CODE_TEST.value));
            expect(excp.internalMessage, equals("Oh noes."));
          });

      expect(future, completes);
    });
    test("random exceptions get sanitized properly", () {
      var future = remoteClientUser.throwsRandomException()
          .then((_) => fail("Shouldn't be reached"))
          .catchError((client_lib.IrisException excp) {
            expect(excp.errorCode, equals(IrisErrorCode.IRIS_INTERNAL_SERVER_ERROR.value));
            expect(excp.internalMessage, equals("Exception: Oups, something went through."));
          });

      expect(future, completes);
    });
    test("procedures can accept requests without pb messages", () {
      var future = remoteClientUser.noMessage()
          .then((User user) {
            expect(user.email, equals("eee@mail.com"));
            expect(user.name, equals("test name"));
          });

      expect(future, completes);
    });
    test("procedures can not return pb messages", () {
      var future = remoteClientUser.noReturnMessage(new UserSearch()..name = "no return message")
          .then((_) {
            expect(_, isNull);
          });

      expect(future, completes);
    });
    test("procedures can not require any pb messages", () {
      var future = remoteClientUser.noMessages()
          .then((_) {
        expect(_, isNull);
      });

      expect(future, completes);
    });
    test("error codes get passed to the client properly", () {
      var future = remoteClientUser.throwsProcedureException()
          .then((_) => fail("Should never be reached"))
          .catchError((client_lib.IrisException exc) {
            expect(exc.errorCode, equals(ErrorCode.ERROR_CODE_TEST.value));
          });


      expect(future, completes);
    });
    test("when a filter throws a ProcedureException it gets passed to the client properly", () {
      var future = remoteClientUser.filterThrows()
          .then((_) => fail("Should never be reached"))
          .catchError((client_lib.IrisException exc) {
            expect(exc.errorCode, equals(ErrorCode.FILTER_ERROR_CODE.value));
            expect(exc.internalMessage, equals("Filter error message"));
          });


      expect(future, completes);
    });
  });

}
