library remote_services_compiler;

import "dart:io";
import "remote_services.dart";



compile(ServiceDefinitions services, Directory target) {

  List compiled = [];

  Map<String, List<ServiceRoute>> sorted = {};

  for (var route in services.routes) {
    if (!sorted.containsKey(route.serviceName)) sorted[route.serviceName] = [];
    sorted[route.serviceName].add(route);
  }



  var classes = "";

  var serviceClass = """// Generated file. Do not edit.

class Services {

  ServiceClient client;
  Services(this.client);


""";


  sorted.forEach((serviceName, routes) {

    var lowerCaseServiceName = serviceName.substring(0, 1).toLowerCase() + serviceName.substring(1, serviceName.length);

    serviceClass += "  $serviceName _$lowerCaseServiceName;\n";
    serviceClass += "  $serviceName get $lowerCaseServiceName => _$lowerCaseServiceName == null ? _$lowerCaseServiceName = new $serviceName(client) : _$lowerCaseServiceName;\n\n";

    classes += "class $serviceName extends Service {\n\n";
    classes += "  $serviceName(ServiceClient client) : super(client);\n\n";

    for (var route in routes) {
      classes += "  Future<${route.returnedType}> ${route.methodName}(${route.expectedRequestType} requestMessage) => client.query('${route.path}', requestMessage, ${route.returnedType.toString()});\n\n";
    }

    classes += "}\n\n";
  });

  serviceClass += "}\n";

  print(serviceClass);
  print(classes);



}