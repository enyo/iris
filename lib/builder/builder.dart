library remote_services_builder;

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:quiver/async.dart';

import 'src/analysis_message.dart';
import 'src/service_analyzer.dart';
import 'src/service_compiler.dart';
import 'build_options.dart';
import 'src/service_info.dart';

import 'src/error_codes.dart';



/**
 * Analyze the services.
 * [:entryPoint:] is a list of absolutely specified paths to libraries
 * which contain service definitions.
 *
 * [:pathToSdk:] is the path to the dart sdk on the filesystem.
 *
 * [:pathToProjectRoot:] is an abolutely specified path to the root of the
 * project. If not specified, it will be inferred from the most specific
 * ancestor of the directory which contains the running script
 *
 * [:protoRoot:] is the directory (specified relative to the project root)
 * which contains the protobuffer definitions.
 *
 * [:pathToProtoc:] is the path to the protoc compiler executable. If not
 * provided, will search the user's $PATH to locate the executable.
 */
Future build({
    String irisTarget,
    Map<String,String> sourceMap: const <String,String>{'.': 'lib/proto'},
    List<String> entryPoints,
    String pathToSdk,
    String pathToProjectRoot,
    String pathToProtoc,
    String templateRoot: 'proto',
    List<String> buildArgs: const ['--full']
}) {
  if (pathToSdk == null) {
    throw 'A SDK directory must be provided';
  }
  if (pathToProjectRoot == null) {
    pathToProjectRoot = _inferProjectRootDirectory();
    //print('PROJECT ROOT: $pathToProjectRoot');
  }
  if (irisTarget == null)
    throw 'An iris target directory must be specified';

  if (pathToProtoc == null) {
    pathToProtoc = _getProtocFromPath();
    if (pathToProtoc == null) {
      throw "'protoc' exutable not found on user's \$PATH";
    }
  }



  var buildOptions = new BuildOptions()
      ..irisTarget = irisTarget
      ..pathToSdk = pathToSdk
      ..pathToProtoc = pathToProtoc
      ..pathToProjectRoot = pathToProjectRoot
      ..sourceMap = sourceMap
      ..templateRoot = templateRoot
      ..buildArgs = buildArgs;

  var serviceCompiler = new ServiceCompiler(buildOptions);
  var serviceAnalyzer = new ServiceAnalyzer.withOptions(buildOptions);

  return forEachAsync(
      entryPoints,
      (entryPoint) => _buildEntryPoint(entryPoint, serviceCompiler, serviceAnalyzer, buildOptions)
  ).then((_) {
    return serviceCompiler.build();
  });
}

Future _buildEntryPoint(String entryPoint, ServiceCompiler compiler, ServiceAnalyzer analyzer, BuildOptions buildOptions) {
  // Crawl the source for classes annotated with @IrisService annotations.
  // Package directories are not scanned (should be included as separate entry points
  // if necessary).
  var serviceInfos = ServiceInfo.crawl(entryPoint, buildOptions.packageRoots, false);
  print('Number of services found: $serviceInfos');

  List<ServiceInfo> analyzedInfos = <ServiceInfo>[];

  return forEachAsync(serviceInfos, (serviceInfo) {
    return compiler.resolve(serviceInfo).then((serviceInfo) {
      if (!analyzer.requiresAnalysis(serviceInfo)) {
        return;
      }
      analyzedInfos.add(serviceInfo);

      var messages = analyzer.analyze(serviceInfo);
      if (messages.isNotEmpty) {
        messages.forEach((msg) => printAnalysisMessage(msg, buildOptions));
      }
    });
  });
}

/**
 * Build the error codes defined in type type [:errorCodeType:] and
 * output the resulting enum to the directory [:irisTarget:] as `error_codes.dart`.
 */
Future buildErrorCodes({
  String irisTarget,
  Type errorCodeType
}) {
  //TODO (ovangle): This should be rewritten to use the analyzer, so that
  // no libraries need to be imported by the builder.
  // For the moment, just include it as a separate build step.

  var compiler = new CompiledErrorCodes(irisTarget, errorCodeType);
  return compiler.build();
}

void printAnalysisMessage(AnalysisMessage analysisMessage, BuildOptions buildOptions) {
  print(analysisMessage);
  var json = analysisMessage.toJson();
  print('');
  print('[${JSON.encode(json)}]');
  print('');
}


String _inferProjectRootDirectory() {
  var dir = new Directory(path.dirname('$Platform.script.path'));
  while (!dir.listSync().any((f) => f.path.endsWith('pubspec.yaml'))) {
    dir = dir.parent;
  }
  return path.normalize(dir.absolute.path);
}

String _getProtocFromPath() {
  var sysPath = Platform.environment['PATH'].split(':');
  return sysPath.fold(null, (exec, pathElem) {
    if (exec != null) return exec;
    var dir = new Directory(pathElem);
    return dir.listSync().firstWhere(
        (f) => path.basename(f.path) == 'protoc',
        orElse: () => null
    );
  });
}