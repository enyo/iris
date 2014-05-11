part of remote_services_builder;



String _lcFirst(String txt) => "${txt[0].toLowerCase()}${txt.substring(1)}";




class CompiledService {


  final String serviceName;

  String get fileName => "${_lcFirst(serviceName.replaceAllMapped(new RegExp("(.+)([A-Z])"), (match) => "${match.group(1)}_${match.group(2).toLowerCase()}"))}.dart";

  String get lowerCaseServiceName => _lcFirst(serviceName);

  List<ServiceProcedure> procedures = [];

  String targetDirectory;


  String relativePathToPbManifest;

  CompiledService(this.serviceName, this.targetDirectory, this.relativePathToPbManifest);




  /**
   * Compiles the manifest, and writes it to the target directory.
   */
  Future build() {
    return new File("${targetDirectory}/$fileName").writeAsString(compiledString);
  }


  String get compiledString {
    var compiledString = "$generatedNotice";

    compiledString += """
library generated_${lowerCaseServiceName};

import "dart:async";
import "package:remote_services/client/client.dart";
import "${relativePathToPbManifest}";

class $serviceName extends Service {

  $serviceName(ServiceClient client) : super(client);

""";

    for (var procedure in procedures) {
      compiledString += "  Future${procedure.responseType == null ? "" : "<${procedure.responseType}>"} ${procedure.methodName}(${procedure.expectedRequestType == null ? "" : procedure.expectedRequestType.toString() + " requestMessage"}) => client.dispatch('${procedure.path}', ${procedure.expectedRequestType == null ? "null" : "requestMessage"}, ${procedure.responseType.toString()}, ${procedure.expectedRequestType == null ? 'false' : 'true'});\n\n";
    }

    compiledString += "}\n\n";

    return compiledString;
  }


}


