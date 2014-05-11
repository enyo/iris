library filter_tests;


import "package:unittest/unittest.dart";


import "../lib/remote/remote_services.dart";



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
