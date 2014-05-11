part of remote_services;




/**
 * A class instantiated by the [ServiceServer] whenever a request is made
 * either by HTTP, Socket or Websocket.
 *
 * You can access it with [Context.request].
 */
class ServiceRequest {


  /// This attribute **always** returns an empty list for Socket connections
  /// since there are now cookies on socket connections.
  List<Cookie> get cookies {
    if (_httpRequest != null) {
      return _httpRequest.cookies;
    }
    else {
      return [];
    }
  }

  final HttpRequest _httpRequest;

  ServiceRequest.fromHttp(this._httpRequest);

  ServiceRequest.fromSocket() : _httpRequest = null;

}



/**
 * The base class for servers.
 */
abstract class ServiceServer {

  List<ServiceRoute> _routes;

  List<ServiceRoute> get routes => _routes;

  ContextInitializer _contextInitializer;

  ContextInitializer get contextInitializer => _contextInitializer;


  void start();




  GeneratedMessage _getMessageFromBytes(ServiceRoute route, List<int> bytes) {
    try {
      GeneratedMessage message = reflectClass(route.expectedRequestType).newInstance(const Symbol("fromBuffer"), [bytes]).reflectee;
      message.check();
      return message;
    }
    catch (err) {
      throw new _ErrorCodeException(RemoteServicesErrorCode.RS_INVALID_PB_MESSAGE_RECEIVED_BY_SERVICE, err.toString());
    }
  }

}



/**
 * The HttpServiceServer exposes all routes via Http.
 */
class HttpServiceServer extends ServiceServer {


  final dynamic address;

  final int port;

  /// This is used as the `Access-Control-Allow-Origin` CORS header.
  /// E.g.: "http://localhost:9000"
  final String allowOrigin;

  HttpServiceServer(this.address, this.port, {this.allowOrigin});

  /**
   * Starts an HTTP server that listens for POST requests for all specified
   * routes and always returns the expected [GeneratedMessage].
   *
   * When an error error occurs, a statusCode between 400 and 599 will be sent,
   * and a [ErrorMessage] along with it.
   */
  Future start() {
    return HttpServer.bind(address, port).then((server) {
      log.info("Listening on $address, port $port.");

      var router = new Router(server);

      // Setup the routes
      for (ServiceRoute route in routes) {

        log.info("- '${route.path}' - expects: '${route.expectedRequestType.toString()}', returns: '${route.returnedType.toString()}'");

        router.serve(route.path, method: "POST").listen((HttpRequest req) {

          _handleRequest(req, route);

        });
      }

      router.defaultStream.listen(serveNotFound);
    });
  }


  Future _handleRequest(HttpRequest req, ServiceRoute route) {

    GeneratedMessage requestMessage;
    Context context;

    var serviceRequest = new ServiceRequest.fromHttp(req);

    // First get the protocol buffer from the request
    return req.fold(new BytesBuilder(), (builder, bytes) => builder..add(bytes))
        .then((BytesBuilder builder) {
          requestMessage = _getMessageFromBytes(route, builder.takeBytes());

          return contextInitializer(serviceRequest);
        })
        .then((Context ctx) {
          context = ctx;

          var future = new Future.value();

          // Call all filters in sequence
          for (var filter in route.filterFunctions) {
            future = future
                .then((_) => filter(context))
                .then((bool filterResult) {
                  if (filterResult == false) throw new FilterException(filter);
                });
          }

          return future;
        })
        // Invoke the route
        .then((_) => route.invoke(context, requestMessage))
        // And send the response
        .then((GeneratedMessage responseMessage) => _send(req, responseMessage.writeToBuffer()))
        .catchError((err) {

          // TODO FIXME: build the ErrorMessage protocol buffer message
          // Check if err is a RouteError and build the pb message accordingly

          RemoteServicesErrorCode errorCode = RemoteServicesErrorCode.RS_INTERNAL_SERVER_ERROR;
          String errorMessage = "ERROR $err";

          if (err is _ErrorCodeException) {
            errorCode = err.errorCode;
            errorMessage = err.message;
          }
          else if (err is FilterException) {
            errorCode = RemoteServicesErrorCode.RS_REJECTED_BY_FILTER;
            errorMessage = "The filter '${err.filterName}' rejected the request.";
          }

          _send(req, UTF8.encode(errorMessage), errorCode);

        });
  }

  serveNotFound(HttpRequest req) {
    log.finest("Sending 404 for route: ${req.uri.path}");

    _send(req, UTF8.encode("Not found."), RemoteServicesErrorCode.RS_PROCEDURE_NOT_FOUND);

    return req.response.close();
  }


  _send(HttpRequest req, List<int> body, [RemoteServicesErrorCode errorCode]) {
    int statusCode = HttpStatus.OK;

    if (allowOrigin != null) {
      req.response.headers.add("Access-Control-Allow-Credentials", "true");
      req.response.headers.add("Access-Control-Allow-Headers", "Content-Type, X-Requested-With, X-PINGOTHER, X-File-Name, Cache-Control");
      req.response.headers.add("Access-Control-Allow-Methods", "POST, OPTIONS");
      req.response.headers.add("Access-Control-Allow-Origin", allowOrigin);
    }

    if (errorCode != null) {
      if (errorCode == RemoteServicesErrorCode.RS_PROCEDURE_NOT_FOUND) {
        statusCode = HttpStatus.NOT_FOUND;
      }
      else {
        statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
      }
      req.response.headers.add("X-Error-Code", errorCode.value);
    }

    req.response.statusCode = statusCode;

    req.response.add(body);

    return req.response.close();
  }

}