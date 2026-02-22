import 'package:flutter/material.dart';
import 'package:flutter_rxdart/dialogs/app_dialog.dart';

// we added this =>'.then((value) => value ?? false)';
// because user may exit the dialog without clicking and it's return future<bool>
Future<bool> showDeleteAccountDialog(BuildContext context) {
  return AppDialog(
    context: context,
    title: 'Delete Account',
    content: 'Are you sure you want to delete your account?',
    optionsBuilder: () => {'Cancel': false, 'Delete': true},
  ).then((value) => value ?? false);
}
