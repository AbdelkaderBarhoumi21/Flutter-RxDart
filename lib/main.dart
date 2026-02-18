import 'package:flutter/material.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(backgroundColor: Colors.blue),
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
  late final BehaviorSubject<DateTime>
  subject; // Get the last emitted value when subscribed
  late final Stream<String> streamOfThings;

  @override
  void initState() {
    subject = BehaviorSubject<DateTime>();
    // SwitchMap convert each emitted value value into a stream
    // cancel the previous inner stream when a values arrives => switchMap is the inner stream
    // Always shows results from the most recent emission
    streamOfThings = subject.switchMap(
      (dateTime) => Stream.periodic(
        const Duration(seconds: 1),
        (count) => 'Stream count = $count, dateTme = $dateTime',
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    subject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder(
              stream: streamOfThings,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final string = snapshot.requireData;
                  return Text(string);
                } else {
                  return const Text('Waiting for the button to be pressed');
                }
              },
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                subject.add(DateTime.now());
              },
              child: Text('start the stream'),
            ),
          ],
        ),
      ),
    );
  }
}
