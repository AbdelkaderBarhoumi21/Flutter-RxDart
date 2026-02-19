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
      ),
      home: const HomePage(),
    );
  }
}

@immutable
class Bloc {
  final Sink<String?> setFirstName; // write only(producer)
  final Sink<String?> setLastName; // write only(producer)
  final Stream<String> fullName; //read only(consumer)

  factory Bloc() {
    final firstNameSubject = BehaviorSubject<String?>();
    final lastNameSubject = BehaviorSubject<String?>();
    final Stream<String> fullName = Rx.combineLatest2(
      firstNameSubject.startWith(null),
      lastNameSubject.startWith(null),
      (String? firstName, String? lastName) {
        if (firstName != null &&
            firstName.isNotEmpty &&
            lastName != null &&
            lastName.isNotEmpty) {
          return '$firstName $lastName';
        } else {
          return 'Both first and last name must been provided';
        }
      },
    );

    return Bloc._(
      fullName: fullName,
      setFirstName: firstNameSubject.sink,
      setLastName: lastNameSubject.sink,
    );
  }
  const Bloc._({
    required this.fullName,
    required this.setFirstName,
    required this.setLastName,
  });

  void dispose() {
    setFirstName.close();
    setLastName.close();
  }
}

typedef AsyncSnapshotBuilderCallback<T> =
    Widget Function(BuildContext context, T? value);

class AsyncSnapshotBuilder<T> extends StatelessWidget {
  const AsyncSnapshotBuilder({
    required this.stream,
    this.onNone,
    this.onWaiting,
    this.onActive,
    this.onDone,
    super.key,
  });
  final Stream<T> stream;
  final AsyncSnapshotBuilderCallback<T>? onNone;
  final AsyncSnapshotBuilderCallback<T>? onWaiting;
  final AsyncSnapshotBuilderCallback<T>? onActive;
  final AsyncSnapshotBuilderCallback<T>? onDone;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            final callBack = onNone ?? (_, _) => SizedBox.shrink();
            return callBack(context, snapshot.data);
          case ConnectionState.waiting:
            final callBack = onWaiting ?? (_, _) => CircularProgressIndicator();
            return callBack(context, snapshot.data);
          case ConnectionState.active:
            final callBack = onActive ?? (_, _) => SizedBox.shrink();
            return callBack(context, snapshot.data);
          case ConnectionState.done:
            final callBack = onDone ?? (_, _) => SizedBox.shrink();
            return callBack(context, snapshot.data);
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Bloc bloc;
  @override
  void initState() {
    bloc = Bloc();
    super.initState();
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CombineLatest RxDart')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Enter first name'),
              onChanged: bloc.setFirstName.add,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(hintText: 'Enter last name'),
              onChanged: bloc.setLastName.add,
            ),
            SizedBox(height: 16),
            AsyncSnapshotBuilder(
              stream: bloc.fullName,
              onActive: (context, String? value) {
                return Text(value ?? '');
              },
            ),
          ],
        ),
      ),
    );
  }
}
