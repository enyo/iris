library error_code_compiler;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import '../../remote/error_code.dart';

/// Added to every generated file.
String generatedNotice = """///
// Generated file. Do not edit.
///
""";

class CompiledErrorCodes {
  //TODO (ovangle): should be rewritten to use the analyzer.


  Type errorCodes;

  ClassMirror reflectedCodes;

  String targetDirectory;

  CompiledErrorCodes(this.targetDirectory, this.errorCodes) {
    reflectedCodes = reflectType(errorCodes);
    if (!reflectedCodes.isSubtypeOf(reflectClass(IrisErrorCode))) {
      throw "Your ErrorCode class needs to implement the RemoteServicesErrorCode class. Please look at its documentation.";
    }
  }


  Future build() {
    return new File("${targetDirectory}/error_code.dart").writeAsString(compiledString);
  }


  String get compiledString {

//    VariableMirror x = reflectedCodes.declarations.values.first;

    var compiledString = "$generatedNotice";

    compiledString += """library iris_error_codes;

class ErrorCode {

""";

    codes.forEach((String name, int code) {
      compiledString += "  static const $name = $code;\n\n";
    });

    compiledString += """
 
}

""";

    return compiledString;
  }


  Map<String, int> get codes {

    Map<String, int> codes = {};


    var reflectedRSErrorCode = reflectClass(IrisErrorCode);

    _filterCodeAttributes(reflectedRSErrorCode).forEach((k, v) {
      var keyName = MirrorSystem.getName(k);
      int codeNum = reflectedRSErrorCode.getField(k).reflectee.value;

      if (codes.values.contains(codeNum))
        throw "Cannot use the same error code ($codeNum) twice";

      codes[keyName] = codeNum;
    });


    _filterCodeAttributes(reflectedCodes).forEach((k, v) {
      var keyName = MirrorSystem.getName(k);
      int codeNum = reflectedCodes.getField(k).reflectee.value;

      if (keyName.startsWith("IRIS_"))
        throw "Invalid field name '${keyName}'. Error codes cannot begin with 'IRIS_'";
      if (codes.containsKey(keyName))
        throw "The code $keyName is already defined.";
      if (codes.values.contains(codeNum))
        throw "Code number $codeNum cannot be used twice";
      if (codeNum >= 900 && codeNum < 1000)
        throw "The code range 900...999 is reserved for internal use.";

      codes[keyName] = codeNum;
    });

    return codes;
  }


  Map<Symbol, DeclarationMirror> _filterCodeAttributes(ClassMirror clazz) {
    var map = new Map<Symbol, DeclarationMirror>();

    clazz.declarations.forEach((k, v) {
      if (v is VariableMirror && v.isStatic) {
        map[k] = v;
      }
    });

    return map;

  }

}
