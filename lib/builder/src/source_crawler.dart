library source_crawler;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:path/path.dart' as path;

import 'analysis_utils.dart';

/**
 * A function which is called by the source crawler
 */
typedef void CompilationUnitVisitor(String libraryUri, String partUri, CompilationUnit compilationUnit);

class SourceCrawler {
  static const FILE_SCHEME = 'file://';
  static const DART_SCHEME = 'dart:';
  static const PACKAGE_SCHEME = 'package:';

  final PackageResolver packageResolver;

  /// Should the crawler include `package:` imports?
  final bool crawlPackages;

  SourceCrawler(List<String> packageRoots, bool this.crawlPackages):
    this.packageResolver = new PackageResolver(packageRoots);

  void crawl(String compilationUnitPath, CompilationUnitVisitor visit) {
    //A list of libraries to visit.
    var toVisit = <String>[];
    var visited = new Set<String>();

    if (!path.url.isAbsolute(compilationUnitPath)) {
      throw 'Must be called with an absolute path';
    }

    if (compilationUnitPath.startsWith(FILE_SCHEME))
      compilationUnitPath = compilationUnitPath.substring(FILE_SCHEME.length);

    toVisit.add(compilationUnitPath);

    while (toVisit.isNotEmpty) {
      var libPath = toVisit.removeLast();
      if (visited.contains(libPath)) {
        continue;
      }

      var libUnit = parseDartFile(libPath);
      if (!isLibrary(libUnit)) {
        throw '$compilationUnitPath must be dart library';
      }

      visit(libPath, libPath, libUnit);
      visited.add(libPath);

      var crawlVisitor = new CrawlVisitor();
      crawlVisitor.visitCompilationUnit(libUnit);

      var curDir = path.url.dirname(libPath);

      for (var partPath in crawlVisitor.parts) {
        var absPath = toAbsoluteUri(curDir, partPath);
        var partUnit = parseDartFile(absPath);
        visit(libPath, absPath, partUnit);
      }

      toVisit.addAll(
          crawlVisitor.importedLibs
              .map((importPath) => toAbsoluteUri(curDir, importPath))
              .where((importPath) => importPath != null)
      );
    }
  }

  bool isLibrary(CompilationUnit compilationUnit) =>
      compilationUnit.directives.every((dir) => dir is! PartOfDirective);

  /**
   * Return the absolute uri of the (possibly relative) uri, or `null` if
   * the uri should not be included in the list of paths to visit.
   */
  String toAbsoluteUri(String currentDir, String uri) {
    if (isDartUri(uri))
      return null;

    if (isPackageUri(uri)) {
      if (!crawlPackages) return null;
      var packageUri = Uri.parse(uri);
      return '${packageResolver.resolveAbsolute(packageUri)}';
    }

    if (currentDir.startsWith(FILE_SCHEME)) {
      currentDir = currentDir.substring(FILE_SCHEME.length);
    }

    if (uri.startsWith(FILE_SCHEME)) {
      uri = uri.substring(FILE_SCHEME.length);
    }

    if (path.url.isAbsolute(uri))
      return uri;

    return path.normalize(path.join(currentDir, uri));
  }

  bool isDartUri(uri) => uri.startsWith(DART_SCHEME);
  bool isPackageUri(uri) => uri.startsWith(PACKAGE_SCHEME);
}


class CrawlVisitor extends AstVisitor {
  List<String> parts = <String>[];
  List<String> importedLibs = <String>[];

  @override
  visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
  }

  @override
  visitImportDirective(ImportDirective node) {
    importedLibs.add(node.uri.stringValue);
  }

  @override
  visitPartDirective(PartDirective node) {
    parts.add(node.uri.stringValue);
  }

  dynamic noSuchMethod(Invocation invocation) => null;
}
