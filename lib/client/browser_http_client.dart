library browser_http_client;


import "dart:html";
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

  final bool withCredentials;

  HttpIrisClient(this.baseUri, {this.withCredentials: true});


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
   *
   * If the Future results in an error you can be sure to get a
   * [IrisException] error.
   *
   * You should never invoke this method directly but use [dispatch].
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

    _rejectWithError(IrisException exception) {
      log.warning("Error (${exception.errorCode}) from remote service: ${exception.internalMessage}");
      completer.completeError(exception);
    }

    xhr.onLoad.listen((e) {
      // Note: file:// URIs have status of 0.
      if (xhr.status >= 200 && xhr.status < 300 && !xhr.responseHeaders.containsKey(ERROR_CODE_RESPONSE_HEADER)) {

        completer.complete(getMessageFromBytes(expectedResponseType, xhr.response));

      } else {
        int errorCode = IrisErrorCode.IRIS_COMMUNICATION_ERROR.value;
        String message = UTF8.decode(xhr.response);

        if (xhr.responseHeaders.containsKey(ERROR_CODE_RESPONSE_HEADER)) {
          errorCode = xhr.responseHeaders[ERROR_CODE_RESPONSE_HEADER];
        }

        _rejectWithError(new IrisException(errorCode, message));
      }
    });

    xhr.onError.listen((err) {
      _rejectWithError(new IrisException(IrisErrorCode.IRIS_COMMUNICATION_ERROR.value, err.toString()));
    });

    xhr.send(requestMessage == null ? null : requestMessage.writeToBuffer());

    return completer.future;

  }


}
