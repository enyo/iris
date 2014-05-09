part of remote_services_compiler;



/**
 * Removes all `..` occurences.
 */
String resolvePath(String path) {
  while (path.contains("/..")) {
    path = path.replaceAll(new RegExp(r"\/[^\/]+\/\.\."), "");
  }
  return path;
}


String getFilename(File file) => file.path.split("/").last;

/**
 * Returns the relative path to a specific file.
 */
String getRelativePath(Directory dir, File file) {

  var fileName = file.path.split("/").last;
  var dirPath = resolvePath(dir.absolute.path);
  var filePath = resolvePath(file.parent.absolute.path);

  dirPath = dirPath.replaceAll(new RegExp(r"\/*$"), "");
  filePath = filePath.replaceAll(new RegExp(r"\/*$"), "");


  var dirSplits = dirPath.split("/");
  var fileSplits = filePath.split("/");

  var sharedDirs = 0;
  for (sharedDirs = 0; sharedDirs < dirSplits.length; sharedDirs++) {
    if (fileSplits[sharedDirs] != dirSplits[sharedDirs]) {
      break;
    }
  }
  sharedDirs--;

  var relativePath = "";

  for (var i = 0; i < dirSplits.length - sharedDirs - 1; i++) {
    relativePath += "../";
  }

  for (var i = sharedDirs + 1; i < fileSplits.length; i++) {
    relativePath += "${fileSplits[i]}/";
  }

  return relativePath + fileName;
}


