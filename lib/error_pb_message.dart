/**
 * This library has initially been generated, but is now used as default transport
 * message for the remote_services library.
 */
library pb_error;

import 'package:protobuf/protobuf.dart';

class Error extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Error')
    ..a(666, 'message', GeneratedMessage.QS)
    ..a(999, 'code', GeneratedMessage.Q3)
  ;

  Error() : super();
  Error.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Error.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Error clone() => new Error()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  String get message => getField(666);
  void set message(String v) { setField(666, v); }
  bool hasMessage() => hasField(666);
  void clearMessage() => clearField(666);

  int get code => getField(999);
  void set code(int v) { setField(999, v); }
  bool hasCode() => hasField(999);
  void clearCode() => clearField(999);
}

