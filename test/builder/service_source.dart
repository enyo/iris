library service_source;

import 'dart:async';

import 'package:iris/remote/iris.dart' as iris;
import '../protos/test_service.pb.dart';

Future<bool> filter(iris.Context context){
  return new Future.value(true);
}

@iris.IrisService('test' '/services.proto', filters: const [filter])
class FileService {
  Future<UploadFileResponse> uploadFile(iris.Context irisContext, UploadFileRequest request) {
    //Do nothing.
    return null;
  }
}