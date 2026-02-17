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

/*
this mean every time you apply operator in your stream you create a new instance => create new stream 
final result =foo             //stream 1
              .take(3)        //stream 2
              .debounce()     //stream 3
              .merge()        //stream 4
              .concat()       //stream 5
*/
// concat is good for API Call

void testIt() async {
  final stream1 = Stream.periodic(
    const Duration(seconds: 1),
    (count) => 'Stream 1, count= $count',
  ).take(3);
  final stream2 = Stream.periodic(
    const Duration(seconds: 5),
    (count) => 'Stream 2, count= $count',
  );

  final result = Rx.zip2(
    stream1,
    stream2,
    (a, b) => 'zipped result , A=$a , B=$b',
  );
  // final result = stream1.mergeWith([stream2]);
  // final result = stream1.concatWith([stream2]);
  await for (final value in result) {
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
