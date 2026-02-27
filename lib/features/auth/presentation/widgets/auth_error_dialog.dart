import 'package:flutter/material.dart';
import 'package:flutter_rxdart/features/auth/domain/auth_error.dart';
import 'package:flutter_rxdart/core/dialogs/app_dialog.dart';

Future<void> showAuthError({
  required AuthError authError,
  required BuildContext context,
}) {
  return AppDialog(
    context: context,
    title: authError.dialogTitle,
    content: authError.dialogText,
    optionsBuilder: () => {'OK': true},
  );
}
