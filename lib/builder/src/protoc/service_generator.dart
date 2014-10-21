part of service_compiler;

class ServiceGenerator extends protoc.ProtobufContainer {
  final ServiceDescriptorProto _descriptor;
  final protoc.ProtobufContainer _parent;
  final protoc.GenerationContext _context;

  final String classname;
  final String fqname;
  List<ProtobufMethod> _methodList = <ProtobufMethod>[];

  ServiceGenerator(
      ServiceDescriptorProto descriptor, protoc.ProtobufContainer parent, protoc.GenerationContext this._context)
      : _descriptor = descriptor,
        _parent = parent,
        classname = (parent.classname == '') ?
              descriptor.name: '${parent.classname}_${descriptor.name}',
        fqname = (parent == null || parent.fqname == null) ? descriptor.name:
          (parent.fqname == '.' ?
              '.${descriptor.name}' : '${parent.fqname}.${descriptor.name}') {
    _context.register(this);
  }

  String get package => _parent.package;

  void initializeMethods() {
    _methodList.clear();
    for (var method in _descriptor.method) {
      _methodList.add(new ProtobufMethod(method, this, _context));
    }
  }

  void generate(protoc.IndentingWriter writer) {
      writer.print('class ${classname} extends Service ');
      writer.addBlock('{', '}', () {
        writer.println();
        writer.println('${classname}(IrisClient client): super(client);');
        writer.println();

        for (var method in _methodList) {
          generateMethod(method, writer);
        }
      });
    }

  void generateMethod(ProtobufMethod method, protoc.IndentingWriter writer) {
    writer.print('Future<');
    writer.print(method.prefixedOutputType);
    writer.print('> ');

    writer.print(method.name);

    writer.print('(');
    writer.print(method.prefixedInputType);
    writer.print(' request)');

    writer.addBlock('{', '}', () {
      writer.println('return client.dispatch(');
      writer.println('    \'' + getProcedurePath(method) + '\',');
      writer.println('    request,');
      writer.println('    (List<int> bytes) => new ${method.prefixedOutputType}.fromBuffer(bytes)');
      writer.println(');');
    });

    writer.println();
  }

  String getProcedurePath(ProtobufMethod method) {
    return '/${_descriptor.name}.${method.name}';
  }
}

class ProtobufMethod {
  final MethodDescriptorProto _descriptor;
  final protoc.ProtobufContainer parent;
  final protoc.GenerationContext context;

  final protoc.ProtobufContainer inputType;
  final protoc.ProtobufContainer outputType;

  ProtobufMethod._(this._descriptor, this.parent, this.context, this.inputType, this.outputType);

  factory ProtobufMethod(MethodDescriptorProto descriptor, protoc.ProtobufContainer parent, protoc.GenerationContext context) {
    var inputMessageType = context[descriptor.inputType];
    if (inputMessageType == null)
      throw 'FAILURE: Unknown type reference: ${descriptor.inputType}';
    var outputMessageType = context[descriptor.outputType];
    if (outputMessageType == null)
      throw 'FAILURE: Unknown type reference: ${descriptor.outputType}';
    return new ProtobufMethod._(descriptor, parent, context, inputMessageType, outputMessageType);
  }

  String get name => _descriptor.name;

  String get inputTypePackage => inputType.package;
  String get prefixedInputType {
    if (inputType.packageImportPrefix.isNotEmpty) {
      return '${inputType.packageImportPrefix}.${inputType.classname}';
    }
    return inputType.classname;
  }

  String get outputTypePackage => outputType.package;
  String get prefixedOutputType {
    if (outputType.packageImportPrefix.isNotEmpty) {
      return '${outputType.packageImportPrefix}.${outputType.classname}';
    }
    return outputType.classname;
  }

}