library client;

import "dart:mirrors";
import "dart:async";

import "package:protobuf/protobuf.dart";
import "../remote/error_code.dart";

/**
 * Whenever an error occurs, this is the exception you get out of it.
 */
class ServiceClientException implements Exception {

  /// The error code received by the server.
  final int errorCode;

  /// An optional message **used for development only**! Do not show this to the
  /// user
  final String internalMessage;

  ServiceClientException(this.errorCode, [this.internalMessage]);


  String toString() => "ServiceClientException with error code ${errorCode}." + internalMessage == null ? "" : " Error: " + internalMessage;

}


/**
 * The base class for clients.
 */
abstract class ServiceClient {


  /**
   * This is the method used to communicate with the remote service.
   */
  Future<GeneratedMessage> dispatch(String path, GeneratedMessage requestMessage, Type expectedResponseType, [requiredRequestMessage = true]) {
    if (requiredRequestMessage) {
      if (requestMessage == null) {
        throw new ServiceClientException(RemoteServicesErrorCode.RS_REQUIRED_PB_MESSAGE_NOT_PROVIDED.value);
      }
      requestMessage.check();
    }
    return query(path, requestMessage, expectedResponseType)
        .then((GeneratedMessage responseMessage) {
          if (expectedResponseType != null && responseMessage == null) {
            throw new ServiceClientException(RemoteServicesErrorCode.RS_REQUIRED_PB_MESSAGE_NOT_PROVIDED.value);
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

}



/**
 * A service on the client.
 */
abstract class Service {

  ServiceClient client;

  Service(ServiceClient this.client);

}