part of remote_services_compiler;


final Pattern _REMOVED_PATTERN = new RegExp(r'--removed=(.*\.dart)$');
final Pattern _CHANGED_PATTERN = new RegExp(r'--changed=(.*\.dart)$');



class _BuildArgs {

  final Set<String> removed = new Set<String>();

  final Set<String> changed = new Set<String>();

  bool clean = false;

  bool full = false;

  bool machineOut = false;


  List<String> directoriesToWatch;


  _BuildArgs(List<String> args, {this.directoriesToWatch: const []}) {

    if (args.any((arg) => arg.startsWith('--machine')))
      machineOut = true;

    if (args.any((arg) => arg.startsWith('--full'))) {
      clean = full = true;
      return;
    }

    if (args.any((arg) => arg.startsWith('--clean'))) {
      clean = true;
      return;
    }

    for (var arg in args) {
      Match match;
      String file;
      if ((match = _CHANGED_PATTERN.matchAsPrefix(arg)) != null) {
        file = match.group(1);
        if (directoriesToWatch.any((dir) => dir != null && path.isWithin(dir, file))) {
          log.finest("Found changed file $file.");
          changed.add(file);
        }
      }
      else if ((match = _REMOVED_PATTERN.matchAsPrefix(arg)) != null) {
        file = match.group(1);
        if (directoriesToWatch.any((dir) => dir != null && path.isWithin(dir, file))) {
          log.finest("Found deleted file $file.");
          removed.add(file);
        }
      }
    }

  }
}
