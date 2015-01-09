library browser_http_client;


import "dart:html";
import "dart:async";


import "package:protobuf/protobuf.dart";
import "package:logging/logging.dart";


import 'client.dart';

/// So the [IrisException] is visible.
export 'client.dart';

import '../remote/error_code.dart';
import 'dart:typed_data';

Logger log = new Logger("IrisClient");


/**
 * The Iris Client that communicates to the server from the browser.
 */
class HttpIrisClient extends IrisClient {


  /// The base URI for all requests.
  final Uri baseUri;

  final bool withCredentials;

  HttpIrisClient(this.baseUri, {this.withCredentials: true}) : super();


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
  Future<GeneratedMessage> query(String path, GeneratedMessage requestMessage, Function convertToMessage) {
    log.finest("Requesting address $path");

    var completer = new Completer();

    Uri uri = getUriFromPath(path);

    var xhr = new HttpRequest();

    xhr.open("POST", uri.toString(), async: true);

    xhr.withCredentials = withCredentials;

    xhr.responseType = "arraybuffer";

    xhr.setRequestHeader("Accept", "application/x-protobuf");

    _rejectWithError(IrisException exception) {
      logIrisException(exception);
      completer.completeError(exception);
    }

    xhr.onLoad.listen((e) {
      // Note: file:// URIs have status of 0.
      if (xhr.status >= 200 && xhr.status < 300) {

        completer.complete(getMessageFromBytes(convertToMessage, new Uint8List.view(xhr.response)));

      } else {

        _rejectWithError(getIrisExceptionFromBytes(new Uint8List.view(xhr.response)));

      }
    });

    xhr.onError.listen((err) {
      _rejectWithError(new IrisException(IrisErrorCode.IRIS_COMMUNICATION_ERROR.value, "There was a problem communicating with the iris server."));
    });

    xhr.send(requestMessage == null ? null : requestMessage.writeToBuffer());

    return completer.future;

  }


}
