part of remote_services;


/**
 * The base class for all remote_services exceptions.
 */
class RemoteServicesException implements Exception {

  final String message;

  RemoteServicesException(this.message);

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