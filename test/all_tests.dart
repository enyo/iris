
import 'package:logging/logging.dart';

import "remote_service_request_tests.dart" as requestTests;


main() {

  Logger.root.level = Level.FINEST;
  Logger.root.onRecord.listen((LogRecord record) => print('${record.loggerName} (${record.level}): ${record.message}'));

  requestTests.main();

}