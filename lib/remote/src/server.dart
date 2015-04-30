part of iris;




/**
 * A class instantiated by the [IrisServer] whenever a request is made
 * either by HTTP, Socket or Websocket.
 *
 * You can access it with [Context.request].
 */
class IrisRequest {


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

  HttpRequest get httpRequest => _httpRequest;

  IrisRequest.fromHttp(this._httpRequest);

  IrisRequest.fromSocket() : _httpRequest = null;


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
      throw new IrisException._("Trying to set cookie but it's not a Http request.");
    }
  }

}



/**
 * The base to handle iris requests.
 */
abstract class IrisRequestHandler {

  List<RemoteProcedure> _procedures;

  List<RemoteProcedure> get procedures => _procedures;

  ContextInitializer _contextInitializer;

  ContextInitializer get contextInitializer => _contextInitializer;

  GeneratedMessage _getMessageFromBytes(RemoteProcedure procedure, List<int> bytes) {
    try {
      GeneratedMessage message = reflectClass(procedure.expectedRequestType).newInstance(const Symbol("fromBuffer"), [bytes]).reflectee;
      message.check();
      return message;
    }
    catch (err) {
      throw new _ErrorCodeException(IrisErrorCode.IRIS_INVALID_PB_MESSAGE_RECEIVED_BY_REMOTE, err.toString());
    }
  }

}

/**
 * Adds additional server functionality to startup a server.
 */
abstract class IrisServer extends IrisRequestHandler {

  Future start();

  Future stop();

}


/**
 * The HttpServiceServer exposes all procedures via Http.
 */
class IrisHttpRequestHandler extends IrisRequestHandler {


  /// This is used as the `Access-Control-Allow-Origin` CORS header.
  /// E.g.: `["http://localhost:9000"]`
  ///
  /// **If this list is empty, every origin will be allowed!**
  final List<String> allowOrigins;

  HttpServer _server;


  /**
   * Creates an HttpServer that starts up the server itself on specified address
   * and port.
   */
  IrisHttpRequestHandler({this.allowOrigins: const []});



  /**
   * Listens to the requests, and routes to the appropriate procedures.
   */
  setupRequestHandling(Stream<HttpRequest> requests) {

    var router = new Router(requests);

    // Setup the procedures
    for (RemoteProcedure procedure in procedures) {

      log.info("- '${procedure.path}' - expects: '${procedure.expectedRequestType.toString()}', returns: '${procedure.responseType.toString()}'");

      router.serve(procedure.path, method: "POST").listen((HttpRequest req) {

        _handleRequest(req, procedure);

      });
    }

    router.defaultStream.listen(serveNotFound);
  }


  Future _handleRequest(HttpRequest req, RemoteProcedure procedure) {

    GeneratedMessage requestMessage;
    Context context;

    var serviceRequest = new IrisRequest.fromHttp(req);

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
        // Not adding the [GeneratedMessage] type here, since not all procedures
        // need to return a GeneratedMessage.
        .then((responseMessage) => _sendMessage(req, procedure.responseType == null ? null : responseMessage))
        .catchError((err) {

          IrisErrorCode errorCode = IrisErrorCode.IRIS_INTERNAL_SERVER_ERROR;
          String errorMessage = err.toString();

          if (err is _ErrorCodeException || err is ProcedureException) {
            errorCode = err.errorCode;
            errorMessage = err.message;
          }
          else if (err is FilterException) {
            errorCode = IrisErrorCode.IRIS_REJECTED_BY_FILTER;
            errorMessage = "The filter '${err.filterName}' rejected the request.";
          }

          log.info('Got error from procedure $procedure: $errorMessage $err');

          _sendError(req, errorCode, errorMessage);

        });
  }

  serveNotFound(HttpRequest req) {
    log.finest("Sending 404 for procedure: ${req.uri.path}");

    _sendError(req, IrisErrorCode.IRIS_PROCEDURE_NOT_FOUND, "The requested procedure was not found.");

    return req.response.close();
  }


  /**
   * This is the function to call to send data to the client.
   */
  _sendMessage(HttpRequest req, GeneratedMessage message) {
    _send(req, message == null ? [] : message.writeToBuffer());
  }


  /**
   * Sends the write error protocol buffer to the client.
   */
  _sendError(HttpRequest req, IrisErrorCode errorCode, String errorMessage) {

    int statusCode;

    if (errorCode == IrisErrorCode.IRIS_PROCEDURE_NOT_FOUND) {
      statusCode = HttpStatus.NOT_FOUND;
    }
    else {
      statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    }

    var message = new IrisErrorMessage()
        ..errorCode = errorCode.value
        ..message = errorMessage;

    _send(req, message.writeToBuffer(), statusCode);
  }


  /**
   * Sets all necessary headers for CORS.
   */
  setCorsHeaders(HttpRequest req) {
    String origin = (req.headers["origin"] != null && req.headers["origin"].length >= 1) ? req.headers["origin"].first : null;
    if (allowOrigins.isEmpty || allowOrigins.contains(origin)) {
      req.response.headers.add("Access-Control-Allow-Credentials", "true");
      req.response.headers.add("Access-Control-Allow-Headers", "Content-Type, X-Requested-With, X-PINGOTHER, X-File-Name, Cache-Control");
      req.response.headers.add("Access-Control-Allow-Methods", "POST, OPTIONS");
      req.response.headers.add("Access-Control-Allow-Origin", origin);
    }
  }


  /**
   * Don't use this method directly. Use [_sendError] or [_sendMessage] instead.
   */
  _send(HttpRequest req, List<int> body, [int statusCode = HttpStatus.OK]) {

    setCorsHeaders(req);

    req.response.statusCode = statusCode;

    req.response.add(body);

    return req.response.close();
  }

}





/**
 * The HttpServiceServer exposes all procedures via Http.
 */
class IrisHttpServer extends IrisHttpRequestHandler implements IrisServer {


  final dynamic address;

  final int port;


  HttpServer _server;


  /**
   * Creates an HttpServer that starts up the server itself on specified address
   * and port.
   */
  IrisHttpServer(this.address, this.port, {allowOrigins: const []}) : super(allowOrigins: allowOrigins);


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

      setupRequestHandling(server);

    });
  }

  Future stop() => _server == null ? new Future.value() : _server.close();


}
