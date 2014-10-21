library imports;

//Qualified import
import 'test_service.pb.dart' as services;

// Show combinator
import 'package:protoc_plugin/src/descriptor.pb.dart' show DescriptorProto;

// Hide combinator
import 'package:protoc_plugin/src/plugin.pb.dart' hide CodeGeneratorResponse_File;
