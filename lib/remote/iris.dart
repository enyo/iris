library iris;

import "dart:io";
export "dart:async";
import "dart:async";
import "dart:mirrors";



import "package:logging/logging.dart";
import "package:route/server.dart";
import "package:protobuf/protobuf.dart";
import "annotations.dart" as annotations;


import "package:annotation_crawler/annotation_crawler.dart" as annotation_crawler;

import "error_code.dart";
import "../src/error_message.dart";

part "src/exceptions.dart";
part "src/server.dart";
part "src/remote.dart";





Logger log = new Logger("Iris");



/**
 * The base class for context classes. Every procedure gets an instance of this
 * class (or a subclass of it) as first parameter when invoked.
 *
 * You can define your own context class by providing it in the [Iris] constructor.
 */
class Context {

   final IrisRequest request;

   Context(this.request);
}


/**
 * The type of a filter function used in a [annotations.Procedure] annotation.
 */
typedef Future<bool> FilterFunction(Context context);


/**
 * The type of context initializer functions
 */
typedef Future<Context> ContextInitializer(IrisRequest req);




/**
 * Holds all necessary information to invoke a procedure on a [Remote].
 *
 * You can create [RemoteProcedure]s by calling [Iris.addRemote].
 */
class RemoteProcedure {

  /// The instance of the remote this procedure will be called on.
  final Remote remote;

  /// The prefix used in the path
  final String prefix;

  /// The expected [GeneratedMessage] type this procedure expects.
  final Type expectedRequestType;

  /// The returned [GeneratedMessage] type.
  final Type responseType;

  /// The actual method to invoke when this procedure is called.
  final MethodMirror method;

  /// The list of filter functions for this specific procedure.
  final List<FilterFunction> filterFunctions;



  RemoteProcedure(this.remote, this.prefix, this.method, this.expectedRequestType, this.responseType, this.filterFunctions);


  /**
   * Returns the prefix with a leading and trailing slash.
   */
  String get _formattedPrefix {
    String formattedPrefix = "";
    if (prefix != null && prefix != "") {
      if (!prefix.startsWith("/")) formattedPrefix = "/";
      formattedPrefix += prefix;
      if (!prefix.endsWith("/")) formattedPrefix += "/";
    }
    else {
      formattedPrefix = "/";
    }
    return formattedPrefix;
  }

  /// Returns the generated path for this procedure. Either to be used as HTTP path
  /// or as name for sockets.
  String get path => "$_formattedPrefix$remoteName.$methodName";

  String get remoteName => remote.runtimeType.toString();

  String get methodName => MirrorSystem.getName(method.simpleName);

  /**
   * Invokes the procedure with [Context] and the [requestMessage] and returns the
   * resulting [GeneratedMessage].
   */
  Future<GeneratedMessage> invoke(Context context, GeneratedMessage requestMessage) {
    List params = [];
    params.add(context); // I put this on a separate line because otherwise there was a type warning.
    if (expectedRequestType != null) params.add(requestMessage);
    return reflect(remote).invoke(method.simpleName, params).reflectee;
  }

}


/**
 * This is your starting point for an iris server.
 */
class Iris {

  final ContextInitializer _contextInitializer;

  ContextInitializer get contextInitializer => _contextInitializer == null ? _defaultContextInitializer : _contextInitializer;

  IrisErrorCode errorCodes;


  /// This defines under which http prefix this request handler will accept
  /// incoming requests. No leading or trailing slashes are needed.
  /// If `null` no prefix is used.
  /// Examples: `api`, `api/v2.0`
  final String prefix;

  Future<Context> _defaultContextInitializer(IrisRequest req) => new Future.value(new Context(req));


  /// The list of all [RemoteProcedure]s available.
  List<RemoteProcedure> procedures = [];

  /// The request handler for this iris instance.
  final IrisRequestHandler requestHandler;


  /// If the [requestHandler] is not a server, then [Iris] creates a stream
  /// controller on startup to give it to the request handler.
  /// Every time [handleRequest] is called, the [HttpRequest] is added to this
  /// stream controller.
  StreamController<HttpRequest> requestStreamController;


  /**
   * Accepts either [IrisRequestHandler]s or [IrisServer]s.
   */
  Iris(this.requestHandler, {contextInitializer: null, this.prefix: "/"}) : _contextInitializer = contextInitializer {
    requestHandler._contextInitializer = contextInitializer;

    /// Will be populated every time [addRemote] is called
    requestHandler._procedures = procedures;
  }

  /**
   * Checks the remote, and creates a list of [RemoteProcedure]s for every
   * [Procedure] found in the remote.
   */
  addRemote(Remote remote) {
    var reflectedRemoteClass = reflectClass(remote.runtimeType);
    var remoteFilters = [];

    // First check if the remote has filters itself.
    var remoteAnnotationInstanceMirror = reflectedRemoteClass.metadata.firstWhere((InstanceMirror im) => im.type.isSubtypeOf(reflectClass(annotations.Remote)), orElse: () => null);
    if (remoteAnnotationInstanceMirror != null) {
      annotations.Remote remoteAnnotation = remoteAnnotationInstanceMirror.reflectee;
      remoteFilters = remoteAnnotation.filters;
    }


    for (var annotatedProcedure in annotation_crawler.annotatedDeclarations(annotations.Procedure, on: reflectedRemoteClass)) {

      if (annotatedProcedure.declaration is MethodMirror) {
        MethodMirror method = annotatedProcedure.declaration;

        annotations.Procedure annotation = annotatedProcedure.annotation;

        List filters = []
            ..addAll(remoteFilters)
            ..addAll(annotation.filters);

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
            throw new InvalidRemoteDeclaration._("Every procedure needs to return a Future containing a GeneratedMessage.", remote);
          }
          else {
            returnType = returnTypeMirror.reflectedType;
          }
        }


        if (method.parameters.length < 1 || method.parameters.length > 2 ||
            !method.parameters.first.type.isSubtypeOf(reflectClass(Context)) ||
            (method.parameters.length == 2 && !method.parameters.last.type.isSubtypeOf(reflectClass(GeneratedMessage)))) {
          throw new InvalidRemoteDeclaration._("Every procedure needs to accept a Context and a GeneratedMessage object as parameters.", remote);
        }

        var requestType = method.parameters.length == 2 ? method.parameters.last.type.reflectedType : null;

        var remoteProcedure = new RemoteProcedure(remote, prefix, method, requestType, returnType, filters);
        log.fine("Found procedure ${remoteProcedure.methodName} on remote ${remoteProcedure.remoteName}");
        procedures.add(remoteProcedure);
      }
    }
  }



  IrisServer _getServer() {
    if (requestHandler is IrisServer) {
      return requestHandler;
    }
    else {
      throw new IrisException._("Trying to use a request handler as server.");
    }

  }


  /**
   * Start the [IrisServer] if the request handler is one. This throws an
   * exception if th requestHandler is not a server.
   * Use [handleRequest] in this case.
   */
  Future startServer() {
    return _getServer().start();
  }


  /**
   * Stops the [IrisServer] if the request handler is one. This throws an
   * exception if th requestHandler is not a server.
   * Use [handleRequest] in this case.
   */
  Future stopServer() {
    return _getServer().stop();
  }


}





