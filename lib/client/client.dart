library client;

import "dart:mirrors";
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


  String toString() => "ServiceClientException with error code ${errorCode}." + (internalMessage == null ? "" : " Error: " + internalMessage);

}


/**
 * The base class for clients.
 */
abstract class IrisClient {


  /**
   * This is the method used to communicate with the remote service.
   */
  Future<GeneratedMessage> dispatch(String path, GeneratedMessage requestMessage, Type expectedResponseType, [requiredRequestMessage = true]) {
    if (requiredRequestMessage) {
      if (requestMessage == null) {
        throw new IrisException(IrisErrorCode.IRIS_REQUIRED_PB_MESSAGE_NOT_PROVIDED.value);
      }
      requestMessage.check();
    }
    return query(path, requestMessage, expectedResponseType)
        .then((GeneratedMessage responseMessage) {
          if (expectedResponseType != null && responseMessage == null) {
            throw new IrisException(IrisErrorCode.IRIS_REQUIRED_PB_MESSAGE_NOT_PROVIDED.value);
          }
          return responseMessage;
        });
  }

  Future<GeneratedMessage> query(String path, GeneratedMessage requestMessage, Type expectedResponseType);


  /**
   * Returns the proper [GeneratedMessage] or null if [expectedMessageType] is
   * `null`.
   */
  GeneratedMessage getMessageFromBytes(Type expectedMessageType, List<int> bytes) {
    if (expectedMessageType == null) {
      return null;
    } else {
      GeneratedMessage message = reflectClass(expectedMessageType).newInstance(const Symbol("fromBuffer"), [bytes]).reflectee;
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
 * A service on the client.
 */
abstract class Service {

  IrisClient client;

  Service(IrisClient this.client);

}