library server_tests;

import "dart:io";

import "package:unittest/unittest.dart";
import "package:mock/mock.dart";

import "package:protobuf/protobuf.dart";

import "../lib/remote/remote_services.dart";
import "../lib/remote/annotations.dart";



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

  group("Server", () {
  });

}


