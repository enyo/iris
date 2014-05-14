library server_tests;

import "dart:io";

import "package:unittest/unittest.dart";
import "package:mock/mock.dart";

import "package:protobuf/protobuf.dart";

import "../lib/remote/iris.dart";
import "../lib/remote/annotations.dart" as anno;



class TestRequest implements GeneratedMessage { }
class TestResponse implements GeneratedMessage { }
class TestContext implements Context { }


class TestServer extends Mock implements IrisServer {

}

class TestService extends Service {

  @anno.Procedure()
  Future<TestResponse> create(Context context, TestRequest req) {
    return null;
  }

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

  group("Server", () {
  });

}


