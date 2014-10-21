library service_compiler;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:quiver/async.dart';
import 'package:protoc_plugin/src/descriptor.pb.dart';
import 'package:protoc_plugin/protoc_builder.dart' as protoc_builder;
import 'package:protoc_plugin/protoc.dart' as protoc;

import 'service_info.dart';
import '../build_options.dart';

part 'protoc/file_generator.dart';
part 'protoc/service_generator.dart';

class ServiceCompiler {

  final BuildOptions buildOptions;
  final protoc_builder.Builder _builder;

  ServiceCompiler(BuildOptions buildOptions):
    this.buildOptions = buildOptions,
    this._builder = new protoc_builder.Builder(
        Uri.parse(buildOptions.templateRoot),
        buildOptions.sourceMap,
        buildOptions.parsedBuildArgs,
        buildOptions.pathToProtoc,
        projectRoot: buildOptions.irisTarget
    );

  Future<FileDescriptorSet> runProtocCompiler() {
    var _filesToCompile = new Set<Uri>();
    return _builder.runProtocCompiler(_builder.allProtobufferTemplates);
  }

  FileDescriptorSet _cachedDescriptorSet;

  Future<FileDescriptorSet> _getDescriptorSet() {
    if (_cachedDescriptorSet == null) {
      return runProtocCompiler().then((descriptorSet) {
        _cachedDescriptorSet = descriptorSet;
        return descriptorSet;
      });
    }
    return new Future.value(_cachedDescriptorSet);
  }

  Map<String,Map<String,ServiceDescriptorProto>> _cachedServiceDescriptorMap;

  Future<Map<String,Map<String,ServiceDescriptorProto>>> _getServiceDescriptorMap() {
    if (_cachedServiceDescriptorMap == null) {
      return _getDescriptorSet().then((descriptorSet) {
        _cachedServiceDescriptorMap = <String,Map<String,ServiceDescriptorProto>>{};
        for (var file in descriptorSet.file) {
          _cachedServiceDescriptorMap[file.name] = new Map.fromIterable(
              file.service,
              key: (serviceDescriptor) => serviceDescriptor.name
          );
        }
        return _cachedServiceDescriptorMap;
      });
    }

    return new Future.value(_cachedServiceDescriptorMap);
  }

  /**
   * Resolves the template as declared in the `@IrisService` annotation on
   * the class.
   */
  Future<ServiceInfo> resolve(ServiceInfo serviceInfo) {
    return _getServiceDescriptorMap().then((descriptorMap) {

      // Set the compilation unit status
      if (buildOptions.parsedBuildArgs.full) {
        serviceInfo.compilationUnitStatus = ServiceInfo.COMPILATION_UNIT_CHANGED;
      } else {
        var absChanged = buildOptions.parsedBuildArgs.changed
            .map((changedPath) => path.url.join(buildOptions.pathToProjectRoot, changedPath));
        if (absChanged.contains(serviceInfo.compilationUnitPath)) {
          serviceInfo.compilationUnitStatus = ServiceInfo.COMPILATION_UNIT_CHANGED;
        }
      }

      if (serviceInfo.compilationUnitStatus == null) {
        serviceInfo.compilationUnitStatus = ServiceInfo.COMPILATION_UNIT_UNCHANGED;
      }

      var templateFile = new File(path.join('${_builder.templateRoot}', serviceInfo.protobufferTemplatePath));
      if (!templateFile.existsSync()) {
        return serviceInfo..templateStatus = ServiceInfo.TEMPLATE_NOT_FOUND;
      }

      var templateUri = new Uri.file(serviceInfo.protobufferTemplatePath);

      var serviceDescriptors = descriptorMap[serviceInfo.protobufferTemplatePath];
      if (serviceDescriptors == null) {
        return serviceInfo..templateStatus = ServiceInfo.TEMPLATE_NOT_FOUND;
      }

      var serviceDescriptor = serviceDescriptors[serviceInfo.serviceName];
      if (serviceDescriptor == null) {
        return serviceInfo..templateStatus = ServiceInfo.TEMPLATE_NOT_FOUND;
      }

      serviceInfo.serviceDescriptor = serviceDescriptor;

      if (_builder.changedTemplates.contains(templateUri)) {
        serviceInfo.templateStatus = ServiceInfo.TEMPLATE_CHANGED;
      } else {
        serviceInfo.templateStatus = ServiceInfo.TEMPLATE_UNCHANGED;
      }

      return serviceInfo;
    });
  }

  Future build() {
    return _builder.deleteRemovedFiles(_builder.removedTemplates)
        .then((_) => _getDescriptorSet()
                     .then((descriptorSet) => compile(descriptorSet, _builder.changedTemplates)
        ));
  }

  Future compile(FileDescriptorSet descriptorSet, Iterable<Uri> rebuildTemplates) {
    var generationContext = new protoc.GenerationContext(_builder.options, _builder.outputConfiguration);
    var generators = <FileGenerator>[];
    for (var file in descriptorSet.file) {
      //This is our file generator which contains the service definitions.
      //Otherwise the method is identical to the builder method
      generators.add(new FileGenerator(file, _builder, generationContext));
    }

    print('Templates to rebuild: $rebuildTemplates');

    return _forEachAsync(descriptorSet.file, (file) {
      var filePath = new Uri.file(file.name);
      if (!rebuildTemplates.contains(filePath)) {
        //The file was just imported by a changed file.
        //It has not changed itself.
        return new Future.value();
      }
      var targetFile = _builder.outputConfiguration.outputPathFor(filePath);
      print('Writing $targetFile');
      var fileGen = generationContext.lookupFile(file.name);
      var writer = new protoc.FileWriter(
          _builder.outputConfiguration.outputPathFor(new Uri.file(file.name))
      );
      fileGen.generate(new protoc.IndentingWriter('  ', writer));
      return writer.toFile();
    });
  }
}

//TODO Workaround for quiver bug
Future _forEachAsync(Iterable iterable, Future action(dynamic value)) {
  if (iterable.isEmpty) return new Future.value();
  return forEachAsync(iterable, action);

}