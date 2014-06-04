library server_tests;

import "dart:io";

import "package:unittest/unittest.dart";
import "package:mock/mock.dart";


import "../lib/remote/iris.dart";




class MockReq extends Mock implements HttpRequest {

  HttpResponse response = new MockRes();

  Uri uri;

}

class MockRes extends Mock implements HttpResponse {

  HttpHeaders headers = new MockHeaders();

}

class MockHeaders extends Mock implements HttpHeaders {

  Map data = {};

  add(String name, String value) {
    data[name] = value;
  }

}


main() {

  group("Server", () {
    test("setCorsHeaders() sets proper headers", () {

      var allowOrigins = const [
                                "http://localhost:11122",
                                "https://www.google.com",
                                "http://exit.live:80",
                                "https://exit.live:443",
                                ];

      var server = new HttpIrisServer("", 12344, allowOrigins: allowOrigins);

      var req = new MockReq();
      req.uri = Uri.parse("http://localhost:11122");
      server.setCorsHeaders(req);
      expect(req.response.headers.data, equals({
        "Access-Control-Allow-Credentials": 'true',
        "Access-Control-Allow-Headers": "Content-Type, X-Requested-With, X-PINGOTHER, X-File-Name, Cache-Control",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Origin": "http://localhost:11122" }));

      req = new MockReq();
      req.uri = Uri.parse("https://www.google.com/search");
      server.setCorsHeaders(req);
      expect(req.response.headers.data["Access-Control-Allow-Origin"], equals("https://www.google.com"));


      // Fails because :80 has been specified in allow origins
      req = new MockReq();
      req.uri = Uri.parse("http://exit.live:80/profile");
      server.setCorsHeaders(req);
      expect(req.response.headers.data["Access-Control-Allow-Origin"], equals(null));

      // Fails because :443 has been specified in allow origins
      req = new MockReq();
      req.uri = Uri.parse("https://exit.live:443/profile");
      server.setCorsHeaders(req);
      expect(req.response.headers.data["Access-Control-Allow-Origin"], equals(null));


    });
  });

}


