import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rxdart/core/loading/loading_screen_controller.dart';

class LoadingScreen {
  LoadingScreen._sharedInstance();
  static final LoadingScreen _shared = LoadingScreen._sharedInstance();
  factory LoadingScreen.instance() => _shared;

  LoadingScreenController? controller;

  /// Shows a loading overlay with the given text.
  ///
  /// If an overlay is already showing (controller != null), it updates the text.
  /// Otherwise, creates a new overlay.
  void show({required BuildContext context, required String text}) {
    if (controller?.update(text) ?? false) {
      // Overlay exists, just update the text
      return;
    } else {
      // No overlay exists, create a new one
      controller = _showOverlay(context: context, text: text);
    }
  }

  /// Hides the loading overlay and cleans up resources.
  ///
  /// **Why set controller = null?**
  /// 1. **Memory Management**: Releases the reference to the controller, allowing
  ///    the garbage collector to free up memory once close() is called.
  /// 2. **State Management**: Indicates that no overlay is currently active,
  ///    which is checked in show() to decide whether to update or create new overlay.
  /// 3. **Prevent Errors**: Avoids calling methods on an already closed controller.
  ///    Multiple calls to hide() won't crash because null?.close() is safe.
  /// 4. **Clean State**: Ensures the next show() call creates a fresh overlay
  ///    instead of trying to update a closed one.
  void hide() {
    controller?.close(); // Close the overlay and its stream
    controller = null; // Release reference for garbage collection & state reset
  }

  LoadingScreenController _showOverlay({
    required BuildContext context,
    required String text,
  }) {
    final _text = StreamController<String>();
    _text.add(text);

    final renderBox = context.findRenderObject() as RenderBox;
    final currentSize = renderBox.size;
    final overlay = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black.withAlpha(150),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: currentSize.width * 0.8,
                minWidth: currentSize.width * 0.5,
                maxHeight: currentSize.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  spacing: 10.0,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    StreamBuilder<String>(
                      stream: _text.stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            snapshot.data!,
                            textAlign: TextAlign.center,
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // display the overlay
    final state = Overlay.of(context);
    state.insert(overlay);

    return LoadingScreenController(
      close: () {
        _text.close();
        overlay.remove();
        return true;
      },
      update: (text) {
        _text.add(text);
        return true;
      },
    );
  }
}
