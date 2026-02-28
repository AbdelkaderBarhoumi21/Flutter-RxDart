import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_rxdart/features/auth/domain/auth_error.dart';
import 'package:flutter_rxdart/features/auth/domain/auth_state.dart';
import 'package:flutter_rxdart/features/contacts/presentation/bloc/contacts_bloc.dart';
import 'package:flutter_rxdart/features/views/presentation/bloc/current_view.dart';
import 'package:flutter_rxdart/features/views/presentation/bloc/views_bloc.dart';
import 'package:flutter_rxdart/features/contacts/domain/contact_model.dart';
import 'package:rxdart/rxdart.dart';

@immutable
class AppBloc {
  final AuthBloc _authBloc;
  final ViewsBloc _viewsBloc;
  final ContactsBloc _contactsBloc;
  final StreamSubscription<String?> _userIdChanges;

  final Stream<CurrentView> currentView;
  final Stream<bool> isLoading;
  final Stream<AuthError?> authError;

  const AppBloc._({
    required AuthBloc authBloc,
    required ViewsBloc viewsBloc,
    required ContactsBloc contactsBloc,
    required StreamSubscription<String?> userIdChanges,
    required this.currentView,
    required this.isLoading,
    required this.authError,
  }) : _authBloc = authBloc,
       _viewsBloc = viewsBloc,
       _contactsBloc = contactsBloc,
       _userIdChanges = userIdChanges;

  void dispose() {
    _authBloc.dispose();
    _contactsBloc.dispose();
    _viewsBloc.dispose();
    _userIdChanges.cancel();
  }

  factory AppBloc() {
    final AuthBloc authBloc = AuthBloc();
    final ViewsBloc viewsBloc = ViewsBloc();
    final ContactsBloc contactsBloc = ContactsBloc();

    // pass user id from auth bloc to contacts bloc
    final userIdChanges = authBloc.userId.listen((String? userId) {
      contactsBloc.userId.add(userId);
    });

    // retrieved the current view from views bloc
    final Stream<CurrentView> currentViewBasedOnAuthStatus = authBloc.authStatus
        .map<CurrentView>((authStatus) {
          if (authStatus is AuthStatusLoggedIn) {
            return CurrentView.contactList;
          } else {
            return CurrentView.login;
          }
        });

    //current view
    final Stream<CurrentView> currentView = Rx.merge([
      currentViewBasedOnAuthStatus,
      viewsBloc.currentView,
    ]);

    // loading
    final Stream<bool> isLoading = Rx.merge([authBloc.isLoading]);

    return AppBloc._(
      authBloc: authBloc,
      viewsBloc: viewsBloc,
      contactsBloc: contactsBloc,
      userIdChanges: userIdChanges,
      currentView: currentView,
      isLoading: isLoading.asBroadcastStream(),
      authError: authBloc.authError.asBroadcastStream(),
    );
  }

  // delete contact
  void deleteContact(ContactModel contact) {
    _contactsBloc.deleteContact.add(contact);
  }

  //create contact
  void createContact({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) {
    _contactsBloc.createContact.add(
      ContactModel.withoutId(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      ),
    );
  }

  // All contacts
  Stream<Iterable<ContactModel>> get contacts => _contactsBloc.contacts;

  // Logout
  void logout() {
    _authBloc.logout.add(null);
  }

  // Register
  void register({required String email, required String password}) {
    _authBloc.register.add(RegisterCommand(email: email, password: password));
  }

  // login
  void login({required String email, required String password}) {
    _authBloc.login.add(LoginCommand(email: email, password: password));
  }

  // delete account
  void deleteAccount() {
    _contactsBloc.deleteAllContacts.add(null);
    _authBloc.deleteAccount.add(null);
  }

  // go to contacts view
  void goToContactListView() =>
      _viewsBloc.goToView.add(CurrentView.contactList);

  // go to create contacts view
  void goToCreateContactView() =>
      _viewsBloc.goToView.add(CurrentView.createContact);
  // go to login view
  void goToLoginView() => _viewsBloc.goToView.add(CurrentView.login);
  // go to register view
  void goToRegisterView() => _viewsBloc.goToView.add(CurrentView.register);
}
