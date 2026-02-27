import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rxdart/features/app/presentation/bloc/app_bloc.dart';
import 'package:flutter_rxdart/features/auth/domain/auth_error.dart';
import 'package:flutter_rxdart/features/views/presentation/bloc/current_view.dart';
import 'package:flutter_rxdart/features/auth/presentation/widgets/auth_error_dialog.dart';
import 'package:flutter_rxdart/core/loading/loading_screen.dart';
import 'package:flutter_rxdart/features/contacts/presentation/pages/add_contact_page.dart';
import 'package:flutter_rxdart/features/contacts/presentation/pages/contacts_page.dart';
import 'package:flutter_rxdart/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_rxdart/features/auth/presentation/pages/register_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AppBloc appBloc;
  StreamSubscription<AuthError?>? _authError;
  StreamSubscription<bool>? _isLoading;

  @override
  void initState() {
    appBloc = AppBloc();
    super.initState();
  }

  @override
  void dispose() {
    appBloc.dispose();
    _authError?.cancel();
    _isLoading?.cancel();
    super.dispose();
  }

  void handleAuthErrors(BuildContext context) async {
    await _authError?.cancel();

    _authError = appBloc.authError.listen((event) {
      final AuthError? authError = event;
      if (authError == null) {
        return;
      }
      showAuthError(authError: authError, context: context);
    });
  }

  void setUpLoadingScreen(BuildContext context) async {
    await _isLoading?.cancel();
    _isLoading = appBloc.isLoading.listen((isLoading) {
      if (isLoading) {
        LoadingScreen.instance().show(context: context, text: 'Loading...');
      } else {
        LoadingScreen.instance().hide();
      }
    });
  }

  Widget getHomePage() {
    return StreamBuilder<CurrentView>(
      stream: appBloc.currentView,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          case ConnectionState.active:
          case ConnectionState.done:
            final currentView = snapshot.requireData;
            switch (currentView) {
              case CurrentView.login:
                return LoginPage(
                  goToRegisterView: appBloc.goToRegisterView,
                  login: appBloc.login,
                );
              case CurrentView.register:
                return RegisterPage(
                  goToLoginView: appBloc.goToLoginView,
                  register: appBloc.register,
                );
              case CurrentView.contactList:
                return ContactsPage(
                  logoutCallback: appBloc.logout,
                  deleteAccountCallback: appBloc.deleteAccount,
                  deleteContactCallback: appBloc.deleteContact,
                  createNewContact: appBloc.goToCreateContactView,
                  contacts: appBloc.contacts,
                );
              case CurrentView.createContact:
                return AddContactPage(
                  createContact: appBloc.createContact,
                  goBack: appBloc.goToContactListView,
                );
            }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    handleAuthErrors(context);
    setUpLoadingScreen(context);
    return getHomePage();
  }
}
