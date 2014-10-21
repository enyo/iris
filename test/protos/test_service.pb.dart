///
//  Generated code. Do not modify.
///
library test_service;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

class File extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('File')
    ..a(1, 'path', GeneratedMessage.QS)
  ;

  File() : super();
  File.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  File.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  File clone() => new File()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  String get path => getField(1);
  void set path(String v) { setField(1, v); }
  bool hasPath() => hasField(1);
  void clearPath() => clearField(1);
}

class UploadFileRequest extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('UploadFileRequest')
    ..a(1, 'contentType', GeneratedMessage.OS)
    ..hasRequiredFields = false
  ;

  UploadFileRequest() : super();
  UploadFileRequest.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  UploadFileRequest.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  UploadFileRequest clone() => new UploadFileRequest()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  String get contentType => getField(1);
  void set contentType(String v) { setField(1, v); }
  bool hasContentType() => hasField(1);
  void clearContentType() => clearField(1);
}

class UploadFileResponse extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('UploadFileResponse')
    ..a(2, 'contentType', GeneratedMessage.OS)
    ..a(3, 'uploadPath', GeneratedMessage.QS)
  ;

  UploadFileResponse() : super();
  UploadFileResponse.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  UploadFileResponse.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  UploadFileResponse clone() => new UploadFileResponse()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  String get contentType => getField(2);
  void set contentType(String v) { setField(2, v); }
  bool hasContentType() => hasField(2);
  void clearContentType() => clearField(2);

  String get uploadPath => getField(3);
  void set uploadPath(String v) { setField(3, v); }
  bool hasUploadPath() => hasField(3);
  void clearUploadPath() => clearField(3);
}

