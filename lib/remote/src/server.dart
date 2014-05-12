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


  /**
   * Stores a cookie on the client if possible.
   *
   * Throws an exception if the connection doesn't allow it.
   */
  addCookie(Cookie cookie) {
    if (_httpRequest != null) {
      _httpRequest.response.cookies.add(cookie);
    }
    else {
      throw new RemoteServicesException._("Trying to set cookie but it's not a Http request.");
    }
  }

}



/**
 * The base class for servers.
 */
abstract class ServiceServer {

  List<ServiceProcedure> _procedures;

  List<ServiceProcedure> get procedures => _procedures;

  ContextInitializer _contextInitializer;

  ContextInitializer get contextInitializer => _contextInitializer;


  void start();

  void stop();


  GeneratedMessage _getMessageFromBytes(ServiceProcedure procedure, List<int> bytes) {
    try {
      GeneratedMessage message = reflectClass(procedure.expectedRequestType).newInstance(const Symbol("fromBuffer"), [bytes]).reflectee;
      message.check();
      return message;
    }
    catch (err) {
      throw new _ErrorCodeException(RemoteServicesErrorCode.RS_INVALID_PB_MESSAGE_RECEIVED_BY_SERVICE, err.toString());
    }
  }

}



/**
 * The HttpServiceServer exposes all procedures via Http.
 */
class HttpServiceServer extends ServiceServer {


  final dynamic address;

  final int port;

  /// This is used as the `Access-Control-Allow-Origin` CORS header.
  /// E.g.: "http://localhost:9000"
  final String allowOrigin;

  HttpServer _server;


  HttpServiceServer(this.address, this.port, {this.allowOrigin});

  /**
   * Starts an HTTP server that listens for POST requests for all specified
   * procedures and always returns the expected [GeneratedMessage].
   *
   * When an error error occurs, a statusCode between 400 and 599 will be sent,
   * and a [ErrorMessage] along with it.
   */
  Future start() {
    return HttpServer.bind(address, port).then((server) {
      _server = server;

      log.info("Listening on $address, port $port.");

      var router = new Router(server);

      // Setup the procedures
      for (ServiceProcedure procedure in procedures) {

        log.info("- '${procedure.path}' - expects: '${procedure.expectedRequestType.toString()}', returns: '${procedure.responseType.toString()}'");

        router.serve(procedure.path, method: "POST").listen((HttpRequest req) {

          _handleRequest(req, procedure);

        });
      }

      router.defaultStream.listen(serveNotFound);
    });
  }

  Future stop() => _server == null ? new Future.value() : _server.close();

  Future _handleRequest(HttpRequest req, ServiceProcedure procedure) {

    GeneratedMessage requestMessage;
    Context context;

    var serviceRequest = new ServiceRequest.fromHttp(req);

    Future reqMsgFuture;

    if (procedure.expectedRequestType == null) {
      reqMsgFuture = new Future.value();
    }
    else {
      reqMsgFuture = req.fold(new BytesBuilder(), (builder, bytes) => builder..add(bytes))
          .then((BytesBuilder builder) {
            requestMessage = _getMessageFromBytes(procedure, builder.takeBytes());
          });
    }

    // First get the protocol buffer from the request
    return reqMsgFuture.then((_) => contextInitializer(serviceRequest))
        .then((Context ctx) {
          context = ctx;

          var future = new Future.value();

          // Call all filters in sequence
          for (var filter in procedure.filterFunctions) {
            future = future
                .then((_) => filter(context))
                .then((bool filterResult) {
                  if (filterResult == false) throw new FilterException(filter);
                });
          }

          return future;
        })
        // Invoke the procedure
        .then((_) => procedure.invoke(context, requestMessage))
        // And send the response
        .then((GeneratedMessage responseMessage) => _send(req, procedure.responseType == null ? [] : responseMessage.writeToBuffer()))
        .catchError((err) {

          RemoteServicesErrorCode errorCode = RemoteServicesErrorCode.RS_INTERNAL_SERVER_ERROR;
          String errorMessage = err.toString();

          if (err is _ErrorCodeException || err is ProcedureException) {
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
    log.finest("Sending 404 for procedure: ${req.uri.path}");

    _send(req, UTF8.encode("The requested procedure was not found."), RemoteServicesErrorCode.RS_PROCEDURE_NOT_FOUND);

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
      req.response.headers.add(ERROR_CODE_RESPONSE_HEADER, errorCode.value);
    }

    req.response.statusCode = statusCode;

    req.response.add(body);

    return req.response.close();
  }

}