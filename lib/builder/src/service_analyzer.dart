library service_analyzer;

import 'package:protoc_plugin/src/descriptor.pb.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

import 'analysis_utils.dart';
import 'analysis_message.dart';
import '../build_options.dart';
import 'service_info.dart';

class ServiceAnalyzer {

  final AnalysisUtils analysisUtils;

  factory ServiceAnalyzer.withOptions(BuildOptions buildOptions) {
    return new ServiceAnalyzer(new AnalysisUtils.withOptions(buildOptions));
  }

  ServiceAnalyzer(this.analysisUtils);

  Map<String, LibraryElement> _cachedLibraries = <String,LibraryElement>{};

  LibraryElement getServiceLibrary(ServiceInfo serviceInfo) {
    if (_cachedLibraries[serviceInfo.libraryPath] == null) {
      var libSource = analysisUtils.sourceFactory.forUri2(new Uri.file(serviceInfo.libraryPath));
      //We collected the library via the source crawler so
      //we should be able to resolve the library element
      assert(libSource != null);
      _cachedLibraries[serviceInfo.libraryPath] =
          analysisUtils.analysisContext.computeLibraryElement(libSource);
    }
    return _cachedLibraries[serviceInfo.libraryPath];
  }

  ClassElement getServiceClassElement(ServiceInfo serviceInfo) {
    var clsElement = getServiceLibrary(serviceInfo).getType(serviceInfo.serviceName);
    //We collected the class via the source crawler so we should be able
    //to resolve the class element
    assert(clsElement != null);
    return clsElement;
  }

  bool requiresAnalysis(ServiceInfo serviceInfo) =>
      serviceInfo.compilationUnitStatus != ServiceInfo.COMPILATION_UNIT_UNCHANGED ||
      serviceInfo.templateStatus != ServiceInfo.TEMPLATE_UNCHANGED;

  List<AnalysisMessage> analyze(ServiceInfo serviceInfo) {
    print('Analyzing: $serviceInfo');
    if (!requiresAnalysis(serviceInfo))
      return <AnalysisMessage>[];

    var classElement = getServiceClassElement(serviceInfo);

    if (serviceInfo.templateStatus == ServiceInfo.TEMPLATE_NOT_FOUND) {
      var msg = new AnalysisError(
          serviceInfo,
          "Could not find '${serviceInfo.serviceName}' in '${serviceInfo.protobufferTemplatePath}'",
          new SourceRange(classElement.nameOffset, classElement.name.length)
      );
      //Don't scan for further messages.
      return [msg];
    }

    var methodAnalyzer = new MethodAnalyzer(analysisUtils, this, serviceInfo);

    var methodMessages = <AnalysisMessage>[];
    for (var methodDescriptor in serviceInfo.methodDescriptors) {
      var msg = methodAnalyzer.analyze(methodDescriptor);
      if (msg != null)
        methodMessages.add(msg);
    }
    return methodMessages;
  }
}

class MethodAnalyzer {

  final AnalysisUtils analysisUtils;
  final ServiceAnalyzer serviceAnalyzer;
  final ServiceInfo serviceInfo;

  MethodAnalyzer(this.analysisUtils, this.serviceAnalyzer, this.serviceInfo);

  LibraryElement get libraryElement => serviceAnalyzer.getServiceLibrary(serviceInfo);

  ClassElement get classElement => serviceAnalyzer.getServiceClassElement(serviceInfo);


  Map<String,DartType> _generatedMessageTypes;

  /**
   * The [GeneratedMessage] types available to the library
   * containing the [:methodElement:] for this descriptor
   */
  Map<String,DartType> get generatedMessageTypes {
    if (_generatedMessageTypes == null) {
      var messageTypes = analysisUtils.generatedMessageTypesInScope(libraryElement);
      _generatedMessageTypes = new Map.fromIterable(
          messageTypes,
          key: (type) => type.name
      );
    }
    return _generatedMessageTypes;
  }

  /**
   * The [DartType] which matches the output type of the method descriptor
   * or `null` if there is no such type in the library scope.
   */
  DartType outputType(MethodDescriptorProto methodDescriptor) =>
      // TODO: Qualified message type names.
      generatedMessageTypes[methodDescriptor.outputType.substring(1)];

  /**
   * The [DartType] which matches the input type of the method descriptor
   * or `null` if there is no such type in the library scope.
   */
  DartType inputType(MethodDescriptorProto methodDescriptor) =>
      generatedMessageTypes[methodDescriptor.inputType.substring(1)];

  /**
   * Analyze the method signature for compatibility with the [:methodDescriptor:]
   *
   * Will return an [AnalysisWarning] if:
   * - A method is not found on the [:classElement:] corresponding to the
   * procedure declared in [:methodDescriptor:]; or
   * - The procedure is not declared with exactly two required parameters
   * (although any number of named or positional parameters are accepted
   *
   * Will return an [AnalysisWarning] if:
   * - The method return type is not assignable to [Future<OutputType>] or
   * [OutputType], where [OutputType] is a type imported into the library scope
   * with name [:methodDescriptor.name:]
   * - The first required method parameter is not assignable to the iris [Context]
   * type.
   * - The second required method parameter is not assignable to the subclass of
   * [GeneratedMessage] found in the library scope with the same name as
   * [:methodDescriptor.inputType:]
   *
   * Otherwise returns `null`.
   */
  AnalysisMessage analyze(MethodDescriptorProto methodDescriptor) {

    MethodElement methodElement = classElement.getMethod(methodDescriptor.name);
    if (methodElement == null) {
      return new AnalysisError(
          serviceInfo,
          "No method found corresponding to procedure "
          "'${methodDescriptor.name}' on class",
          new SourceRange(classElement.nameOffset, classElement.name.length)
      );
    }

    var msg = checkValidReturnType(methodElement, methodDescriptor);
    if (msg != null) return msg;
    msg = checkValidParameterList(methodElement, methodDescriptor);
    if (msg != null) return msg;

    return null;
  }

  AnalysisMessage checkValidReturnType(MethodElement methodElement, MethodDescriptorProto methodDescriptor) {
    var returnType = methodElement.returnType;
    //Check whether the type is assignable to Future<dynamic>
    var future_dynamic = analysisUtils.futureType
        .substitute4([analysisUtils.dynamicType]);
    bool isAsyncReturn = returnType.isAssignableTo(future_dynamic);
    if (isAsyncReturn) {
      if (returnType is ParameterizedType && returnType.typeArguments.isNotEmpty) {
        returnType = returnType.typeArguments.first;
      } else {
        returnType = analysisUtils.dynamicType;
      }
    }

    var methodOut = outputType(methodDescriptor);

    if (methodOut == null || !methodOut.isAssignableTo(returnType)) {
      var returnTypeNode = methodElement.node.returnType;
      return new AnalysisWarning(
          serviceInfo,
          "Return type incompatible with declared procedure type '$methodOut'",
          new SourceRange(returnTypeNode.offset, returnTypeNode.length)
      );
    } else {
      return null;
    }
  }

  AnalysisMessage checkValidParameterList(MethodElement methodElement, MethodDescriptorProto methodDescriptor) {
    var params = methodElement.parameters
        .where((param) => param.parameterKind == ParameterKind.REQUIRED)
        .toList();
    if (params.length != 2) {
      return new AnalysisError(
          serviceInfo,
          "procedure must be declared with two mandatory parameters",
          new SourceRange(methodElement.nameOffset, methodElement.name.length)
      );
    }
    ParameterElement contextParam = params[0];
    if (!contextParam.type.isAssignableTo(analysisUtils.contextType)) {
      return new AnalysisWarning(
          serviceInfo,
          "parameter must be assignable to iris 'Context'",
          new SourceRange(contextParam.nameOffset, contextParam.name.length)
      );
    }

    ParameterElement requestParam = params[1];
    var methodInputType = inputType(methodDescriptor);
    if (methodInputType == null || !requestParam.type.isAssignableTo(methodInputType)) {
      return new AnalysisWarning(
          serviceInfo,
          "Parameter incompatible with procedure request type '$methodInputType'",
          new SourceRange(requestParam.nameOffset, requestParam.name.length)
      );
    }
    //parameters OK.
    return null;
  }
}
