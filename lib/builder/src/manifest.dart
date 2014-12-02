part of remotes_builder;



class CompiledManifest {


  List<CompiledRemote> compiledRemotes = [];

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


  CompiledRemote getOrCreateRemote(String remoteName) {
    return compiledRemotes.firstWhere((remote) => remote.remoteName == remoteName,
        orElse: () {
          var remote = new CompiledRemote(remoteName, targetDirectory, relativePathToPbManifest);
          compiledRemotes.add(remote);
          return remote;
        });
  }


  /**
   * Compiles the manifest and all its remotes, and writes it to the target directory.
   */
  Future build() {
    var futures = [];

    futures.add(new File("${targetDirectory}/$fileName").writeAsString(compiledString));

    for (var remote in compiledRemotes) {
      futures.add(remote.build());
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


  String _getCompiledGetterForRemote(CompiledRemote remote) {
    var remoteName = remote.remoteName,
        lowerCaseRemoteName = remote.lowerCaseRemoteName;

    var getter = "";
    getter += "  $remoteName _$lowerCaseRemoteName;\n";
    getter += "  $remoteName get $lowerCaseRemoteName => _$lowerCaseRemoteName == null ? _$lowerCaseRemoteName = new $remoteName(client) : _$lowerCaseRemoteName;\n";
    return getter;
  }


  String get compiledString {
    var compiledString = "$generatedNotice";

    compiledString += """library iris_manifest;

import "package:iris/client/client.dart";

""";

    for (var remote in compiledRemotes) {
      compiledString += """import "${remote.fileName}";\n""";
    }

    compiledString += """

class Remotes {

  IrisClient client;
  Remotes(this.client);

""";

    compiledString += compiledRemotes.map((remote) => _getCompiledGetterForRemote(remote)).toList().join("\n");

    compiledString += "\n}\n";

    return compiledString;
  }


}
