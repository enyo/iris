library build_options;

import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:protoc_plugin/protoc_builder.dart';


class BuildOptions {
  /// The (absolute) path to the sdk directory
  String pathToSdk;

  /// The (absolute) path to the protoc compiler
  String pathToProtoc;

  /// The build args passed to the `build.dart`
  List<String> buildArgs;

  BuildArgs _parsedBuildArgs;

  BuildArgs get parsedBuildArgs {
    if (_parsedBuildArgs == null) {
      _parsedBuildArgs = BuildArgs.parse(buildArgs);
    }
    return _parsedBuildArgs;
  }

  /// The (absolute) path to the root of the project directory.
  String pathToProjectRoot;

  /// The path to the directory which contains the protobuffer templates,
  /// specified relative to the project root.
  String templateRoot;

  List<String> _packageRoots;

  List<String> get packageRoots {
    if (_packageRoots == null) {
      var rootDirectory = new Directory(pathToProjectRoot);
      _packageRoots = <String>[];
      bool hasPubspec(Directory dir) =>
          dir.listSync().any((f) => f.path.endsWith('pubspec.yaml'));

      if (hasPubspec(rootDirectory))
        _packageRoots.add(path.join(pathToProjectRoot, 'packages'));

      for (var dir in rootDirectory.listSync(recursive: true)) {
        if (dir is Directory && dir.listSync().any((f) => f.path.endsWith('pubspec.yaml'))) {
          _packageRoots.add(path.join(dir.absolute.path, 'packages'));
        }
      }
    }
    return _packageRoots;
  }

  /// An absolutely specified directory representing a physical location
  /// on the filesystem to output generated services and messages.
  String irisTarget;

  /// Maps directories which contain protobuffer templates (specified relative to the protobuffer root)
  /// to directories relative to the [:irisTarget:] project directory.
  Map<String,String> sourceMap;
}