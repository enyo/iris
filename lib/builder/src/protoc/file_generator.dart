part of service_compiler;


class FileGenerator extends protoc.FileGenerator {
  FileDescriptorProto fileDescriptor;
  protoc.GenerationContext context;

  List<ServiceGenerator> serviceGenerators = <ServiceGenerator>[];

  FileGenerator(
      FileDescriptorProto fileDescriptor,
      protoc.ProtobufContainer parent,
      protoc.GenerationContext context
  ): super(fileDescriptor, parent, context),
     this.fileDescriptor = fileDescriptor,
     this.context = context {
    for (ServiceDescriptorProto service in fileDescriptor.service) {
      serviceGenerators.add(new ServiceGenerator(service, this, context));
    }
  }

  // Extract the filename from a URI and remove the extension.
  String _fileNameWithoutExtension(Uri filePath) {
    String fileName = filePath.pathSegments.last;
    int index = fileName.lastIndexOf(".");
    return index == -1 ? fileName : fileName.substring(0, index);
  }

  String _generateClassName(Uri protoFilePath) {
    String s = _fileNameWithoutExtension(protoFilePath).replaceAll('-', '_');
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  String _generateLibraryName(Uri protoFilePath) {
    if (fileDescriptor.package != '') return fileDescriptor.package;
    return 'generated_' + _fileNameWithoutExtension(protoFilePath).replaceAll('-', '_');
  }

  // TODO (ovangle): This should be more easy to override than
  // just copying the impl.
  // Should submit a PR which exposes an (optional) factory for services.
  @override
  void generate(protoc.IndentingWriter out) {
    Uri filePath = new Uri.file(fileDescriptor.name);
    if (filePath.isAbsolute)
      throw('FAILURE: File with an absolute path is not supported');

    String libraryName = _generateLibraryName(filePath);

    out.println(
        '///\n'
        '//  Generated code. Do not modify.\n'
        '///\n'
        'library $libraryName;\n'
        '\n'
        "import 'dart:async';"
        '\n'
        "import 'package:fixnum/fixnum.dart';\n"
        "import 'package:iris/client/client.dart';\n"
        "import 'package:protobuf/protobuf.dart';\n"
    );

    for (var import in fileDescriptor.dependency) {
      Uri importPath = new Uri.file(import);
      if (importPath.isAbsolute) {
        throw("FAILURE: Import with absolute path is not supported");
      }
      // Create a path from the current file to the imported proto.
      Uri resolvedImport = context.outputConfiguration.resolveImport(
          importPath, filePath);
      // Find the file generator for this import as it contains the
      // package name.
      FileGenerator fileGenerator = context.lookupFile(import);
      out.print("import '$resolvedImport'");
      if (package != fileGenerator.package && !fileGenerator.package.isEmpty) {
        out.print(' as ${fileGenerator.packageImportPrefix}');
      }
      out.println(';');
    }
    out.println();

    // Initialize field
    for (var m in messageGenerators) {
      m.initializeFields();
    }

    // Initialize methods
    for (var s in serviceGenerators) {
      s.initializeMethods();
    }

    // Generate code
    for (var s in serviceGenerators) {
      s.generate(out);
    }

    for (var m in messageGenerators) {
      m.generate(out);
    }

    for (var e in enumGenerators) {
      e.generate(out);
    }

    if (!extensionGenerators.isEmpty) {
      // TODO(antonm): do not generate a class.
      String className = _generateClassName(filePath);
      out.addBlock('class $className {', '}\n', () {
        for (var x in extensionGenerators) {
          x.generate(out);
        }
        out.print('static void registerAllExtensions(ExtensionRegistry registry)');
        out.addBlock('{', '}', () {
          for (var x in extensionGenerators) {
             out.println('  registry.add(${x.name});');
           }
        });
      });
    }
  }
}