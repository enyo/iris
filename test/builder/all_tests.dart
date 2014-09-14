library builder.all_tests;

import 'method_analyzer_test.dart' as methodAnalyzer;
import 'package_visitor_test.dart' as packageVisitor;
import 'source_crawler_test.dart' as sourceCrawler;

void main() {
  methodAnalyzer.main();
  packageVisitor.main();
  sourceCrawler.main();
}