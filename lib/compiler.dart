library remote_services_compiler;

import "dart:io";
import "remote_services.dart";

part "src/compiler/manifest.dart";
part "src/compiler/service.dart";


/// Added to every generated file.
String generatedNotice = """///
/// Generated file. Do not edit.
///
""";



/**
 * Compile the remote services to be used by the client.
 *
 * The [targetDirectory] defines where to put the compiled files.
 *
 * The [pbMessagesManifest] defines where the protocol buffer messages manifest
 * file ist located. This is relative to the [targetDirectory].
 */
compile(ServiceDefinitions serviceDefinitions, Directory targetDirectory, String pbMessagesManifest, {String servicesFileName: "services.dart"}) {

  var compiledManifest = new CompiledManifest(targetDirectory, pbMessagesManifest, fileName: servicesFileName);

  for (var route in serviceDefinitions.routes) {
    compiledManifest.getOrCreateService(route.serviceName).routes.add(route);
  }

  compiledManifest.compile();
  print(compiledManifest.compiledString);

}



