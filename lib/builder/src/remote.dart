part of remotes_builder;



String _lcFirst(String txt) => "${txt[0].toLowerCase()}${txt.substring(1)}";




class CompiledRemote {


  final String remoteName;

  String get fileName => "${_lcFirst(remoteName.replaceAllMapped(new RegExp("(.+)([A-Z])"), (match) => "${match.group(1)}_${match.group(2).toLowerCase()}"))}.dart";

  String get lowerCaseRemoteName => _lcFirst(remoteName);

  List<RemoteProcedure> procedures = [];

  String targetDirectory;


  String relativePathToPbManifest;

  CompiledRemote(this.remoteName, this.targetDirectory, this.relativePathToPbManifest);




  /**
   * Compiles the manifest, and writes it to the target directory.
   */
  Future build() {
    return new File("${targetDirectory}/$fileName").writeAsString(compiledString);
  }


  String get compiledString {
    var compiledString = "$generatedNotice";

    compiledString += """
library generated_${lowerCaseRemoteName};

import "dart:async";
import "package:iris/client/client.dart";
import "${relativePathToPbManifest}";

class $remoteName extends Remote {

  $remoteName(IrisClient client) : super(client);

""";

    for (var procedure in procedures) {
      compiledString += "  Future${procedure.responseType == null ? "" : "<${procedure.responseType}>"} ${procedure.methodName}(${procedure.expectedRequestType == null ? "" : procedure.expectedRequestType.toString() + " requestMessage"}) => client.dispatch('${procedure.path}', ${procedure.expectedRequestType == null ? "null" : "requestMessage"}, ${procedure.responseType == null ? 'null' : '(List<int> bytes) => new ${procedure.responseType.toString()}.fromBuffer(bytes)'}, ${procedure.expectedRequestType == null ? 'false' : 'true'});\n\n";
    }

    compiledString += "}\n\n";

    return compiledString;
  }


}


