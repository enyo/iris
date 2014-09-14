library package_visitor_test;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:iris/builder/src/analysis_utils.dart';

const SDK_LOCATION = '/usr/local/lib/dart-sdk';
final PROJECT_ROOT = () {
  var dir = new Directory(path.dirname(Platform.script.path));
  while (dir.listSync().every((f) => path.basename(f.path) != 'pubspec.yaml')) {
    dir = dir.parent;
  }
  return 'file://${dir.absolute.path}';
}();

final PACKAGE_ROOTS = [path.join(PROJECT_ROOT, 'packages')];

void main() {
  group('package resolver', () {

    var resolver = new PackageResolver(PACKAGE_ROOTS);

    test("should be able to resolve a package: path", () {
      var uri = Uri.parse('package:iris/client/client.dart');
      var source = resolver.resolveAbsolute(uri);
      expect(source.uri, uri);
    });
  });

  group('analysis', () {
    var analysis_utils = new AnalysisUtils(SDK_LOCATION, PACKAGE_ROOTS);

    test("should be able to get the `DartType` of `GeneratedMessage`", () {
      var messageType = analysis_utils.generatedMessageType;
      expect(messageType.name, 'GeneratedMessage');
    });

    test("should be able to get all the subclasses of `GeneratedMessage` in a generated protobuf file", () {
      var libSource = analysis_utils.analysisContext.sourceFactory
          .forUri(path.join(PROJECT_ROOT, 'test/protos/test_service.pb.dart'));
      var libElement = analysis_utils.analysisContext.computeLibraryElement(libSource);
      var types = analysis_utils.generatedMessageTypesInScope(libElement);
      expect(types.map((type) => type.name), [
          'File', 'UploadFileRequest', 'UploadFileResponse'
      ]);
    });

    test("should be able to get all types exposed by a manifest file", () {
      var libSource = analysis_utils.analysisContext.sourceFactory
          .forUri(path.join(PROJECT_ROOT, 'test/protos/messages.pbmanifest.dart'));
      var libElement = analysis_utils.analysisContext.computeLibraryElement(libSource);
      var types = analysis_utils.generatedMessageTypesInScope(libElement);
      expect(types.map((type) => type.name), ['File', 'UploadFileRequest', 'UploadFileResponse']);
    });

    test("should respect export combinators", () {
      var libSource = analysis_utils.analysisContext.sourceFactory
          .forUri(path.join(PROJECT_ROOT, 'test/protos/export_combinators.dart'));
      var libElement = analysis_utils.analysisContext.computeLibraryElement(libSource);
      var types = analysis_utils.generatedMessageTypesInScope(libElement);
      expect(types.map((type) => type.name), ['UploadFileRequest', 'UploadFileResponse', 'DescriptorProto']);
    });

    test("should not collect types which aren't subtypes", () {
      var libSource = analysis_utils.analysisContext.sourceFactory
          .forUri(path.join(PROJECT_ROOT, 'lib/builder/builder.dart'));
      var libElement = analysis_utils.analysisContext.computeLibraryElement(libSource);
      var types = analysis_utils.generatedMessageTypesInScope(libElement);
      expect(types.map((type) => type.name), []);
    });

    test("should be able to find the types imported by a library", () {
      var libSource = analysis_utils.analysisContext.sourceFactory
          .forUri(path.join(PROJECT_ROOT, 'test', 'protos', 'imports.dart'));
      var libElement = analysis_utils.analysisContext.computeLibraryElement(libSource);
      var types = analysis_utils.generatedMessageTypesInScope(libElement);
      expect(types.map((type) => type.name), [
              'File',
              'UploadFileRequest',
              'UploadFileResponse',
              'DescriptorProto',
              'CodeGeneratorRequest',
              'CodeGeneratorResponse']);
    });
  });
}