part of remote_services_builder;




class CompiledErrorCodes {


  Type errorCodes;

  ClassMirror reflectedCodes;

  String targetDirectory;

  CompiledErrorCodes(this.targetDirectory, this.errorCodes) {
    reflectedCodes = reflectType(errorCodes);
    if (!reflectedCodes.isSubtypeOf(reflectClass(RemoteServicesErrorCode))) {
      throw new BuilderException("Your ErrorCode class needs to implement the RemoteServicesErrorCode class. Please look at its documentation.");
    }
  }


  Future build() {
    return new File("${targetDirectory}/error_code.dart").writeAsString(compiledString);
  }


  String get compiledString {

//    VariableMirror x = reflectedCodes.declarations.values.first;

    var compiledString = "$generatedNotice";

    compiledString += """library remote_services_error_codes;

class ErrorCode {

  final int value;

  const ErrorCode._(this.value);

""";

    codes.forEach((String name, int code) {
      compiledString += "  static const $name = const ErrorCode._($code);\n\n";
    });

    compiledString += """
 
}

""";

    return compiledString;
  }


  Map<String, int> get codes {

    Map<String, int> codes = {};


    var reflectedRSErrorCode = reflectClass(RemoteServicesErrorCode);

    _filterCodeAttributes(reflectedRSErrorCode).forEach((k, v) {
      var keyName = MirrorSystem.getName(k);
      int codeNum = reflectedRSErrorCode.getField(k).reflectee.value;

      if (codes.values.contains(codeNum)) throw new BuilderException("Ooops. The library has an error and used the same code twice! Please contact the authors immediately.");

      codes[keyName] = codeNum;
    });


    _filterCodeAttributes(reflectedCodes).forEach((k, v) {
      var keyName = MirrorSystem.getName(k);
      int codeNum = reflectedCodes.getField(k).reflectee.value;

      if (keyName.startsWith("RS_")) throw new BuilderException("You can't define code names starting with 'RS_' ($keyName).");
      if (codes.containsKey(keyName)) throw new BuilderException("The code $keyName is already defined.");
      if (codes.values.contains(codeNum)) throw new BuilderException("You can't use the same code twice.");
      if (codeNum >= 900 && codeNum < 1000) throw new BuilderException("The code range 900...999 is reserved for internal use.");

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
