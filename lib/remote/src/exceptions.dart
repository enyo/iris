part of iris;


/**
 * The base class for all remotes exceptions.
 */
class IrisException implements Exception {

  final String message;

  /**
   * This class has only a private constructor since it should only be
   * instantiated in this library.
   */
  IrisException._([this.message]);

}


/**
 * Thrown when a filter does not pass.
 *
 * This is a private class since it should never be visible by a consumer of
 * this library.
 */
class FilterException extends IrisException {

  final FilterFunction filter;

  String get filterName {
    ClosureMirror closure = reflect(filter);
    return MirrorSystem.getName(closure.function.simpleName);
  }

  FilterException(this.filter) : super._();

}


/**
 * Thrown whenever you call [Iris.addRemote] with a [Remote] that
 * contains invalid procedures.
 */
class InvalidRemoteDeclaration extends IrisException {

  final Remote remote;


  InvalidRemoteDeclaration._(String message, this.remote) : super._(message);
  String toString() => "The remote you provided (${this.remote.toString()}) was invalid: $message";

}


/**
 * Thrown internally with the appropriate error code.
 */
class _ErrorCodeException extends IrisException {


  final IrisErrorCode errorCode;


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
class ProcedureException extends IrisException {

  final IrisErrorCode errorCode;


  /**
   * You can pass an optiona [message] that will also be sent along to the client.
   *
   * Beware that his could potentially leak information if sent to a browser!
   */
  ProcedureException(this.errorCode, [message]) : super._(message);

}

