import 'package:flutter/material.dart';
import 'package:flutter_rxdart/core/dialogs/app_dialog.dart';

// we added this =>'.then((value) => value ?? false)';
// because user may exit the dialog without clicking and it's return future<bool>
Future<bool> showLogoutDialog(BuildContext context) {
  return AppDialog(
    context: context,
    title: 'Logout',
    content: 'Are you sure you want to logout?',
    optionsBuilder: () => {'Cancel': false, 'Logout': true},
  ).then((value) => value ?? false);
}
