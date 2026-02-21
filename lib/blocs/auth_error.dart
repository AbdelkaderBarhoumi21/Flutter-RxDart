import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart';

const Map<String, AuthError> authErrorMapping = {
  'user-not-found': AuthErrorUserNotFound(),
  'weak-password': AuthErrorWeakPassword(),
  'invalid-email': AuthErrorInvalidEmail(),
  'email-already-in-use': AuthErrorEmailAlreadyInUse(),
  'operation-not-allowed': AuthErrorOperationNotAllowed(),
  'no-current-user': AuthErrorNoCurrentUser(),
  'requires-recent-login': AuthErrorRequiresRecentLogin(),
};

@immutable
abstract class AuthError {
  final String dialogTitle;
  final String dialogText;

  const AuthError({required this.dialogTitle, required this.dialogText});

  factory AuthError.fromFirebase(FirebaseAuthException exception) =>
      authErrorMapping[exception.code.toLowerCase().trim()] ??
      const AuthErrorUnknown();
}

@immutable
class AuthErrorUnknown extends AuthError {
  const AuthErrorUnknown()
    : super(
        dialogTitle: 'Authentication error',
        dialogText: 'Unknown authentication error',
      );
}

//auth -no current user
@immutable
class AuthErrorRequiresRecentLogin extends AuthError {
  const AuthErrorRequiresRecentLogin()
    : super(
        dialogTitle: 'Requires recent login',
        dialogText:
            'You need to log out and log back in again in order to perform this operation',
      );
}

//auth -no current user
@immutable
class AuthErrorNoCurrentUser extends AuthError {
  const AuthErrorNoCurrentUser()
    : super(
        dialogTitle: 'No current user',
        dialogText: 'No current user found',
      );
}

// operation not alloweed
@immutable
class AuthErrorOperationNotAllowed extends AuthError {
  const AuthErrorOperationNotAllowed()
    : super(
        dialogTitle: 'Operation not allowed',
        dialogText: 'You cannot perform this operation',
      );
}

// User not found
@immutable
class AuthErrorUserNotFound extends AuthError {
  const AuthErrorUserNotFound()
    : super(
        dialogTitle: 'User not found',
        dialogText: 'The given user was not found on the server',
      );
}

// Weak password
@immutable
class AuthErrorWeakPassword extends AuthError {
  const AuthErrorWeakPassword()
    : super(
        dialogTitle: 'Weak password',
        dialogText:
            'Please choose a stronger password consisting of more characters',
      );
}

// Invalid email
@immutable
class AuthErrorInvalidEmail extends AuthError {
  const AuthErrorInvalidEmail()
    : super(
        dialogTitle: 'Invalid email',
        dialogText: 'Please double check your email and try again',
      );
}

// Email already in use
@immutable
class AuthErrorEmailAlreadyInUse extends AuthError {
  const AuthErrorEmailAlreadyInUse()
    : super(
        dialogTitle: 'Email already in use',
        dialogText: 'Please choose another email to register with',
      );
}
