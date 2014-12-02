library server_tests;

import "dart:io";

import "package:unittest/unittest.dart";
import "package:mock/mock.dart";


import "../lib/remote/iris.dart";




class MockReq extends Mock implements HttpRequest {

  HttpResponse response = new MockRes();

  HttpHeaders headers = new MockHeaders();

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

}

class MockRes extends Mock implements HttpResponse {

  HttpHeaders headers = new MockHeaders();

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

}

class MockHeaders extends Mock implements HttpHeaders {

  Map<String, String> data = {};

  add(String name, String value) {
    data[name] = value;
  }


  List<String> operator [](String name) {
    return [data[name]];
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

}


main() {

  group("Server", () {
    test("setCorsHeaders() sets proper headers", () {

      var allowOrigins = const [
                                "http://localhost:11122",
                                "https://www.google.com",
                                ];

      var server = new IrisHttpServer("", 12344, allowOrigins: allowOrigins);

      var req = new MockReq();
      req.headers.add("origin", "http://localhost:11122");
      server.setCorsHeaders(req);
      expect(req.response.headers.data, equals({
        "Access-Control-Allow-Credentials": 'true',
        "Access-Control-Allow-Headers": "Content-Type, X-Requested-With, X-PINGOTHER, X-File-Name, Cache-Control",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Origin": "http://localhost:11122" }));

      req = new MockReq();
      req.headers.add("origin", "https://www.google.com");
      server.setCorsHeaders(req);
      expect(req.response.headers.data["Access-Control-Allow-Origin"], equals("https://www.google.com"));


      req = new MockReq();
      req.headers.add("origin", "https://www.unknown.com");
      server.setCorsHeaders(req);
      expect(req.response.headers.data["Access-Control-Allow-Origin"], equals(null));



    });
  });

}


