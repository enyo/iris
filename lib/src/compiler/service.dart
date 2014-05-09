part of remote_services_compiler;



String _lcFirst(String txt) => "${txt[0].toLowerCase()}${txt.substring(1)}";




class CompiledService {


  final String serviceName;

  String get fileName => "${_lcFirst(serviceName.replaceAllMapped(new RegExp("(.+)([A-Z])"), (match) => "${match.group(1)}_${match.group(2).toLowerCase()}"))}.dart";

  String get lowerCaseServiceName => _lcFirst(serviceName);

  List<ServiceRoute> routes = [];

  String targetDirectory;


  String relativePathToPbManifest;

  CompiledService(this.serviceName, this.targetDirectory, this.relativePathToPbManifest);




  /**
   * Compiles the manifest, and writes it to the target directory.
   */
  Future compile() {
    return new File("${targetDirectory}/$fileName").writeAsString(compiledString);
  }


  String get compiledString {
    var compiledString = "$generatedNotice";

    compiledString += """
library generated_${lowerCaseServiceName};

import "dart:async";
import "package:remote_services/client.dart";
import "${relativePathToPbManifest}";

class $serviceName extends Service {

  $serviceName(ServiceClient client) : super(client);

""";

    for (var route in routes) {
      compiledString += "  Future<${route.returnedType}> ${route.methodName}(${route.expectedRequestType} requestMessage) => client.query('${route.path}', requestMessage, ${route.returnedType.toString()});\n\n";
    }

    compiledString += "}\n\n";

    return compiledString;
  }


}


