
import 'package:logging/logging.dart';

import "iris_request_tests.dart" as requestTests;
import "iris_tests.dart" as serviceDefinitionsTests;
import "server_tests.dart" as serverTests;
import 'builder/all_tests.dart' as builderTests;
import "filter_tests.dart" as filterTests;
import "integration_tests.dart" as integrationTests;


main() {

//  Logger.root.level = Level.WARNING;
//  Logger.root.onRecord.listen((LogRecord record) => print('${record.loggerName} (${record.level}): ${record.message}'));

  requestTests.main();
  serviceDefinitionsTests.main();
  builderTests.main();
  serverTests.main();
  filterTests.main();
  integrationTests.main();

}