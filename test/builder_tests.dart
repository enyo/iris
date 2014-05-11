library builder_tests;

import "dart:io";

import "package:unittest/unittest.dart";

import "../lib/builder/builder.dart";
import "../lib/remote/error_code.dart";


class ErrorCode extends RemoteServicesErrorCode {


  static const INVALID_EMAIL = const ErrorCode(1);

  static const INVALID_USERNAME = const ErrorCode(2);


  const ErrorCode(value) : super(value);

}

class InvalidCode1 extends RemoteServicesErrorCode {

  static const INVALID_EMAIL = const ErrorCode(1);

  /// Two times same code.
  static const INVALID_USERNAME = const ErrorCode(1);

  const InvalidCode1(value) : super(value);

}

class InvalidCode2 extends RemoteServicesErrorCode {

  static const RS_BLABLA = const ErrorCode(1);


  const InvalidCode2(value) : super(value);

}

class InvalidCode3 extends RemoteServicesErrorCode {

  static const INVALID_EMAIL = const ErrorCode(955);


  const InvalidCode3(value) : super(value);

}



class Test { }

main() {

  group("Builder", () {
    test("relativePathToPbManifest should depend on includePbMessages", () {
      var manifest = new CompiledManifest("../lib/target", "../lib/orig_proto/messages_manifest.dart", includePbMessages: false);

      expect(manifest.relativePathToPbManifest, equals("../orig_proto/messages_manifest.dart"));
      manifest.includePbMessages = true;

      expect(manifest.relativePathToPbManifest, equals("proto/messages_manifest.dart"));

    });

    group("ErrorCodes", () {
      test("should throw when the type is incorrect", () {
        expect(() => new CompiledErrorCodes('xxx', Test), throws);
      });
      test("should throw when using same code twice", () {
        expect(() => new CompiledErrorCodes('xxx', InvalidCode1)..codes, throws);
      });
      test("should throw when using key that starts with RS_", () {
        expect(() => new CompiledErrorCodes('xxx', InvalidCode2)..codes, throws);
      });
      test("should throw when using an error code between 900 and 999", () {
        expect(() => new CompiledErrorCodes('xxx', InvalidCode3)..codes, throws);
      });
      test("should get all codes", () {
        var cec = new CompiledErrorCodes("xxx", ErrorCode);
        var codes = cec.codes;

        expect(codes["INVALID_EMAIL"], equals(1));
        expect(codes["INVALID_USERNAME"], equals(2));
        expect(codes["RS_PROCEDURE_NOT_FOUND"], equals(RemoteServicesErrorCode.RS_PROCEDURE_NOT_FOUND.value));
        expect(codes["RS_INTERNAL_SERVER_ERROR"], equals(RemoteServicesErrorCode.RS_INTERNAL_SERVER_ERROR.value));

      });
    });
  });

}

