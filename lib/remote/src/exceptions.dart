part of remote_services;


/**
 * The base class for all remote_services exceptions.
 */
class RemoteServicesException implements Exception {

  final String message;

  /**
   * This class has only a private constructor since it should only be
   * instantiated in this library.
   */
  RemoteServicesException._([this.message]);

}


/**
 * Thrown when a filter does not pass.
 *
 * This is a private class since it should never be visible by a consumer of
 * this library.
 */
class FilterException extends RemoteServicesException {

  final FilterFunction filter;

  String get filterName {
    ClosureMirror closure = reflect(filter);
    return MirrorSystem.getName(closure.function.simpleName);
  }

  FilterException(this.filter) : super._();

}


/**
 * Thrown whenever you call [RemoteServices.addService] with a [Service] that
 * contains invalid procedures.
 */
class InvalidServiceDeclaration extends RemoteServicesException {

  final Service service;


  InvalidServiceDeclaration._(String message, this.service) : super._(message);
  String toString() => "The service you provided (${this.service.toString()}) was invalid: $message";

}


/**
 * Thrown internally with the appropriate error code.
 */
class _ErrorCodeException extends RemoteServicesException {


  final RemoteServicesErrorCode errorCode;


  /**
   * You can pass an optiona [message] that will also be sent along to the client.
   *
   * Beware that his could potentially leak information if sent to a browser!
   */
  _ErrorCodeException(this.errorCode, [message]) : super._(message);

}



/**
 * Throw this in your procedures when you want to send an error code to the client.
 */
class ProcedureException extends RemoteServicesException {

  final RemoteServicesErrorCode errorCode;


  /**
   * You can pass an optiona [message] that will also be sent along to the client.
   *
   * Beware that his could potentially leak information if sent to a browser!
   */
  ProcedureException(this.errorCode, [message]) : super._(message);

}

