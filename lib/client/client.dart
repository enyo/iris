library client;

import "dart:mirrors";
import "dart:async";

import "package:protobuf/protobuf.dart";

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


  Future<GeneratedMessage> query(String path, GeneratedMessage requestMessage, Type expectedResponseType);


  getMessageFromBytes(Type expectedMessageType, List<int> bytes) {
    GeneratedMessage message = reflectClass(expectedMessageType).newInstance(const Symbol("fromBuffer"), [bytes]).reflectee;
    message.check();
    return message;
  }

}



/**
 * A service on the client.
 */
abstract class Service {

  ServiceClient client;

  Service(ServiceClient this.client);

}