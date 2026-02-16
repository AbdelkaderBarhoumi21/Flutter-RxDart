import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';

import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

void testIt() async {
  final stream1 = Stream.periodic(
    const Duration(seconds: 1),
    (count) => 'Stream 1, count= $count',
  );
  final stream2 = Stream.periodic(
    const Duration(seconds: 3),
    (count) => 'Stream 1, count= $count',
  );
  // combineLatest2 => mean combine 2 stream , combineLatest3 => mean combine 3 stream
  final combined = Rx.combineLatest2(
    stream1,
    stream2,
    (count1, count2) => 'one = ($count1) , two = ($count2)',
  );

  await for (final value in combined) {
    value.log();
  }
}

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    testIt();
    return Scaffold(
      appBar: AppBar(title: AppBar(title: Text('Home Page'))),
    );
  }
}
