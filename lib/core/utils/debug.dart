import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

extension debuging on String {
  String? get isDebugging => kDebugMode ? this : null;
}

// Examples
void test() {
  final result = "hello".isDebugging;
  debugPrint('==================================$result');
}
