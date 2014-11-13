library remote_services_builder;

import "dart:io";
import "dart:mirrors";
import "package:logging/logging.dart";

import "package:path/path.dart" as path;

import '../remote/iris.dart';

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
 * Returns a [BuildArgs] object for given arguments.
 */
BuildArgs getBuildArgs(List<String> args, String pbMessagesManifest, {String servicesDirectory}) {
  if (args == null) {
    log.warning("No build arguments provided. Defaulting to `--full`");
    args = ['--full'];
  }

  var buildArgs = new BuildArgs(args, directoriesToWatch: [ path.dirname(pbMessagesManifest), servicesDirectory ]);

  return buildArgs;
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
Future build(Iris serviceDefinitions, String targetDirectory, String pbMessagesManifest, {List<String> args, bool includePbMessages: false, String servicesFileName: "services.dart", String servicesDirectory, Type errorCodes}) {
  log.info("Running iris compiler");
  log.info("Writing compiled services to: $targetDirectory");
  log.info("protobuffer Manifset: $pbMessagesManifest");

  if (args == null) {
    log.warning("No build arguments provided. Defaulting to `--full`");
    args = ['--full'];
  }

  var buildArgs = getBuildArgs(args, pbMessagesManifest, servicesDirectory: servicesDirectory);

  return _async.then((_) {
    if (buildArgs.clean) return cleanTargetDirectory(targetDirectory);
  }).then((_) {
    if (buildArgs.requiresBuild) {
      log.info("Found changed or deleted files or --full flag was passed. Building remote services now.");

      var targetDir = new Directory(targetDirectory);

      return targetDir.exists()
          .then((exists) {
            if (!exists) return targetDir.create();
          })
          .then((_) {
              log.info("Building iris services");
              var compiledManifest = new CompiledManifest(targetDirectory, pbMessagesManifest, includePbMessages: includePbMessages, fileName: servicesFileName, errorCodes: errorCodes);

              for (var procedure in serviceDefinitions.procedures) {
                compiledManifest.getOrCreateService(procedure.serviceName).procedures.add(procedure);
              }

              return compiledManifest.build();
          })
          .then((_) => log.info("Iris compilation successful"));

    }
  });

}

Future cleanTargetDirectory(String targetDirectory) {
  Directory dir = new Directory(targetDirectory);
  log.info("Cleaning target directory");
  return dir.exists().then((exists) {
    if (exists) {
      return dir.delete(recursive: true);
    }
  });
}

final _async = new Future.value();



