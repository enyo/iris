library iris_request_tests;

import "dart:io";

import "package:unittest/unittest.dart";
import "package:mock/mock.dart";

import "../lib/remote/iris.dart";


main() {

  group("IrisRequest", () {
    test(".cookies returns empty Array if it's a socket connection", () {
      var rsr = new IrisRequest.fromSocket();
      expect(rsr.cookies, equals([]));
    });
    test(".cookies returns the cookies from HttpRequest if it's a HTTP request", () {
      var httpReq = new MockHttpRequest();

      Cookie cookie1 = new Cookie("name1", "value1"),
        cookie2 = new Cookie("name2", "value2");

      httpReq.when(callsTo("get cookies")).alwaysReturn([ cookie1, cookie2 ]);
      var rsr = new IrisRequest.fromHttp(httpReq);
      expect(rsr.cookies, equals([ cookie1, cookie2 ]));
    });
  });

}


@proxy
class MockHttpRequest extends Mock implements HttpRequest {

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

}