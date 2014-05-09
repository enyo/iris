part of remote_services_compiler;



class CompiledManifest {


  List<CompiledService> compiledServices = [];

  Directory targetDirectory;

  String fileName;

  File pbMessagesManifest;

  String get relativePathToPbManifest {
    if (includePbMessages) {
      return "proto/${getFilename(pbMessagesManifest)}";
    }
    else {
      return getRelativePath(targetDirectory, pbMessagesManifest);
    }
  }

  /// Whether the protocol buffer messages should be copied over as well
  bool includePbMessages;

  CompiledManifest(this.targetDirectory, this.pbMessagesManifest, {this.includePbMessages, this.fileName});


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
  Future compile() {
    var futures = [];

    futures.add(new File("${targetDirectory.path}$fileName").writeAsString(compiledString));

    for (var service in compiledServices) {
      futures.add(service.compile());
    }

    if (includePbMessages) {
      // Copy all protocol buffer messages over
      var protoDir = new Directory("${targetDirectory.path}proto");

      futures.add(protoDir.exists()
          .then((exists) {
            if (!exists) {
              return protoDir.create();
            }
          })
          .then((_) => pbMessagesManifest.parent.list(recursive: false).where((FileSystemEntity file) => file is File && file.path.endsWith(".dart")).toList())
          .then((List<File> files) {
            List<Future> copyFutures = files.map((file) => file.copy("${protoDir.path}/${getFilename(file)}")).toList();
            return Future.wait(copyFutures);
          })
      );
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
