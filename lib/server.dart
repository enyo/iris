part of remote_service;




/**
 * A class instantiated by the [RemoteServiceServer] whenever a request is made
 * either by HTTP, Socket or Websocket.
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
 * The base class for context classes.
 */
class Context {

   final RemoteServiceRequest req;

   Context(this.req);
}



/**
 * The base class for the remote_service server.
 */
class RemoteServiceServer<C extends Context> {

  final Function contextInitializer;

  RemoteServiceServer([this.contextInitializer]);

}



