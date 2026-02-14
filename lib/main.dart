import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

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

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Every rebuild of this widget will create a new BehaviorSubject, but it will only be created once due to useMemoized => key ref to super.key.
    final subject = useMemoized(() => BehaviorSubject<String>(), [key]);
    // useEffect will run the provided function when the widget is disposed, ensuring that the subject is properly closed to prevent memory leaks.
    useEffect(() => subject.close, [subject]);
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder(
          stream: subject.stream.distinct().debounceTime(
            const Duration(seconds: 1),
          ),
          initialData: 'Please start typing....',
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (snapshot.hasData) {
              return Text(snapshot.requireData);
            }
            return const Text('Type something');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onChanged: (value) {
            subject.sink.add(value);
          },
        ),
      ),
    );
  }
}
