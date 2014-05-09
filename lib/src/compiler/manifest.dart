part of remote_services_compiler;


class CompiledManifest {


  List<CompiledService> compiledServices = [];

  Directory targetDirectory;

  String fileName;

  /// TODO: turn this into a [File] class.
  String pbMessagesManifest;

  String get relativePathToPbManifest => pbMessagesManifest;

  CompiledManifest(this.targetDirectory, this.pbMessagesManifest, {this.fileName});


  CompiledService getOrCreateService(String serviceName) {
    return compiledServices.firstWhere((service) => service.serviceName == serviceName,
        orElse: () {
          var service = new CompiledService(serviceName, targetDirectory, pbMessagesManifest);
          compiledServices.add(service);
          return service;
        });
  }


  /**
   * Compiles the manifest and all its services, and writes it to the target directory.
   */
  Future compile() {
    var futures = [];

    futures.add(new File("${targetDirectory.path}$fileName").writeAsString(compiledString));

    for (var service in compiledServices) {
      futures.add(service.compile());
    }

    return Future.wait(futures);
  }


  String _getCompiledGetterForService(CompiledService service) {
    var serviceName = service.serviceName,
        lowerCaseServiceName = service.lowerCaseServiceName;

    var getter = "";
    getter += "  $serviceName _$lowerCaseServiceName;\n";
    getter += "  $serviceName get $lowerCaseServiceName => _$lowerCaseServiceName == null ? _$lowerCaseServiceName = new $serviceName(client) : _$lowerCaseServiceName;\n";
    return getter;
  }


  String get compiledString {
    var compiledString = "$generatedNotice";

    compiledString += """library remote_services_manifest;

import "package:remote_services/client.dart";

""";

    for (var service in compiledServices) {
      compiledString += """import "${service.fileName}";\n""";
    }

    compiledString += """

class Services {

  ServiceClient client;
  Services(this.client);

""";

    compiledString += compiledServices.map((service) => _getCompiledGetterForService(service)).toList().join("\n");

    compiledString += "\n}\n";

    return compiledString;
  }


}
