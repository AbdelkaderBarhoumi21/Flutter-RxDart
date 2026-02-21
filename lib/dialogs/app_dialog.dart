import 'package:flutter/material.dart';

/// String => button text (cancel , ok)
/// T? returned value once button is clicked
/* {
  'Annuler': null,      ← button "Cancel" return null
  'Confirm': true,    ← button "Confirm" return true
  'Delete': false,   ← button "Delete" return false
}
*/
typedef DialogOptionBuilder<T> = Map<String, T?> Function();
Future<T?> AppDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required DialogOptionBuilder optionsBuilder,
}) {
  final options = optionsBuilder();
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: options.keys.map((optionTitle) {
          final value = options[optionTitle];
          return TextButton(
            onPressed: () {
              if (value != null) {
                Navigator.of(context).pop(value);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(optionTitle),
          );
        }).toList(),
      );
    },
  );
}
