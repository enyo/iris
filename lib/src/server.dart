part of remote_services;




/**
 * A class instantiated by the [ServiceServer] whenever a request is made
 * either by HTTP, Socket or Websocket.
 *
 * You can access it with [Context.request].
 */
class RemoteServiceRequest {


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

  RemoteServiceRequest.fromHttp(this._httpRequest);

  RemoteServiceRequest.fromSocket() : _httpRequest = null;

}



/**
 * The base class for servers.
 */
class ServiceServer {

}

