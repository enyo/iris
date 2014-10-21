library analysis_visitor;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:path/path.dart' as path;

import '../build_options.dart';

class AnalysisUtils {

  final DartSdk dartSdk;
  final List<String> packageRootPaths;

  factory AnalysisUtils.withOptions(BuildOptions buildOpts) {
    return new AnalysisUtils(buildOpts.pathToSdk, buildOpts.packageRoots);
  }

  AnalysisUtils(String pathToSdk, this.packageRootPaths):
    this.dartSdk = new DirectoryBasedDartSdk(new JavaFile(pathToSdk));

  AnalysisContext _analysisContext;

  AnalysisContext get analysisContext {
    if (_analysisContext == null) {
      _analysisContext = new AnalysisContextImpl()
        ..sourceFactory = new SourceFactory([
            new DartUriResolver(dartSdk),
            new PackageResolver(packageRootPaths),
            new FileUriResolver()
        ]);
    }
    return _analysisContext;
  }

  SourceFactory get sourceFactory => analysisContext.sourceFactory;

  /**
   * Generated message types imported into the scope of the library.
   */
  Iterable<DartType> generatedMessageTypesInScope(LibraryElement library) {
    var subtypeCollector = new SubtypeCollector(analysisContext, generatedMessageType);
    //Collect all the scopes directly defined in this library
    var typesInScope = subtypeCollector.collect(library).toList();

    //For each imported library, collect from the import and add the
    //exposed types.
    for (var importElement in library.imports) {
      if (importElement.uri == null ||
          importElement.uri == DartUriResolver.DART_SCHEME) {
        //No generated messages in `dart:*` libraries.
        continue;
      }

      var subtypeCollector = new SubtypeCollector(analysisContext, generatedMessageType);
      var importedTypes = subtypeCollector.collect(importElement.importedLibrary);
      for (var combinator in importElement.combinators) {
        if (combinator is ShowElementCombinator) {
          importedTypes = importedTypes
              .where((type) => combinator.shownNames.contains(type.name));
        }
        if (combinator is HideElementCombinator) {
          importedTypes = importedTypes
              .where((type) => !combinator.hiddenNames.contains(type.name));
        }
      }
      typesInScope.addAll(importedTypes);
    }
    return typesInScope;
  }

  DartType _futureType;

  /**
   * The type of the [Future] return type.
   */
  InterfaceType get futureType {
    if (_futureType == null) {
      var asyncLibrarySource = analysisContext.sourceFactory.forUri('dart:async');
      var asyncLibrary = analysisContext.computeLibraryElement(asyncLibrarySource);
      _futureType = asyncLibrary.getType('Future').type;
      if (_futureType == null) {
        throw 'Could not find Future interface';
      }
    }
    return _futureType;
  }

  DartType get dynamicType => new DynamicTypeImpl();

  DartType _contextType;

  /**
   * The type of the iris [Context] argument for procedures.
   */
  DartType get contextType {
    if (_contextType == null) {
      var remoteLibSource = analysisContext.sourceFactory.forUri('package:iris/remote/iris.dart');
      var remoteLib = analysisContext.computeLibraryElement(remoteLibSource);
      var unit = remoteLib.definingCompilationUnit.unit;
      _contextType = remoteLib.getType('Context').type;
    }
    return _contextType;
  }

  DartType _generatedMessageType;

  /**
   * The dart type of [GeneratedMessage].
   */
  DartType get generatedMessageType {
    if (_generatedMessageType == null) {
      var protobufLibrarySource = sourceFactory.forUri('package:protobuf/protobuf.dart');
      var protobufLibrary = analysisContext.computeLibraryElement(protobufLibrarySource);

      _generatedMessageType = protobufLibrary.getType('GeneratedMessage').type;
    }
    return _generatedMessageType;
  }
}

/**
 * Collect all subtypes of a particular type publicly exposed by a [LibraryElement].
 */
class SubtypeCollector extends ElementVisitor {

  final AnalysisContext analysisContext;
  final DartType rootType;

  List<InterfaceType> dartTypes;

  SubtypeCollector(this.analysisContext, this.rootType);

  collect(LibraryElement library) {
    dartTypes = <InterfaceType>[];
    visitLibraryElement(library);
    return dartTypes;
  }

  @override
  visitClassElement(ClassElement element) {
    if (element.type.isSubtypeOf(rootType) && element.type != rootType)
      dartTypes.add(element.type);
  }

  @override
  visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
  }

  @override
  visitExportElement(ExportElement element) {
    var subtypeCollector = new SubtypeCollector(analysisContext, rootType);
    var exportedSubtypes = subtypeCollector.collect(element.exportedLibrary);
    for (var combinator in element.combinators) {
      if (combinator is ShowElementCombinator) {
        exportedSubtypes = exportedSubtypes
            .where((subtype) =>  combinator.shownNames.contains(subtype.name));
      }
      if (combinator is HideElementCombinator) {
        exportedSubtypes = exportedSubtypes
            .where((subtype) => !combinator.hiddenNames.contains(subtype.name));
      }
    }
    dartTypes.addAll(exportedSubtypes);
  }

  @override
  visitLibraryElement(LibraryElement element) {
    element.visitChildren(this);
  }

  dynamic noSuchMethod(Invocation invocation) => null;
}

/**
 * A [UriResolver] for dart `package:` uris which requires a list of
 * absolutely specified library roots.
 */
class PackageResolver extends UriResolver {
  static const FILE_SCHEME = 'file://';

  static const PACKAGE_SCHEME = 'package';
  List<String> packageRootPaths;

  PackageResolver(this.packageRootPaths) {
    if (packageRootPaths.isEmpty) {
      throw 'Must supply at least one package root.';
    }
    if (!packageRootPaths.every(path.url.isAbsolute)) {
      throw 'Package roots must be specified as absolute paths';
    }
  }

  @override
  Source resolveAbsolute(Uri uri) {
    return packageMapUriResolver.resolveAbsolute(uri);
  }

  PackageMapUriResolver _packageMapUriResolver;

  PackageMapUriResolver get packageMapUriResolver {
    if (_packageMapUriResolver == null) {
      var resourceProvider = PhysicalResourceProvider.INSTANCE;
      var packageMap = <String,List<Folder>>{};
      for (var packageRootPath in packageRootPaths) {
        if (!packageRootPath.endsWith('/'))
          packageRootPath = '$packageRootPath/';
        if (packageRootPath.startsWith(FILE_SCHEME))
          packageRootPath = packageRootPath.substring(FILE_SCHEME.length);
        var packageRoot = resourceProvider.getResource(packageRootPath);
        if (packageRoot == null || packageRoot is! Folder)
          throw 'Invalid package root: $packageRoot';

        packageRoot.getChildren().where((child) => child is Folder).forEach((resource) {
          var packageName = resource.path.substring(packageRoot.path.length);
          packageMap.putIfAbsent(packageName, () => <Folder>[]);
          packageMap[packageName].add(resource);
        });
      }
      _packageMapUriResolver = new PackageMapUriResolver(resourceProvider, packageMap);
    }
    return _packageMapUriResolver;
  }
}
