import 'package:flutter/foundation.dart';

@immutable
class GateId {
  final int value;

  const GateId(this.value);

  @override
  bool operator ==(Object other) => other is GateId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'gate-$value';
}
