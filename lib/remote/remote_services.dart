library remote_services;

import "dart:io";
export "dart:async";
import "dart:async";
import "dart:mirrors";
import "dart:convert";



import "package:logging/logging.dart";
import "package:route/server.dart";
import "package:protobuf/protobuf.dart";
import "annotations.dart" as annotations;


import "package:annotation_crawler/annotation_crawler.dart" as annotation_crawler;

import "error_code.dart";
import "../src/consts.dart";

part "src/exceptions.dart";
part "src/server.dart";
part "src/service.dart";





Logger log = new Logger("RemoteServices");



/**
 * The base class for context classes. Every procedure gets an instance of this
 * class (or a subclass of it) as first parameter when invoked.
 *
 * You can define your own context class by calling
 * [RemoteServices.setContextInitializer].
 */
class Context {

   final ServiceRequest request;

   Context(this.request);
}


/**
 * The type of a filter function used in a [annotations.Procedure] annotation.
 */
typedef Future<bool> FilterFunction(Context context);


/**
 * The type of context initializer functions
 */
typedef Future<Context> ContextInitializer(ServiceRequest req);




/**
 * Holds all necessary information to invoke a procedure on a [Service].
 *
 * You can create [ServiceProcedure]s by calling [ServiceDefinitions.addService].
 */
class ServiceProcedure {

  /// The instance of the service this procedure will be called on.
  final Service service;

  /// The expected [GeneratedMessage] type this procedure expects.
  final Type expectedRequestType;

  /// The returned [GeneratedMessage] type.
  final Type responseType;

  /// The actual method to invoke when this procedure is called.
  final MethodMirror method;

  /// The list of filter functions for this specific procedure.
  final List<FilterFunction> filterFunctions;



  ServiceProcedure(this.service, this.method, this.expectedRequestType, this.responseType, this.filterFunctions);

  /// Returns the generated path for this procedure. Either to be used as HTTP path
  /// or as name for sockets.
  String get path => "/$serviceName.$methodName";

  String get serviceName => service.runtimeType.toString();

  String get methodName => MirrorSystem.getName(method.simpleName);

  /**
   * Invokes the procedure with [Context] and the [requestMessage] and returns the
   * resulting [GeneratedMessage].
   */
  Future<GeneratedMessage> invoke(Context context, GeneratedMessage requestMessage) {
    List params = [context];
    if (expectedRequestType != null) params.add(requestMessage);
    return reflect(service).invoke(method.simpleName, params).reflectee;
  }

}


/**
 * The base class for the remote_service server. This is your starting point for
 * a remote services server.
 */
class ServiceDefinitions {

  final ContextInitializer _contextInitializer;

  ContextInitializer get contextInitializer => _contextInitializer == null ? _defaultContextInitializer : _contextInitializer;

  RemoteServicesErrorCode errorCodes;

  ServiceDefinitions([this._contextInitializer]);

  Future<Context> _defaultContextInitializer(ServiceRequest req) => new Future.value(new Context(req));


  /// The list of all [ServiceProcedure]s available.
  List<ServiceProcedure> procedures = [];

  /// The list of all servers configured for those services.
  List<ServiceServer> servers = [];

  /**
   * Checks the service, and creates a list of [SerProcedurerocedure]s for every
   * [Procedure] found in the service.
   */
  addService(Service service) {
    if (servers.length != 0) throw new RemoteServicesException._("You can't add a service after servers have been added.");

    for (var annotatedProcedure in annotation_crawler.annotatedDeclarations(annotations.Procedure, on: reflectClass(service.runtimeType))) {

      if (annotatedProcedure.declaration is MethodMirror) {
        MethodMirror method = annotatedProcedure.declaration;

        annotations.Procedure annotation = annotatedProcedure.annotation;


        /// Now check that the method is actually of type [ProcedureMethod].
        /// See: http://stackoverflow.com/questions/23497032/how-do-check-if-a-methodmirror-implements-a-typedef

        TypeMirror returnTypeMirror = method.returnType.typeArguments.first;
        Type returnType;

        if (returnTypeMirror is! ClassMirror && returnTypeMirror.reflectedType == dynamic) {
          returnType = null;
        }
        else {
          // Using `.isSubtypeOf` here doesn't work because Future has Generics.
          if (method.returnType.qualifiedName != const Symbol("dart.async.Future") ||
              returnTypeMirror is! ClassMirror ||
              !returnTypeMirror.isSubtypeOf(reflectClass(GeneratedMessage))) {
            throw new InvalidServiceDeclaration._("Every procedure needs to return a Future containing a GeneratedMessage.", service);
          }
          else {
            returnType = returnTypeMirror.reflectedType;
          }
        }


        if (method.parameters.length < 1 || method.parameters.length > 2 ||
            !method.parameters.first.type.isSubtypeOf(reflectClass(Context)) ||
            (method.parameters.length == 2 && !method.parameters.last.type.isSubtypeOf(reflectClass(GeneratedMessage)))) {
          throw new InvalidServiceDeclaration._("Every procedure needs to accept a Context and a GeneratedMessage object as parameters.", service);
        }

        var requestType = method.parameters.length == 2 ? method.parameters.last.type.reflectedType : null;

        var serviceProcedure = new ServiceProcedure(service, method, requestType, returnType, annotation.filters);
        log.fine("Found procedure ${serviceProcedure.methodName} on service ${serviceProcedure.serviceName}");
        procedures.add(serviceProcedure);
      }
    }
  }


  /**
   * Sets all procedures on the server and adds it to the list.
   */
  addServer(ServiceServer server) {
    if (procedures.isEmpty) throw new RemoteServicesException._("You tried to add a server but no procedures have been added yet.");

    server._procedures = procedures;
    server._contextInitializer = contextInitializer;
    servers.add(server);
  }


  /**
   * Starts all servers
   */
  Future startServers() {
    return Future.wait(servers.map((server) => server.start()));
  }


  /**
   * Stops all servers
   */
  Future stopServers() {
    return Future.wait(servers.map((server) => server.stop()));
  }


}





