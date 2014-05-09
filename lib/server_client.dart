library server_client;


import "dart:io";
import "dart:async";
import "dart:convert";



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

  HttpServiceClient(this.baseUri);


  /**
   * Returns an [Uri] with all the properties copied over from [baseUri] and the
   * path.
   */
  Uri getUriFromPath(String path) {
    return new Uri(scheme: baseUri.scheme, host: baseUri.host, port: baseUri.port, path: path);
  }


  Future<GeneratedMessage> query(String path, GeneratedMessage requestMessage, Type expectedResponseType) {

    HttpClient client = new HttpClient();

    Uri uri = getUriFromPath(path);

    log.finest("Requesting address ${uri.toString()}");

    HttpClientResponse response;

    return client.postUrl(uri)
      .then((HttpClientRequest request) {
        // Prepare the request then call close on it to send it.

        if (requestMessage != null) {
          var buffer = requestMessage.writeToBuffer();
          request.headers.add("Content-Length", buffer.length);
          request.headers.add("Content-Type", "application/x-protobuf");
          request.add(buffer);
        }
        return request.close();

      })
      .then((HttpClientResponse res) {
        response = res;
        return response.toList();
      })
      .then((List<List<int>> bytesCollection) {

        // TODO: optimise by copying to a fixed size array with setRange
        List<int> bytes = bytesCollection.expand((x) => x).toList(growable: false);

        if (response.statusCode < 200 || response.statusCode >= 400) {
          log.warning("Response from server: ${UTF8.decode(bytes)}");
          throw new Exception("Response was not 200 but ${response.statusCode} so trying to parse error response");
        }

        return getMessageFromBytes(expectedResponseType, bytes);
      })
      .catchError((error) {
        // TODO FIXME convert to RemoteServiceError
        throw error;
      });

  }



}
