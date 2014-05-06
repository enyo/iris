part of remote_services;



/**
 * Thrown whenever you call [RemoteServices.addService] with a [Service] that
 * contains invalid routes.
 */
class InvalidServiceDeclaration {

  final String message;

  final Service service;

  InvalidServiceDeclaration(this.message, this.service);

  String toString() => "The service you provided (${this.service.toString()}) was invalid: $message";

}