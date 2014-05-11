library filter_tests;

import "dart:io";

import "package:unittest/unittest.dart";
import "package:mock/mock.dart";

import "package:protobuf/protobuf.dart";

import "../lib/remote_services.dart";
import "../lib/annotations.dart";



Future<bool> authFilter(Context context) {
  return new Future.value(true);
}




main() {

  group("Filter", () {
    group("_FilterException", () {
      test(".getFilterName()", () {
        var exc = new FilterException(authFilter);
        expect(exc.filterName, equals("authFilter"));
      });
    });
  });

}


