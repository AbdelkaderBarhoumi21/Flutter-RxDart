import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rxdart/loading/loading_screen_controller.dart';

class LoadingScreen {
  LoadingScreen._sharedInstance();
  static final LoadingScreen _shared = LoadingScreen._sharedInstance();
  factory LoadingScreen.instance() => _shared;

  LoadingScreenController? controller;

  LoadingScreenController _showOverlay({
    required BuildContext context,
    required String text,
  }) {
    final _text = StreamController<String>();
    _text.add(text);

    final state = Overlay.of(context);
    final renderBox =
        context.findRenderObject()
            as RenderBox; // RendreBox type of Rendre object that'w why we cast as
    final size = renderBox.size;
  }
}
