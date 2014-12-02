library iris_tests;

import "dart:io";

import "package:unittest/unittest.dart";
import "package:mock/mock.dart";

import "package:protobuf/protobuf.dart";

import "../lib/remote/iris.dart";
import "../lib/remote/annotations.dart" as anno;
import 'dart:mirrors';



class TestRequest implements GeneratedMessage { noSuchMethod(Invocation invocation) => null; }
class TestResponse implements GeneratedMessage { noSuchMethod(Invocation invocation) => null; }
class TestContext implements Context { noSuchMethod(Invocation invocation) => null; }


class TestServer extends Mock implements IrisServer {

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

}


Future remoteFilterFunc(Context context) => new Future.value();
Future filterFunc1(Context context) => new Future.value();
Future filterFunc2(Context context) => new Future.value();

class RemoteTest extends Remote {

  @anno.Procedure()
  Future<TestResponse> create(Context context, TestRequest req) => null;

  @anno.Procedure(filters: const [filterFunc1, filterFunc2])
  Future<TestResponse> auth(Context context, TestRequest req) => null;


}


@anno.Remote(filters: const [remoteFilterFunc])
class RemoteWithFilters extends Remote {

  @anno.Procedure()
  Future<TestResponse> noFilter(Context context, TestRequest req) => null;

  @anno.Procedure(filters: const [filterFunc1, filterFunc2])
  Future<TestResponse> allFilters(Context context, TestRequest req) => null;

}


class NoGeneratedMessageRouteRemote extends Remote {

  @anno.Procedure()
  Future<String> create(Context context, TestRequest req) => null;

}


class WrongParamsRouteRemote extends Remote {

  @anno.Procedure()
  Future<TestResponse> create(TestRequest req, Context context) => null;

}





main() {

  group("Iris", () {
    test("addRemote() should throw InvalidRemoteDefinition if return type is no Future<GeneratedMessage>", () {
      var remotes = new Iris(new TestServer());
      expect(() => remotes.addRemote(new NoGeneratedMessageRouteRemote()), throws);
    });

    test("addRemote() should throw InvalidRemoteDefinition if accepted params are not Context and GeneratedMessage", () {
      var remotes = new Iris(new TestServer());
      expect(() => remotes.addRemote(new WrongParamsRouteRemote()), throws);
    });

    test("addRemote() properly detects all procedures", () {
      var remotes = new Iris(new TestServer());
      remotes.addRemote(new RemoteTest());
      remotes.procedures.first.invoke(new TestContext(), new TestRequest());
    });

    test("addRemote() finds all filters on procedures", () {
      var remotes = new Iris(new TestServer());
      remotes.addRemote(new RemoteTest());
      expect(remotes.procedures.length, equals(2));
      expect(remotes.procedures.last.filterFunctions.length, equals(2));
      expect(remotes.procedures.last.filterFunctions.first, equals(filterFunc1));
      expect(remotes.procedures.last.filterFunctions.last, equals(filterFunc2));
    });

    test("addRemote() finds all filters on remote and procedures and combines them", () {
      var remotes = new Iris(new TestServer());
      remotes.addRemote(new RemoteWithFilters());
      expect(remotes.procedures.length, equals(2));

      expect(remotes.procedures.first.filterFunctions.length, equals(1));
      expect(remotes.procedures.first.filterFunctions.first, equals(remoteFilterFunc));

      expect(remotes.procedures.last.filterFunctions.length, equals(3));
      expect(remotes.procedures.last.filterFunctions, equals([remoteFilterFunc, filterFunc1, filterFunc2]));
    });

    test("start() calls start() on the server and returns the Future from it", () {
      var server = new TestServer();

      var iris = new Iris(server);

      iris.addRemote(new RemoteTest());

      var future = new Future.value();
      server.when(callsTo("start")).alwaysReturn(future);

      expect(server.calls("start").logs.length, equals(0));

      var returnedFuture = iris.startServer();

      expect(future, equals(returnedFuture));

      expect(server.calls("start").logs.length, equals(1));

    });

    test("Iris forwards the prefix parameter to the remotes", () {
      var server = new TestServer();

      var iris = new Iris(server, prefix: 'api/beta');

      iris.addRemote(new RemoteTest());

      iris.procedures.firstWhere((procedure) => procedure.path == '/api/beta/RemoteTest.create');

    });

    test("RemoteProcedure handles prefixes with or without leading/trailing slash", () {
      MethodMirror;
      var testRemote = new RemoteTest();

      InstanceMirror classInstanceMirror = reflect(testRemote);
      ClassMirror myClassMirror = classInstanceMirror.type;
      MethodMirror methodMirror = myClassMirror.instanceMembers[new Symbol("create")];

      var procedure;

      procedure = new RemoteProcedure(testRemote, 'api', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/RemoteTest.create'));

      procedure = new RemoteProcedure(testRemote, '/api', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/RemoteTest.create'));

      procedure = new RemoteProcedure(testRemote, 'api/', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/RemoteTest.create'));

      procedure = new RemoteProcedure(testRemote, 'api/v1.4', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/v1.4/RemoteTest.create'));

      procedure = new RemoteProcedure(testRemote, '/api/v1.4/', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/v1.4/RemoteTest.create'));
    });

  });

}


