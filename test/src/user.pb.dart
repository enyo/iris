///
//  Generated code. Do not modify.
///
library pb_user;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

class User extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('User')
    ..a(1, 'id', GeneratedMessage.Q6, () => makeLongInt(0))
    ..a(2, 'email', GeneratedMessage.QS)
    ..a(3, 'name', GeneratedMessage.OS)
  ;

  User() : super();
  User.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  User.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  User clone() => new User()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  Int64 get id => getField(1);
  void set id(Int64 v) { setField(1, v); }
  bool hasId() => hasField(1);
  void clearId() => clearField(1);

  String get email => getField(2);
  void set email(String v) { setField(2, v); }
  bool hasEmail() => hasField(2);
  void clearEmail() => clearField(2);

  String get name => getField(3);
  void set name(String v) { setField(3, v); }
  bool hasName() => hasField(3);
  void clearName() => clearField(3);
}

class UserSearch extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('UserSearch')
    ..a(4, 'name', GeneratedMessage.QS)
  ;

  UserSearch() : super();
  UserSearch.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  UserSearch.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  UserSearch clone() => new UserSearch()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;

  String get name => getField(4);
  void set name(String v) { setField(4, v); }
  bool hasName() => hasField(4);
  void clearName() => clearField(4);
}

