import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

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

Stream<String> getNames({required String filePath}) {
  final names = rootBundle.loadString(filePath);
  final result = Stream.fromFuture(names).transform((const LineSplitter()));
  return result;
}

Stream<String> getAllNames() => getNames(
  filePath: 'assets/texts/cats.txt',
).concatWith([getNames(filePath: 'assets/texts/dogs.txt')]);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    //toList there collect all elements of this stream in a [List]
    return Scaffold(
      appBar: AppBar(title: const Text('RxDart concat')),
      body: FutureBuilder(
        future: getAllNames().toList(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return const Center(child: CircularProgressIndicator());
            case ConnectionState.done:
              final names = snapshot.requireData;
              return ListView.separated(
                separatorBuilder: (context, index) => SizedBox(width: 16),
                itemCount: names.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(names[index]));
                },
              );
          }
        },
      ),
    );
  }
}
