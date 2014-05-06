
library remote_services;

import "dart:io";
export "dart:async";
import "dart:async";
import "dart:mirrors";



import "package:protobuf/protobuf.dart";
import "annotations.dart" as annotations;


import "package:annotation_crawler/annotation_crawler.dart" as annotation_crawler;


part "src/exceptions.dart";
part "src/server.dart";
part "src/service.dart";

/**
 * The base class for context classes. Every route gets an instance of this
 * class (or a subclass of it) as first parameter when invoked.
 *
 * You can define your own context class by calling
 * [RemoteServices.setContextInitializer].
 */
class Context {

   final RemoteServiceRequest request;

   Context(this.request);
}


/**
 * The type of a filter function used in a [annotations.Route] annotation.
 */
typedef Future<bool> FilterFunction(Context context);


/**
 * The type of context initializer functions
 */
typedef Future<Context> ContextInitalizer(RemoteServiceRequest req);




/**
 * Holds all necessary information to invoke a route on a [Service].
 *
 * You can create [ServiceRoute]s by calling [RemoteServices.addService].
 */
class ServiceRoute {

  /// The instance of the service this route will be called on.
  final Service service;

  /// The expected [GeneratedMessage] type this route expects.
  final TypeMirror expectedRequestType;

  /// The actual method to invoke when this route is called.
  final MethodMirror method;

  ServiceRoute(this.service, this.method, this.expectedRequestType);

  /**
   * Invokes the route with [Context] and the [requestMessage] and returns the
   * resulting [GeneratedMessage].
   */
  Future<GeneratedMessage> invoke(Context context, GeneratedMessage requestMessage) {
    return reflect(service).invoke(method.simpleName, [context, requestMessage]).reflectee;
  }

}


/**
 * The base class for the remote_service server. This is your starting point for
 * a remote services server.
 */
class RemoteServices {

  final ContextInitalizer contextInitializer;

  RemoteServices({this.contextInitializer});


  List<ServiceRoute> _routes = [];

  List<ServiceRoute> get routes => _routes;


  /**
   * Checks the service, and creates a list of [ServiceRoute]s for every
   * [Route] found in the service.
   */
  addService(Service service) {
    for (var annotatedRoute in annotation_crawler.annotatedDeclarations(annotations.Route, on: reflectClass(service.runtimeType))) {

      if (annotatedRoute.declaration is MethodMirror) {
        MethodMirror method = annotatedRoute.declaration;

        TypeMirror returnType = method.returnType.typeArguments.first;

        // Using `.isSubtypeOf` here doesn't work because Future has Generics.
        if (method.returnType.qualifiedName != const Symbol("dart.async.Future") ||
            !returnType.isSubtypeOf(reflectClass(GeneratedMessage))) {
          throw new InvalidServiceDeclaration("Every route needs to return a Future containing a GeneratedMessage.", service);
        }


        if (method.parameters.length != 2 ||
            !method.parameters.first.type.isSubtypeOf(reflectClass(Context)) ||
            !method.parameters.last.type.isSubtypeOf(reflectClass(GeneratedMessage))) {
          throw new InvalidServiceDeclaration("Every route needs to accept a Context and a GeneratedMessage object as parameters.", service);
        }

        var _route = new ServiceRoute(service, method, method.parameters.last.type);

        _routes.add(_route);

      }
    }
  }


  addServer(ServiceServer server) {

  }

}










//
//Future<MyContext> initContext(RemoteServiceRequest req) {
//
//  var context = new MyContext();
//
//
//  redisClient
//  context.session = ""
//
//
//}
//
//
//Future<Context> initContext(RemoteServiceRequest req) => new Context(req);
//
//
//Future<bool> authenticationFilter(MyContext context) {
//
//  context.loggedInUser
//
//}




/*
test() {


  new RemoteServiceServer<Context>()
    ..setContextInitializer(initContext);


}


@service
class UserService {


  /**
   * DOCBLOCK
   */
  @Filter(authenticationFilter)
  Future<CreateUserResponset> create(MyContext context, CreateUserRequest req) {

  }


}


remoteServices.user.create();
*/

