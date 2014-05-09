library client;

import "dart:mirrors";
import "dart:async";
import "package:protobuf/protobuf.dart";


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