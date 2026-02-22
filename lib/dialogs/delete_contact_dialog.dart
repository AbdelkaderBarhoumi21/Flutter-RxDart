import 'package:flutter/material.dart';
import 'package:flutter_rxdart/dialogs/app_dialog.dart';

// we added this =>'.then((value) => value ?? false)';
// because user may exit the dialog without clicking and it's return future<bool>
Future<bool> showDeleteContactDialog(BuildContext context) {
  return AppDialog(
    context: context,
    title: 'Delete Contact',
    content: 'Are you sure you want to delete this contact?',
    optionsBuilder: () => {'Cancel': false, 'Delete': true},
  ).then((value) => value ?? false);
}
