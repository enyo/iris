library iris_tests;

import "dart:io";

import "package:unittest/unittest.dart";
import "package:mock/mock.dart";

import "package:protobuf/protobuf.dart";

import "../lib/remote/iris.dart";
import "../lib/remote/annotations.dart" as anno;
import 'dart:mirrors';



class TestRequest implements GeneratedMessage { }
class TestResponse implements GeneratedMessage { }
class TestContext implements Context { }


class TestServer extends Mock implements IrisServer {

}


Future serviceFilterFunc(Context context) => new Future.value();
Future filterFunc1(Context context) => new Future.value();
Future filterFunc2(Context context) => new Future.value();

class TestService extends Service {

  @anno.Procedure()
  Future<TestResponse> create(Context context, TestRequest req) => null;

  @anno.Procedure(filters: const [filterFunc1, filterFunc2])
  Future<TestResponse> auth(Context context, TestRequest req) => null;


}


@anno.IrisService(null, filters: const [serviceFilterFunc])
class ServiceWithFilters extends Service {

  @anno.Procedure()
  Future<TestResponse> noFilter(Context context, TestRequest req) => null;

  @anno.Procedure(filters: const [filterFunc1, filterFunc2])
  Future<TestResponse> allFilters(Context context, TestRequest req) => null;

}


class NoGeneratedMessageRouteService extends Service {

  @anno.Procedure()
  Future<String> create(Context context, TestRequest req) => null;

}


class WrongParamsRouteService extends Service {

  @anno.Procedure()
  Future<TestResponse> create(TestRequest req, Context context) => null;

}





main() {

  group("Iris", () {
    test("addService() should throw InvalidServiceDefinition if return type is no Future<GeneratedMessage>", () {
      var services = new Iris(new TestServer());
      expect(() => services.addService(new NoGeneratedMessageRouteService()), throws);
    });

    test("addService() should throw InvalidServiceDefinition if accepted params are not Context and GeneratedMessage", () {
      var services = new Iris(new TestServer());
      expect(() => services.addService(new WrongParamsRouteService()), throws);
    });

    test("addService() properly detects all procedures", () {
      var services = new Iris(new TestServer());
      services.addService(new TestService());
      services.procedures.first.invoke(new TestContext(), new TestRequest());
    });

    test("addService() finds all filters on procedures", () {
      var services = new Iris(new TestServer());
      services.addService(new TestService());
      expect(services.procedures.length, equals(2));
      expect(services.procedures.last.filterFunctions.length, equals(2));
      expect(services.procedures.last.filterFunctions.first, equals(filterFunc1));
      expect(services.procedures.last.filterFunctions.last, equals(filterFunc2));
    });

    test("addService() finds all filters on service and procedures and combines them", () {
      var services = new Iris(new TestServer());
      services.addService(new ServiceWithFilters());
      expect(services.procedures.length, equals(2));

      expect(services.procedures.first.filterFunctions.length, equals(1));
      expect(services.procedures.first.filterFunctions.first, equals(serviceFilterFunc));

      expect(services.procedures.last.filterFunctions.length, equals(3));
      expect(services.procedures.last.filterFunctions, equals([serviceFilterFunc, filterFunc1, filterFunc2]));
    });

    test("start() calls start() on the server and returns the Future from it", () {
      var server = new TestServer();

      var services = new Iris(server);

      services.addService(new TestService());

      var future = new Future.value();
      server.when(callsTo("start")).alwaysReturn(future);

      expect(server.calls("start").logs.length, equals(0));

      var returnedFuture = services.startServer();

      expect(future, equals(returnedFuture));

      expect(server.calls("start").logs.length, equals(1));

    });

    test("Iris forwards the prefix parameter to the services", () {
      var server = new TestServer();

      var services = new Iris(server, prefix: 'api/beta');

      services.addService(new TestService());

      services.procedures.firstWhere((procedure) => procedure.path == '/api/beta/TestService.create');

    });

    test("ServiceProcedure handles prefixes with or without leading/trailing slash", () {
      MethodMirror;
      var testService = new TestService();

      InstanceMirror classInstanceMirror = reflect(testService);
      ClassMirror myClassMirror = classInstanceMirror.type;
      MethodMirror methodMirror = myClassMirror.instanceMembers[new Symbol("create")];

      var procedure;

      procedure = new ServiceProcedure(testService, 'api', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/TestService.create'));

      procedure = new ServiceProcedure(testService, '/api', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/TestService.create'));

      procedure = new ServiceProcedure(testService, 'api/', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/TestService.create'));

      procedure = new ServiceProcedure(testService, 'api/v1.4', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/v1.4/TestService.create'));

      procedure = new ServiceProcedure(testService, '/api/v1.4/', methodMirror, null, null, null);
      expect(procedure.path, equals('/api/v1.4/TestService.create'));
    });

  });

}


