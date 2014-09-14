library analysis_message;

import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source.dart';

import 'service_info.dart';

abstract class AnalysisMessage {
  final String message;

  /// The file which contains the compilation unit
  final String compilationUnitPath;

  /// The compilation unit which contains the code which
  /// generated the message.
  final CompilationUnit compilationUnit;
  final SourceRange sourceRange;

  String get method;

  AnalysisMessage(ServiceInfo serviceInfo, this.message, this.sourceRange):
    this.compilationUnit = serviceInfo.compilationUnit,
    this.compilationUnitPath = serviceInfo.compilationUnitPath;

  Map<String,dynamic> toJson() {

    var relFilePath = path.relative(
        compilationUnitPath,
        from: path.dirname(Platform.script.path)
    );

    var json = {
      'method': method,
      'params': {
        'message': 'iris: $message',
        'file': relFilePath,
      }
    };

    if (sourceRange != null) {
      var loc = compilationUnit.lineInfo.getLocation(sourceRange.offset);
      json['params']['line'] = loc.lineNumber;
      json['params']['charStart'] = sourceRange.offset;
      json['params']['charEnd'] = sourceRange.offset + sourceRange.length;
    }

    return json;
  }

  //TODO: toString should print line information.
  toString() => 'iris: $message';
}

class AnalysisError extends AnalysisMessage {

  @override
  String get method => 'error';

  AnalysisError(
      ServiceInfo serviceInfo,
      String message,
      SourceRange sourceRange
  ): super(serviceInfo, message, sourceRange);
}

class AnalysisWarning extends AnalysisMessage {

  @override
  String get method => 'warning';

  AnalysisWarning(
      ServiceInfo serviceInfo,
      String message,
      SourceRange sourceRange
  ): super(serviceInfo, message, sourceRange);
}