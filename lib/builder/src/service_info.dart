library service_info;

import 'package:analyzer/src/generated/ast.dart';
import 'package:protoc_plugin/src/descriptor.pb.dart';

import 'source_crawler.dart';

class ServiceInfo {

  /// The service template was changed before this run of the builder
  static const TEMPLATE_CHANGED = 'template_changed';

  /// The service template was neither changed or removed before this run of the builder
  static const TEMPLATE_UNCHANGED = 'template_unchanged';

  /// The service template was not found in the declared file. This status may be
  /// caused because the service was not found in the declared protobuffer template,
  /// or because the file which defined the template does not exist.
  static const TEMPLATE_NOT_FOUND = 'template_not_found';

  /// The compilation unit which declares this service was unchanged
  static const COMPILATION_UNIT_UNCHANGED = 'compilation_unit_unchanged';

  /// The compilation unit which declares this service was changed
  static const COMPILATION_UNIT_CHANGED = 'compilation_unit_changed';

  /**
   * Crawl the dart source, starting at the specified [:entryPoint:], collecting
   * classes annotated with the `@IrisService` annotation.
   */
  static List<ServiceInfo> crawl(String entryPoint, List<String> packageRoots, [bool crawlPackages=false]) {
    var sourceCrawler = new SourceCrawler(packageRoots, crawlPackages);

    var infos = <ServiceInfo>[];

    visit(String libraryPath, String compilationUnitPath, CompilationUnit compilationUnit) {
      var classDeclarations = compilationUnit.declarations.where((decl) => decl is ClassDeclaration);

      for (var decl in classDeclarations) {
        var metadata = decl.metadata.where(isIrisServiceAnnotation);
        if (metadata.isEmpty) continue;
        var serviceInfo = new ServiceInfo()
            ..libraryPath = libraryPath
            ..compilationUnitPath = compilationUnitPath
            ..compilationUnit = compilationUnit
            ..classDeclaration = decl
            ..annotation = metadata.single;
        infos.add(serviceInfo);
      }
    }

    sourceCrawler.crawl(entryPoint, visit);
    return infos;
  }

  /// The path to the library which defines the service
  String libraryPath;

  /// The path to the part of the compilation unit which defines the service, or `null`
  /// if the service is defined in the compilation unit which declares the library.
  String compilationUnitPath;

  /// The compilation unit defining the service
  CompilationUnit compilationUnit;

  /// The class declaration annotated with `@IrisService`
  ClassDeclaration classDeclaration;

  /// The @IrisService annotation
  Annotation annotation;

  /// The protobuffer template if the template has been compiled and the
  /// template has been changed during the current run of the builder,
  /// otherwise `null`.
  ServiceDescriptorProto serviceDescriptor;

  /// The status of the compilation unit on this run of the builder, or `null` if the
  /// service has not yet been resolved
  var compilationUnitStatus;

  /// The status of the service template on this run of the builder, or `null` if the
  /// service has not been compiled.
  var templateStatus;


  /// `true` if `this` represents a compiled [ServiceInfo].
  bool get isCompiled => templateStatus != null;

  String _templatePath;

  /**
   * The path to the protobuffer file which
   * declares the service (specified relative
   * to the protobuffer root)
   */
  String get protobufferTemplatePath {
    if (_templatePath == null) {
      var visitor = new _DeclaredInVisitor();
      visitor.visitAnnotation(annotation);
      _templatePath = visitor.declaredInPath;
    }
    return _templatePath;
  }

  /// The name of the service is the same as the name of the class which
  /// defines the service.
  String get serviceName => classDeclaration.name.name;

  /// The procedures defined on the service template if the template has been
  /// compiled and the template has been changed during the current run of the
  /// builder, otherwise `null`.
  List<MethodDescriptorProto> get methodDescriptors =>
      (serviceDescriptor != null) ? serviceDescriptor.method : null;

  String toString() => 'ServiceInfo($serviceName)';
}

bool isIrisServiceAnnotation(Annotation annotation) {
  var name = annotation.name;
    if (name is PrefixedIdentifier) {
      name = name.identifier;
    }
    return name.name == 'IrisService';
}


/**
 * Visit an `IrisService` [Annotation] node and collect the first argument
 * as the location of the protobuffer template which defines the service.
 */
class _DeclaredInVisitor extends AstVisitor {
  String declaredInPath;

  int indentLevel = 0;

  void printNode(AstNode node) {
    var indent = 0;
    var msg = '  ' * indentLevel;
    msg += '${node.runtimeType}: $node';
    print(msg);
  }

  @override
  visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
    declaredInPath = node.stringValue;
  }

  @override
  visitAnnotation(Annotation node) => visitArgumentList(node.arguments);

  @override
  visitArgumentList(ArgumentList node) {
    node.visitChildren(this);
  }

  @override
  visitNamedExpression(NamedExpression node) {
    //A named argument. We only care about the (single) mandatory argument.
  }

  @override
  visitNullLiteral(NullLiteral node) {
    throw 'declaredIn cannot be `null`';
  }

  @override
  visitStringInterpolation(StringInterpolation node) {
    throw new UnsupportedError('`declaredIn` cannot use string interpolation');
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral node) {
    declaredInPath = node.stringValue;
  }

  dynamic noSuchMethod(Invocation invocation) {
    throw new UnsupportedError('${invocation.memberName}');
  }
}