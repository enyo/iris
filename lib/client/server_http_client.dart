library server_http_client;


import "dart:io";
import "dart:async";
import "dart:convert";



import "package:protobuf/protobuf.dart";
import "package:logging/logging.dart";


import 'client.dart';
import '../remote/error_code.dart';
import '../src/consts.dart';


Logger log = new Logger("IrisClient");



/**
 * The Iris Client that communicates to the server from the browser.
 */
class HttpIrisClient extends IrisClient {


  /// The base URI for all requests.
  final Uri baseUri;

  HttpIrisClient(this.baseUri);


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

        if (response.statusCode < 200 || response.statusCode >= 400 || response.headers[ERROR_CODE_RESPONSE_HEADER] != null) {
          log.warning("Response with status code ${response.statusCode} from server: ${UTF8.decode(bytes)}");

          int errorCode = IrisErrorCode.IRIS_COMMUNICATION_ERROR.value;
          String message = "";

          try {
            message = UTF8.decode(bytes);
          }
          catch (e) { }

          if (response.headers[ERROR_CODE_RESPONSE_HEADER] != null) {
            errorCode = int.parse(response.headers[ERROR_CODE_RESPONSE_HEADER].first);
          }

          throw new IrisException(errorCode, message);
        }

        return getMessageFromBytes(expectedResponseType, bytes);
      })
      .catchError((error) {
        if (error is IrisException) {
          // Has already been handled
          throw error;
        } else {
          throw new IrisException(IrisErrorCode.IRIS_COMMUNICATION_ERROR.value, error.toString());
        }
      });

  }



}
