library method_analyzer_test;

import 'package:unittest/unittest.dart';

import 'dart:io';

import 'package:analyzer/src/generated/element.dart';
import 'package:path/path.dart' as path;

import 'package:protoc_plugin/src/descriptor.pb.dart';

import 'package:iris/builder/src/analysis_utils.dart';
import 'package:iris/builder/src/service_analyzer.dart';
import 'package:iris/builder/src/service_info.dart';

final SDK_LOCATION = '/usr/local/lib/dart-sdk';

final PROJECT_ROOT = () {
  var dir = new Directory(path.dirname(Platform.script.path));
  while (dir.listSync().every((f) => path.basename(f.path) != 'pubspec.yaml')) {
    dir = dir.parent;
  }
  return dir.absolute.path;
}();

final PACKAGE_ROOTS = [path.join(PROJECT_ROOT, 'packages')];

class MockServiceAnalyzer implements ServiceAnalyzer {

  final LibraryElement library;

  LibraryElement getServiceLibrary(ServiceInfo serviceInfo) {
    return library;
  }

  ClassElement getServiceClassElement(ServiceInfo serviceInfo) {
    return library.getType(serviceInfo.serviceName);
  }

  MockServiceAnalyzer(this.library);

  noSuchMethod(Invocation invocation) {
    throw new UnsupportedError('${invocation.memberName}');
  }
}


void main() {

  if (SDK_LOCATION == null) {
    throw "Must set 'DART_HOME' environment variable";
  }

  var analysisUtils = new AnalysisUtils(SDK_LOCATION, PACKAGE_ROOTS);

  group('analyze method return type', () {
    var methodDescriptorProto = new MethodDescriptorProto()
        ..name = 'uploadFile'
        ..inputType = '.UploadFileRequest'
        ..outputType = '.UploadFileResponse';

    var serviceDescriptor = new ServiceDescriptorProto()
        ..name = 'FileService'
        ..method.add(methodDescriptorProto);


    var libSource = analysisUtils.analysisContext.sourceFactory
              .forUri2(new Uri.file(path.join(PROJECT_ROOT, 'test', 'builder', 'service_source.dart')));
    var lib = analysisUtils.analysisContext.computeLibraryElement(libSource);

    var serviceInfo = new ServiceInfo()
        ..serviceDescriptor = serviceDescriptor
        ..compilationUnit = lib.unit
        ..classDeclaration = lib.getType('FileService').node;

    var methodAnalyzer = new MethodAnalyzer(
        analysisUtils,
        new MockServiceAnalyzer(lib),
        serviceInfo
    );

    test("should be able to analyze a fully typed async return type", () {
      var msgs = methodAnalyzer.analyze(methodDescriptorProto);
      expect(msgs, isNull);
    });

  });
}
