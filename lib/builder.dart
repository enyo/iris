library remote_services_compiler;

import "dart:io";
import "remote_services.dart";

part "src/compiler/utils.dart";
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
 *
 * [includePbMessages] defines whether you want all protocol buffer messages to
 * be copied over to the target directory as well. This is useful if you want
 * to make your remote services public but not the whole server.
 */
Future build(ServiceDefinitions serviceDefinitions, Directory targetDirectory, File pbMessagesManifest, List<String> args, {bool includePbMessages: false, String servicesFileName: "services.dart"}) {

  var compiledManifest = new CompiledManifest(targetDirectory, pbMessagesManifest, includePbMessages: includePbMessages, fileName: servicesFileName);

  for (var route in serviceDefinitions.routes) {
    compiledManifest.getOrCreateService(route.serviceName).routes.add(route);
  }

  return compiledManifest.compile();

}



