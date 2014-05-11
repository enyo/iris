library remote_services_error_code;

/**
 * Use this as base class for your error codes. Eg.:
 *
 *     class ErrorCode extends RemoteServicesErrorCode {
 *
 *       static const INVALID_USERNAME_OR_PASSWORD = const ErrorCode._(0);
 *
 *       static const INVALID_EMAIL = const ErrorCode._(1);
 *
 *       const ErrorCode._(int value) : super(value);
 *     }
 *
 * Error codes between 900 and 999 are reserved for internal codes, as well as
 * error code names starting with `RS_`, and you will get an exception when
 * trying to use them.
 *
 */
abstract class RemoteServicesErrorCode {

  final int value;

  /// Unable to communicate with the remote service.
  static const RS_COMMUNICATION_ERROR = const _InternalErrorCode._(900);

  /// Whenever an attempt to call a procedure that doesn't exist is made.
  static const RS_PROCEDURE_NOT_FOUND = const _InternalErrorCode._(901);

  /// Whenever an error on the server occured that wasn't recoverable.
  static const RS_INTERNAL_SERVER_ERROR = const _InternalErrorCode._(902);



  /// When the service received an invalid protocol buffer message
  static const RS_INVALID_PB_MESSAGE_RECEIVED_BY_SERVICE = const _InternalErrorCode._(910);

  /// When the client received an invalid protocol buffer message
  static const RS_INVALID_PB_MESSAGE_RECEIVED_BY_CLIENT = const _InternalErrorCode._(911);



  /// When a filter rejected the request
  static const RS_REJECTED_BY_FILTER = const _InternalErrorCode._(920);



  const RemoteServicesErrorCode(this.value);

}
class _InternalErrorCode extends RemoteServicesErrorCode {
  const _InternalErrorCode._(int value) : super(value);
}

