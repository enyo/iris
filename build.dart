import 'package:protoc_plugin/protoc_builder.dart';

void main(List<String> args) {
  args = ['--full'];
  // build the test protobuffers
  var testProtoSourceMap = {'.': 'test/protos'};
  buildMapped(testProtoSourceMap, buildArgs: args, templateRoot: 'test');
}