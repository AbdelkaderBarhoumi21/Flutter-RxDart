import 'package:flutter/foundation.dart';

typedef CloseLoadingScreen = bool Function(); // () => true
typedef UpdateLoadingScreen = bool Function(String string); // (message) => true

@immutable
class LoadingScreenController {
  final CloseLoadingScreen close;
  final UpdateLoadingScreen update;
  const LoadingScreenController({required this.close, required this.update});
}
