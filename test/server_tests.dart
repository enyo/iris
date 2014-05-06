library server_tests;

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

  @Route()
  Future<TestResponse> create(Context context, TestRequest req) {
    return null;
  }

}


class NoGeneratedMessageRouteService extends Service {

  @Route()
  Future<String> create(Context context, TestRequest req) => null;

}


class WrongParamsRouteService extends Service {

  @Route()
  Future<TestResponse> create(TestRequest req, Context context) => null;

}





main() {

  group("Server", () {
  });

}


