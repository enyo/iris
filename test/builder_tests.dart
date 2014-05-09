library builder_tests;

import "dart:io";

import "package:unittest/unittest.dart";

import "../lib/builder.dart";


main() {

  group("Builder", () {
    test("resolvePath() works as expected", () {


      expect(resolvePath("/home/test/../test2/../../lib"), equals("/lib"));

    });
    test("getRelativePath() works as expected", () {

      expect(getRelativePath(new Directory("../lib/proto"), new File("../lib/src/compiler/service.dart")), equals("../src/compiler/service.dart"));

      expect(getRelativePath(new Directory(".."), new File("../test.dart")), equals("test.dart"));

      expect(getRelativePath(new Directory("../foo/bar/../"), new File("../bar/test.dart")), equals("../bar/test.dart"));

    });

    test("relativePathToPbManifest should depend on includePbMessages", () {
      var manifest = new CompiledManifest(new Directory("../lib/target"), new File("../lib/orig_proto/messages_manifest.dart"), includePbMessages: false);

      expect(manifest.relativePathToPbManifest, equals("../orig_proto/messages_manifest.dart"));
      manifest.includePbMessages = true;

      expect(manifest.relativePathToPbManifest, equals("proto/messages_manifest.dart"));

    });
  });

}

