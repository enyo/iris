library pb_iris_error;

import 'package:protobuf/protobuf.dart';

class IrisErrorMessage extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('IrisErrorMessage')
    ..a(9998, 'errorCode', GeneratedMessage.Q3)
    ..a(9999, 'message', GeneratedMessage.QS)
  ;

  IrisErrorMessage() : super();
  IrisErrorMessage.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  IrisErrorMessage.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  IrisErrorMessage clone() => new IrisErrorMessage()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  int get errorCode => getField(9998);
  void set errorCode(int v) { setField(9998, v); }
  bool hasErrorCode() => hasField(9998);
  void clearErrorCode() => clearField(9998);

  String get message => getField(9999);
  void set message(String v) { setField(9999, v); }
  bool hasMessage() => hasField(9999);
  void clearMessage() => clearField(9999);
}

