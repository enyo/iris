library source_crawler_test;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:analyzer/analyzer.dart';
import 'package:unittest/unittest.dart';
import 'package:iris/builder/src/source_crawler.dart';
import 'package:iris/builder/src/service_info.dart';

const SDK_LOCATION = '/usr/local/lib/dart-sdk';
final PROJECT_ROOT = () {
  var dir = new Directory(path.dirname(Platform.script.path));
  while (dir.listSync().every((f) => path.basename(f.path) != 'pubspec.yaml')) {
    dir = dir.parent;
  }
  return 'file://${dir.absolute.path}';
}();

void main() {
  group('crawl visitor', () {
    var lib = '''
library mylib;

import 'package:package/path.dart';

part 'mypart.dart';
''';
    var unit = parseCompilationUnit(lib);

    test("should collect all uri directives in lib", () {
      var crawlVisitor = new CrawlVisitor();
      crawlVisitor.visitCompilationUnit(unit);
      expect(crawlVisitor.importedLibs, ['package:package/path.dart']);
      expect(crawlVisitor.parts, ['mypart.dart']);
    });
  });

  group('source crawler', () {

    var sourceCrawler = new SourceCrawler([path.join(PROJECT_ROOT, 'packages')], true);

    group('absolute uris', () {

      var projRoot = PROJECT_ROOT.substring('file://'.length);

      test("should be able to create an absolute package uri", () {
        var packageUri = 'package:protobuf/protobuf.dart';
        var packageRoot = path.join(PROJECT_ROOT, 'packages');
        expect(
            sourceCrawler.toAbsoluteUri(PROJECT_ROOT, packageUri),
            path.join(projRoot, 'packages', 'protobuf/protobuf.dart')
        );
      });

      test("an absolutely specified file path should be untouched", () {
        expect(
            sourceCrawler.toAbsoluteUri(PROJECT_ROOT, '/usr/local/bin'),
            '/usr/local/bin'
        );
      });

      test("a relatively specified file path should be returned relative to the current directory", () {
        expect(
            sourceCrawler.toAbsoluteUri(PROJECT_ROOT, 'lib/builder/builder.dart'),
            path.join(projRoot, 'lib/builder/builder.dart')
        );
      });
    });

    test("should be able to crawl a list of directories", () {
      var numVisited = 0;
      visit(libraryUri, compilationUnitUri, compilationUnit) {
        numVisited++;
      }
      var compilationUnitPath = path.url.join(PROJECT_ROOT, 'lib/builder/builder.dart');
      sourceCrawler.crawl(compilationUnitPath, visit);
      expect(numVisited, greaterThan(0));
    });
  });

  group('crawl metadata', () {
    test("should collect all services defined in a file", () {
      var entryPoint = path.join(PROJECT_ROOT, 'test/builder/service_source.dart');
      var packageRoots = [path.join(PROJECT_ROOT, 'packages')];
      var infos = ServiceInfo.crawl(entryPoint, packageRoots);
      var info = infos.single;
      expect(info.serviceName, 'FileService');
      expect(info.compilationUnitPath, path.join(PROJECT_ROOT.substring('file://'.length), 'test/builder/service_source.dart'));
      expect(info.protobufferTemplatePath, 'test/services.proto');
    });
  });
}