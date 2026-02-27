import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rxdart/features/app/presentation/bloc/app_bloc.dart';
import 'package:flutter_rxdart/features/auth/domain/auth_error.dart';
import 'package:flutter_rxdart/features/home/presentation/page/home_page.dart';
import 'package:flutter_rxdart/features/views/presentation/bloc/current_view.dart';
import 'package:flutter_rxdart/features/auth/presentation/widgets/auth_error_dialog.dart';
import 'package:flutter_rxdart/config/firebase_options.dart';
import 'package:flutter_rxdart/core/loading/loading_screen.dart';
import 'package:flutter_rxdart/features/contacts/presentation/pages/add_contact_page.dart';
import 'package:flutter_rxdart/features/contacts/presentation/pages/contacts_page.dart';
import 'package:flutter_rxdart/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_rxdart/features/auth/presentation/pages/register_page.dart';

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

