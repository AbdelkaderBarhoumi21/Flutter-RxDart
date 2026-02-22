import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdart/blocs/auth_blocs/auth_error.dart';
import 'package:flutter_rxdart/blocs/auth_blocs/auth_state.dart';
import 'package:flutter_rxdart/extension/stream_extension.dart';
import 'package:rxdart/rxdart.dart';

@immutable
class AuthBloc {
  // Read only steams
  final Stream<AuthStatus> authStatus;
  final Stream<AuthError?> authError;
  final Stream<bool> isLoading;
  final Stream<String?> userId;

  // Write only streams
  final Sink<LoginCommand> login;
  final Sink<RegisterCommand> register;
  final Sink<void> logout;

  const AuthBloc._({
    required this.authStatus,
    required this.authError,
    required this.isLoading,
    required this.userId,
    required this.login,
    required this.register,
    required this.logout,
  });

  factory AuthBloc() {
    final isLoading = BehaviorSubject<bool>.seeded(false);
    final Stream<AuthStatus> authStatus = FirebaseAuth.instance
        .authStateChanges()
        .map((user) {
          if (user != null) {
            return const AuthStatusLoggedIn();
          } else {
            return const AuthStatusLoggedOut();
          }
        });

    //final get user
    final Stream<String?> userId = FirebaseAuth.instance
        .authStateChanges()
        .map((user) => user?.uid)
        .startWith(FirebaseAuth.instance.currentUser?.uid);

    // login in + error handling
    final login = BehaviorSubject<LoginCommand>();
    final Stream<AuthError?> loginError = login
        .setLoadingTo(true, onSink: isLoading.sink)
        .asyncMap((loginCommand) async {
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: loginCommand.email,
              password: loginCommand.password,
            );
            return null;
          } on FirebaseAuthException catch (e) {
            return AuthError.fromFirebase(e);
          } catch (_) {
            return const AuthErrorUnknown();
          }
        })
        .setLoadingTo(false, onSink: isLoading.sink);

    // register in + error handling
    final register = BehaviorSubject<RegisterCommand>();
    final Stream<AuthError?> registerError = register
        .setLoadingTo(true, onSink: isLoading.sink)
        .asyncMap((registerCommand) async {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: registerCommand.email,
              password: registerCommand.password,
            );
            return null;
          } on FirebaseAuthException catch (e) {
            return AuthError.fromFirebase(e);
          } catch (_) {
            return const AuthErrorUnknown();
          }
        })
        .setLoadingTo(false, onSink: isLoading.sink);

    // logout in + error handling
    final logout = BehaviorSubject<Void>();
    final Stream<AuthError?> logoutError = logout
        .setLoadingTo(true, onSink: isLoading.sink)
        .asyncMap((_) async {
          try {
            await FirebaseAuth.instance.signOut();
            return null;
          } on FirebaseAuthException catch (e) {
            return AuthError.fromFirebase(e);
          } catch (_) {
            return const AuthErrorUnknown();
          }
        })
        .setLoadingTo(false, onSink: isLoading.sink);
    // delete user  + error handling
    final deleteAccount = BehaviorSubject<Void>();
    final Stream<AuthError?> deleteAccountError = deleteAccount
        .setLoadingTo(true, onSink: isLoading.sink)
        .asyncMap((_) async {
          try {
            await FirebaseAuth.instance.currentUser?.delete();
            return null;
          } on FirebaseAuthException catch (e) {
            return AuthError.fromFirebase(e);
          } catch (_) {
            return const AuthErrorUnknown();
          }
        })
        .setLoadingTo(false, onSink: isLoading.sink);
    // Auth error => login+ register +logout errors

    final Stream<AuthError?> authError = Rx.merge([
      loginError,
      registerError,
      logoutError,
      deleteAccountError,
    ]);
    return AuthBloc._(
      authStatus: authStatus,
      authError: authError,
      isLoading: isLoading,
      userId: userId,
      login: login.sink,
      register: register.sink,
      logout: logout.sink,
    );
  }

  void dispose() {
    login.close();
    register.close();
    logout.close();
  }
}
