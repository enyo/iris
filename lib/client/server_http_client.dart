library server_http_client;


import "dart:io";
import "dart:async";


import "package:protobuf/protobuf.dart";
import "package:logging/logging.dart";


import 'client.dart';

/// So the [IrisException] is visible.
export 'client.dart';

import '../remote/error_code.dart';


Logger log = new Logger("IrisClient");



/**
 * The Iris Client that communicates to the server from the browser.
 */
class HttpIrisClient extends IrisClient {


  /// The base URI for all requests.
  final Uri baseUri;

  HttpIrisClient(this.baseUri) : super();


  /**
   * Returns an [Uri] with all the properties copied over from [baseUri] and the
   * path.
   */
  Uri getUriFromPath(String path) {
    return new Uri(scheme: baseUri.scheme, host: baseUri.host, port: baseUri.port, path: path);
  }


  /**
   * If the Future results in an error you can be sure to get a
   * [IrisException] error.
   *
   * You should never invoke this method directly but use [dispatch].
   */
  Future<GeneratedMessage> query(String path, GeneratedMessage requestMessage, Function convertToMessage) {

    HttpClient client = new HttpClient();

    Uri uri = getUriFromPath(path);

    HttpClientResponse response;

    var requestFuture;

    if (requestMessage == null) {
      log.finest("Issuing GET request to ${uri.toString()}");
      requestFuture = client.getUrl(uri);

    }
    else {
      log.finest("Issuing POST request to ${uri.toString()}");
      requestFuture = client.postUrl(uri);
    }

    return requestFuture
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

        if (response.statusCode >= 200 && response.statusCode < 300) {

          return getMessageFromBytes(convertToMessage, bytes);

        }
        else {

          throw getIrisExceptionFromBytes(bytes);

        }

      })
      .catchError((error) {
        IrisException exception;
        if (error is IrisException) {
          // Has already been handled
          exception = error;
        } else {
          exception = new IrisException(IrisErrorCode.IRIS_COMMUNICATION_ERROR.value, error.toString());
        }
        logIrisException(exception);

        throw exception;
      });

  }



}
