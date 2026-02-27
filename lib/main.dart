import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rxdart/blocs/app_bloc.dart';
import 'package:flutter_rxdart/blocs/auth_blocs/auth_error.dart';
import 'package:flutter_rxdart/blocs/view_blocs/current_view.dart';
import 'package:flutter_rxdart/dialogs/auth_error_dialog.dart';
import 'package:flutter_rxdart/firebase_options.dart';
import 'package:flutter_rxdart/loading/loading_screen.dart';
import 'package:flutter_rxdart/views/pages/add_contact_page.dart';
import 'package:flutter_rxdart/views/pages/contacts_page.dart';
import 'package:flutter_rxdart/views/pages/login_page.dart';
import 'package:flutter_rxdart/views/pages/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //test();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      home: const HomePage(),
    );
  }
}

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
