///
//  Generated code. Do not modify.
///
library pb_authentication;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

class AuthenticationRequest extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('AuthenticationRequest')
    ..a(1, 'email', GeneratedMessage.QS)
    ..a(2, 'password', GeneratedMessage.QS)
  ;

  AuthenticationRequest() : super();
  AuthenticationRequest.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  AuthenticationRequest.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  AuthenticationRequest clone() => new AuthenticationRequest()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  String get email => getField(1);
  void set email(String v) { setField(1, v); }
  bool hasEmail() => hasField(1);
  void clearEmail() => clearField(1);

  String get password => getField(2);
  void set password(String v) { setField(2, v); }
  bool hasPassword() => hasField(2);
  void clearPassword() => clearField(2);
}

class AuthenticationResponse extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('AuthenticationResponse')
    ..a(3, 'success', GeneratedMessage.QB)
  ;

  AuthenticationResponse() : super();
  AuthenticationResponse.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  AuthenticationResponse.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  AuthenticationResponse clone() => new AuthenticationResponse()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  bool get success => getField(3);
  void set success(bool v) { setField(3, v); }
  bool hasSuccess() => hasField(3);
  void clearSuccess() => clearField(3);
}

