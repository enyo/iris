library remote_services_builder;

import "dart:io";
import "dart:mirrors";
import "package:logging/logging.dart";

import "package:path/path.dart" as path;

import '../remote/remote_services.dart';

import '../remote/error_code.dart';

part 'src/utils.dart';
part 'src/manifest.dart';
part 'src/service.dart';
part 'src/build_args.dart';
part 'src/error_codes.dart';


/// Added to every generated file.
String generatedNotice = """///
/// Generated file. Do not edit.
///
""";


Logger log = new Logger("RemoteServicesBuilder");


/**
 * Thrown when there was a problemen with the services definition.
 */
class BuilderException implements Exception {

  String message;

  BuilderException(this.message);


  String toString() => "BuilderException: $message";

}


/**
 * Compile the remote services to be used by the client.
 *
 * **If you put this function in the `build.dart` file then you need to pass
 * the [args] parameter!** Otherwise those files will be rebuilt every time
 * *any* file in the project changes which can potentially end up in an infinite
 * loop.
 * You will porbably also set the [servicesDirectory] which tells the builder
 * where to look for changes.
 * The protocol buffer messages directory is only watched if [includePbMessages]
 * is true (since otherwise the lib doesn't need to rebuild).
 *
 *
 * The [targetDirectory] defines where to put the compiled files.
 *
 * The [pbMessagesManifest] defines where the protocol buffer messages manifest
 * file ist located. This is relative to the [targetDirectory].
 *
 * [includePbMessages] defines whether you want all protocol buffer messages to
 * be copied over to the target directory as well. This is useful if you want
 * to make your remote services public but not the whole server.
 *
 * Setting [errorCodes] creates a `error_code.dart` file that the client can
 * import to handle error codes properly.
 *
 * If [args] are provided, then it will be looked for "--changed" and "--removed"
 * arguments, and the build will only be done dependent on that information.
 */
Future build(ServiceDefinitions serviceDefinitions, String targetDirectory, String pbMessagesManifest, {List<String> args, bool includePbMessages: false, String servicesFileName: "services.dart", String servicesDirectory, Type errorCodes}) {

  var doBuild = false;

  if (args != null) {
    var argsBuilder = new _BuildArgs(args, directoriesToWatch: [ path.dirname(pbMessagesManifest), servicesDirectory ]);
    if (!argsBuilder.changed.isEmpty || !argsBuilder.removed.isEmpty) {
      log.info("Found changed or deleted files. Building remote services now.");
      doBuild = true;
    }
  }

  if (doBuild) {

    var targetDir = new Directory(targetDirectory);

    return targetDir.exists()
        .then((exists) {
          if (!exists) return targetDir.create();
        })
        .then((_) {
            var compiledManifest = new CompiledManifest(targetDirectory, pbMessagesManifest, includePbMessages: includePbMessages, fileName: servicesFileName, errorCodes: errorCodes);

            for (var procedure in serviceDefinitions.procedures) {
              compiledManifest.getOrCreateService(procedure.serviceName).procedures.add(procedure);
            }

            return compiledManifest.build();
        });

  }
  else {
    return new Future.value();
  }

}



