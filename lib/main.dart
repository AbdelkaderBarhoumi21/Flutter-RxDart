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

const things = [
  Thing(name: 'Foo', type: TypeOfThing.person),
  Thing(name: 'Bar', type: TypeOfThing.person),
  Thing(name: 'Baz', type: TypeOfThing.person),
  Thing(name: 'Bunz', type: TypeOfThing.animal),
  Thing(name: 'Fluffers', type: TypeOfThing.animal),
  Thing(name: 'Woofz', type: TypeOfThing.animal),
];

enum TypeOfThing { animal, person }

@immutable
class Thing {
  final TypeOfThing type;
  final String name;
  const Thing({required this.name, required this.type});
}

@immutable
class Bloc {
  final Sink<TypeOfThing?> setTypeOfThing; // write only
  final Stream<TypeOfThing?> currentTypeOfThing; // read only
  final Stream<Iterable<Thing>> things;
  // Safety: UI can only write to Sink, read from Stream
  factory Bloc({required Iterable<Thing> things}) {
    final typeOfThingSubject = BehaviorSubject<TypeOfThing?>();
    // startWith(things) this stream always startwith things when there is no emitted values yet
    final filteredThings = typeOfThingSubject
        .debounceTime(const Duration(milliseconds: 300))
        .map<Iterable<Thing>>((typeOfThing) {
          if (typeOfThing != null) {
            return things.where((thing) => thing.type == typeOfThing);
          } else {
            return things;
          }
        })
        .startWith(things);

    return Bloc._(
      setTypeOfThing: typeOfThingSubject.sink,
      currentTypeOfThing: typeOfThingSubject.stream,
      things: filteredThings,
    );
  }

  const Bloc._({
    required this.setTypeOfThing,
    required this.currentTypeOfThing,
    required this.things,
  });

  void dispose() {
    setTypeOfThing.close();
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
    bloc = Bloc(things: things);
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
      appBar: AppBar(title: const Text('Home Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<TypeOfThing?>(
              stream: bloc.currentTypeOfThing,
              builder: (context, snapshot) {
                final selectedTypeOfThing = snapshot.data;
                return Wrap(
                  spacing: 8.0,
                  children: TypeOfThing.values.map((typeOfThing) {
                    return FilterChip(
                      selectedColor: Colors.blue,
                      selected: selectedTypeOfThing == typeOfThing,
                      label: Text(typeOfThing.name),
                      onSelected: (selected) {
                        final type = selected ? typeOfThing : null;
                        bloc.setTypeOfThing.add(type);
                      },
                    );
                  }).toList(),
                );
              },
            ),

            Expanded(
              child: StreamBuilder<Iterable<Thing>>(
                stream: bloc.things,
                builder: (context, snapshot) {
                  final things = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: things.length,
                    itemBuilder: (context, index) {
                      final thing = things.elementAt(index);
                      return ListTile(
                        title: Text(thing.name),
                        subtitle: Text(thing.type.name),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
