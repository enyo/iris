
import 'package:logging/logging.dart';

import "remote_service_request_tests.dart" as requestTests;
import "service_definitions_tests.dart" as serviceDefinitionsTests;
import "server_tests.dart" as serverTests;
import "builder_tests.dart" as builderTests;
import "filter_tests.dart" as filterTests;
import "integration_tests.dart" as integrationTests;


main() {

//  Logger.root.level = Level.WARNING;
//  Logger.root.onRecord.listen((LogRecord record) => print('${record.loggerName} (${record.level}): ${record.message}'));

  requestTests.main();
  serviceDefinitionsTests.main();
  serverTests.main();
  builderTests.main();
  filterTests.main();
  integrationTests.main();

}