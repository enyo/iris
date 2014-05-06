part of remote_services;


/**
 * The base class for all remote_services exceptions.
 */
class RemoteServicesException implements Exception {

  final String message;

  RemoteServicesException([this.message]);

}


/**
 * Thrown when a filter does not pass.
 */
class FilterException extends RemoteServicesException {

  final FilterFunction filter;

  FilterException(this.filter);

}


/**
 * Thrown whenever you call [RemoteServices.addService] with a [Service] that
 * contains invalid routes.
 */
class InvalidServiceDeclaration extends RemoteServicesException {

  final Service service;


  InvalidServiceDeclaration(String message, this.service) : super(message);
  String toString() => "The service you provided (${this.service.toString()}) was invalid: $message";

}





/**
 * Throw this in your routes when you want to send an error code to the client.
 */
class RouteException extends RemoteServicesException {

  final int errorCode;


  /**
   * You can pass an optiona [message] that will also be sent along to the client.
   *
   * Beware that his could potentially leak information if sent to a browser!
   */
  RouteException(this.errorCode, [message]) : super(message);

}

