library client;


import "dart:async";
import "package:protobuf/protobuf.dart";


/**
 * The base class for clients.
 */
abstract class ServiceClient {


  Future<GeneratedMessage> query(String path, GeneratedMessage requestMessage, Type expectedResponseType);

}



/**
 * A service on the client.
 */
abstract class Service {

  ServiceClient client;

  Service(ServiceClient this.client);

}