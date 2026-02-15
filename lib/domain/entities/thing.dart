import 'package:flutter/foundation.dart' show immutable;

@immutable
class ThingModel {
  final String name;

  const ThingModel({required this.name});
}
