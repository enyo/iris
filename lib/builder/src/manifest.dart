part of remote_services_builder;



class CompiledManifest {


  List<CompiledService> compiledServices = [];

  String targetDirectory;

  String fileName;

  String pbMessagesManifest;

  String get relativePathToPbManifest {
    if (includePbMessages) {
      return "proto/${path.basename(pbMessagesManifest)}";
    }
    else {
      return path.relative(pbMessagesManifest, from: targetDirectory);
    }
  }

  /// Whether the protocol buffer messages should be copied over as well
  bool includePbMessages;

  Type errorCodes;

  CompiledManifest(this.targetDirectory, this.pbMessagesManifest, {this.includePbMessages, this.fileName, this.errorCodes});


  CompiledService getOrCreateService(String serviceName) {
    return compiledServices.firstWhere((service) => service.serviceName == serviceName,
        orElse: () {
          var service = new CompiledService(serviceName, targetDirectory, relativePathToPbManifest);
          compiledServices.add(service);
          return service;
        });
  }


  /**
   * Compiles the manifest and all its services, and writes it to the target directory.
   */
  Future build() {
    var futures = [];

    futures.add(new File("${targetDirectory}/$fileName").writeAsString(compiledString));

    for (var service in compiledServices) {
      futures.add(service.build());
    }

    if (includePbMessages) {
      // Copy all protocol buffer messages over
      var protoDir = new Directory("${targetDirectory}/proto");

      futures.add(protoDir.exists()
          .then((exists) {
            if (!exists) {
              return protoDir.create();
            }
          })
          .then((_) => new Directory(path.dirname(pbMessagesManifest)).list(recursive: false).where((FileSystemEntity file) => file is File && file.path.endsWith(".dart")).toList())
          .then((List<File> files) {
            List<Future> copyFutures = files.map((file) => file.copy("${protoDir.path}/${path.basename(file.path)}")).toList();
            return Future.wait(copyFutures);
          })
      );
    }

    if (errorCodes != null) {
      futures.add(new CompiledErrorCodes(targetDirectory, errorCodes).build());
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

import "package:remote_services/client/client.dart";

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
