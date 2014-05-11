library services_tests;

import "dart:io";

import "package:unittest/unittest.dart";
import "package:mock/mock.dart";

import "package:protobuf/protobuf.dart";

import "../lib/remote_services.dart";
import "../lib/annotations.dart";



class TestRequest implements GeneratedMessage { }
class TestResponse implements GeneratedMessage { }
class TestContext implements Context { }


class TestServer extends Mock implements ServiceServer {

}

class TestService extends Service {

  @Procedure()
  Future<TestResponse> create(Context context, TestRequest req) {
    return null;
  }

}


class NoGeneratedMessageRouteService extends Service {

  @Procedure()
  Future<String> create(Context context, TestRequest req) => null;

}


class WrongParamsRouteService extends Service {

  @Procedure()
  Future<TestResponse> create(TestRequest req, Context context) => null;

}





main() {

  group("Services", () {
    test("addService() should throw InvalidServiceDefinition if return type is no Future<GeneratedMessage>", () {
      var services = new ServiceDefinitions();
      expect(() => services.addService(new NoGeneratedMessageRouteService()), throws);
    });

    test("addService() should throw InvalidServiceDefinition if accepted params are not Context and GeneratedMessage", () {
      var services = new ServiceDefinitions();
      expect(() => services.addService(new WrongParamsRouteService()), throws);
    });

    test("addService() properly detects all procedures", () {
      var services = new ServiceDefinitions();
      services.addService(new TestService());
      services.procedures.first.invoke(new TestContext(), new TestRequest());
    });

    test("addService() throws if a server has already been set", () {
      var services = new ServiceDefinitions();
      services.addService(new TestService());
      services.addServer(new TestServer());
      expect(() => services.addService(new TestService()), throws);
    });

    test("addServer() throws if no procedure has been added yet", (){
      var services = new ServiceDefinitions();
      expect(() => services.addServer(new TestServer()), throws);
    });


    test("start() calls start() on all servers and resolves Future when all are done", () {
      var services = new ServiceDefinitions();
      services.addService(new TestService());

      var server1 = new TestServer();
      var server2 = new TestServer();

      services
          ..addServer(server1)
          ..addServer(server2);

      server1.when(callsTo("start")).alwaysReturn(new Future.value());

      var server2Completer = new Completer();

      server2.when(callsTo("start")).alwaysReturn(server2Completer.future);

      expect(server1.calls("start").logs.length, equals(0));
      expect(server2.calls("start").logs.length, equals(0));

      var allFinished = false;
      var finished = services.startServers();

      finished.whenComplete(expectAsync(() => expect(allFinished, equals(true))));

      expect(server1.calls("start").logs.length, equals(1));
      expect(server2.calls("start").logs.length, equals(1));

      new Timer(new Duration(milliseconds: 100), () {
        allFinished = true;
        server2Completer.complete();
      });


    });

  });

}


