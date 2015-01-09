library client;

import "dart:async";
import "dart:convert";

import "package:logging/logging.dart";
import "package:protobuf/protobuf.dart";
import '../remote/error_code.dart';
import '../src/error_message.dart';




Logger log = new Logger("IrisClient");


/**
 * Whenever an error occurs, this is the exception you get out of it.
 */
class IrisException implements Exception {

  /// The error code received by the server.
  final int errorCode;

  /// An optional message **used for development only**! Do not show this to the
  /// user
  final String internalMessage;

  IrisException(this.errorCode, [this.internalMessage]);


  String toString() => "IrisException with error code ${errorCode}." + (internalMessage == null ? "" : " Error: " + internalMessage);

}


/**
 * The base class for clients.
 */
abstract class IrisClient {


  /// Controlling [onError]
  StreamController<IrisException> _onErrorController;

  /// You can listen on this stream to get all exceptions that are generated
  /// by this client. This allows you to globally listen to exceptions (for
  /// example, AuthenticationRequired error codes).
  Stream<IrisException> onError;

  IrisClient() {
    _onErrorController = new StreamController<IrisException>();
    onError = _onErrorController.stream.asBroadcastStream();
  }


  /**
   * This is the method used to communicate with the remote.
   */
  Future<GeneratedMessage> dispatch(String path, GeneratedMessage requestMessage, Function convertToMessage, [requiredRequestMessage = true]) {
    if (requiredRequestMessage) {
      if (requestMessage == null) {
        throw new IrisException(IrisErrorCode.IRIS_REQUIRED_PB_MESSAGE_NOT_PROVIDED.value);
      }
      requestMessage.check();
    }
    return query(path, requestMessage, convertToMessage)
        .then((GeneratedMessage responseMessage) {
          if (convertToMessage != null && responseMessage == null) {
            throw new IrisException(IrisErrorCode.IRIS_REQUIRED_PB_MESSAGE_NOT_PROVIDED.value);
          }
          return responseMessage;
        })
        .catchError((IrisException exception) {
          _onErrorController.add(exception);
          throw exception;
        });
  }

  Future<GeneratedMessage> query(String path, GeneratedMessage requestMessage, Function convertToMessage);


  /**
   * Returns the proper [GeneratedMessage] or null if [convertToMessage] is
   * `null`.
   */
  GeneratedMessage getMessageFromBytes(Function convertToMessage, List<int> bytes) {
    if (convertToMessage == null) {
      return null;
    } else {
      GeneratedMessage message = convertToMessage(bytes);
      message.check();
      return message;
    }
  }


  /**
   * Takes a list of bytes, tries to map it to a [IrisErrorMessage] and
   * returns an [IrisException] with given values.
   *
   * If the bytes are not a proper [IrisErrorMessage], it will generate an
   * [IrisException] with the appropriate error codes.
   */
  IrisException getIrisExceptionFromBytes(List<int> bytes) {

    int errorCode;
    String message;

    try {
      IrisErrorMessage pbMessage = new IrisErrorMessage.fromBuffer(bytes);
      pbMessage.check();
      errorCode = pbMessage.errorCode;
      message = pbMessage.message;
    }
    catch (e) {
      int errorCode = IrisErrorCode.IRIS_COMMUNICATION_ERROR.value;
      String message = UTF8.decode(bytes);
    }

    return new IrisException(errorCode, message);
  }


  logIrisException(IrisException exception) {
    log.warning("Iris Error (${exception.errorCode}): ${exception.internalMessage}");
  }


}



/**
 * A remote on the client.
 */
abstract class Remote {

  IrisClient client;

  Remote(IrisClient this.client);

}