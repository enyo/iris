library builder_tests;

import "dart:io";

import "package:unittest/unittest.dart";

import "../lib/builder.dart";


main() {

  group("Builder", () {
    test("relativePathToPbManifest should depend on includePbMessages", () {
      var manifest = new CompiledManifest(new Directory("../lib/target"), new File("../lib/orig_proto/messages_manifest.dart"), includePbMessages: false);

      expect(manifest.relativePathToPbManifest, equals("../orig_proto/messages_manifest.dart"));
      manifest.includePbMessages = true;

      expect(manifest.relativePathToPbManifest, equals("proto/messages_manifest.dart"));

    });
  });

}

