library browser_http_client;


import "dart:html";
import "dart:async";



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

        completer.complete(getMessageFromBytes(expectedResponseType, xhr.response));

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
