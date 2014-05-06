library browser;


import "dart:html";
import "dart:async";
import "dart:mirrors";



import "package:protobuf/protobuf.dart";
import "package:logging/logging.dart";


import "client.dart";


Logger log = new Logger("RemoteServiceClient");



/**
 * The RemoteService Client that communicates to the server from the browser.
 */
class HttpServiceClient extends ServiceClient {


  /// The base URI for all requests.
  final Uri baseUri;

  final bool withCredentials;

  HttpServiceClient(this.baseUri, {this.withCredentials: false});


  /**
   * Returns an [Uri] with all the properties copied over from [baseUri] and the
   * path.
   */
  Uri getUriFromPath(String path) {
    return new Uri(scheme: baseUri.scheme, host: baseUri.host, port: baseUri.port, path: path);
  }


  /**
   * This method communicates with the backend server through HTTP requests, and
   * handling the responses.
   */
  Future<GeneratedMessage> query(String path, GeneratedMessage requestMessage, Type expectedResponseType) {
    log.finest("Requesting address $path");

    var completer = new Completer();

    Uri uri = getUriFromPath(path);

    var xhr = new HttpRequest();

    xhr.open("POST", uri.toString(), async: true);

    xhr.withCredentials = withCredentials;

    xhr.responseType = "arraybuffer";

    xhr.setRequestHeader("Accept", "application/x-protobuf");

    xhr.onLoad.listen((e) {
      // Note: file:// URIs have status of 0.
      if (xhr.status >= 200 && xhr.status < 300) {

        var message = reflectClass(expectedResponseType).newInstance(const Symbol("fromBuffer"), [ xhr.response ]).reflectee;
        completer.complete(message);

      } else {

        // TODO return ErrorMessage

      }
    });

    xhr.onError.listen((err) {
      //    completer.completeError(new messages.Error()
      //      ..code = error_codes.COMMUNICATION_ERROR);
    });

    xhr.send(requestMessage.writeToBuffer());

    return completer.future;

  }


}



//
///**
// * This class communicates with the backend server by making HTTP requests, and
// * handling the responses.
// */
//Future<GeneratedMessage> request(String path, Type messageType, {String method: "GET", GeneratedMessage sendMessage}) {
//
//  log.finest("Requesting address $path");
//
//  var sendData;
//
//  if (sendMessage != null) {
//    sendData = sendMessage.writeToBuffer();
//  }
//
//
//  var completer = new Completer();
//
//
//
//  var xhr = new HttpRequest();
//  xhr.open(method, "http://localhost:1337$path", async: true);
//
//  xhr.withCredentials = true;
//
//  xhr.responseType = "arraybuffer";
//
//  xhr.setRequestHeader("Accept", "application/x-protobuf");
//
////    xhr.setRequestHeader(header, value);
//
////    xhr.onProgress.listen(onProgress);
//
//  xhr.onLoad.listen((e) {
//    // Note: file:// URIs have status of 0.
//    if (xhr.status >= 200 && xhr.status < 300) {
//
//      var message = reflectClass(messageType).newInstance(const Symbol("fromBuffer"), [ xhr.response ]).reflectee;
//      completer.complete(message);
//
//    } else {
//
//      messages.Error errorMessage;
//      try {
//        errorMessage = new messages.Error.fromBuffer(xhr.response);
//        if (errorMessage.code == error_codes.AUTHORIZATION_REQUIRED) {
//          session.loggedOut();
//        }
//      }
//      catch(e) {
////        errorMessage = new messages.Error()
////          ..code = error_codes.COMMUNICATION_ERROR;
//      }
//      completer.completeError(errorMessage);
//
//    }
//  });
//
//  xhr.onError.listen((err) {
////    completer.completeError(new messages.Error()
////      ..code = error_codes.COMMUNICATION_ERROR);
//  });
//
//  if (sendData != null) {
//    xhr.send(sendData);
//  } else {
//    xhr.send();
//  }
//
//
//  return completer.future;
//
//}
