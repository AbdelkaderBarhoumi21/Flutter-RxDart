# Why BehaviorSubject is Both a Sink AND a Stream

`BehaviorSubject` implements **both interfaces**: it can be used as a `Stream` (reading) AND as a `Sink` (writing).

---

## Class Hierarchy

```dart
BehaviorSubject<T>
    ↓ extends
Subject<T>
    ↓ implements
Stream<T>          // Reading (listen, map, where, etc.)
StreamController<T> // Management
Sink<T>            // Writing (add, addError, close)
```

---

## BehaviorSubject = 3 in 1

```dart
final subject = BehaviorSubject<int>();

// 1️⃣ As a Sink (writing)
subject.add(10);           // ← Write a value
subject.addError('error'); // ← Write an error
subject.close();           // ← Close the stream

// 2️⃣ As a Stream (reading)
subject.listen((value) => print(value)); // ← Listen
subject.map((x) => x * 2);               // ← Transform
subject.where((x) => x > 5);             // ← Filter

// 3️⃣ Direct value access (BehaviorSubject-specific)
int currentValue = subject.value;        // ← Read without listening
bool hasValue = subject.hasValue;        // ← Check if a value exists
```

---

## Why is BehaviorSubject a Sink?

### Simplified Source Code

```dart
class BehaviorSubject<T> extends Subject<T> {
  // Implements Sink<T>
  @override
  void add(T value) {
    _value = value;           // Store the last value
    _controller.add(value);   // Emit to the stream
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  Future close() {
    return _controller.close();
  }

  // Special property
  T get value => _value;
}
```

**Because it implements `Sink<T>`**, you can:
- `.add(value)` to emit
- `.addError(error)` for errors
- `.close()` to close

---

## Practical Example

```dart
import 'package:rxdart/rxdart.dart';

void main() {
  final subject = BehaviorSubject<int>.seeded(0);

  // Use as Sink (writing)
  subject.add(1);
  subject.add(2);
  subject.add(3);

  // Use as Stream (reading)
  subject.listen((value) {
    print('Received: $value');
  });

  // Direct access (BehaviorSubject-specific)
  print('Current value: ${subject.value}'); // 3

  // Add more values
  subject.add(4);
  subject.add(5);

  subject.close();
}

/* Output:
Received: 3  ← New subscriber immediately receives the last value
Received: 4
Received: 5
Current value: 3
*/
```

---

## Comparison with StreamController

### StreamController (separate)

```dart
final controller = StreamController<int>();

// Sink and Stream are SEPARATE
Sink<int> sink = controller.sink;     // Writing
Stream<int> stream = controller.stream; // Reading

sink.add(10);        // ✅ Writing
stream.listen(...);  // ✅ Reading

// ❌ Cannot do:
controller.add(10);  // Error! Must use controller.sink.add()
```

### BehaviorSubject (unified)

```dart
final subject = BehaviorSubject<int>();

// Sink and Stream are UNIFIED
subject.add(10);     // ✅ Direct writing
subject.listen(...); // ✅ Direct reading

// Or access via .sink and .stream if needed
subject.sink.add(10);     // ✅ Also possible
subject.stream.listen(...); // ✅ Also possible
```

---

## In Your AuthBloc Code

```dart
factory AuthBloc() {
  final login = BehaviorSubject<LoginCommand>();
  //    ↑
  //    login is both a Sink AND a Stream

  // Used as Sink in the private constructor
  return AuthBloc._(
    login: login.sink,  // ← Expose only the Sink part (writing)
  );

  // But in the factory, used as Stream
  final Stream<AuthError?> loginError = login
    //                                  ↑
    //                                  Used as Stream (reading)
    .setLoadingTo(true, onSink: isLoading.sink)
    .asyncMap((loginCommand) async { ... });
}
```

---

## Why Separate `.sink` and `.stream`?

### Without Separation (dangerous)

```dart
class AuthBloc {
  final BehaviorSubject<LoginCommand> login; // ← Exposes EVERYTHING

  const AuthBloc._({required this.login});
}

// Usage:
authBloc.login.add(...);     // ✅ Can write (OK)
authBloc.login.listen(...);  // ✅ Can read (OK)
authBloc.login.close();      // ⚠️ Can close (DANGER!)
authBloc.login.value;        // ⚠️ Can access directly (undesired)
```

### With Separation (safe)

```dart
class AuthBloc {
  final Sink<LoginCommand> login; // ← Exposes ONLY writing

  const AuthBloc._({required this.login});
}

// Usage:
authBloc.login.add(...);    // ✅ Can write (OK)
authBloc.login.listen(...); // ❌ Impossible! (secure)
authBloc.login.close();     // ❌ Impossible! (secure)
```

---

## Visualization

```
BehaviorSubject<int>
│
├─ .sink (Sink<int>)      → Write-only
│   ├─ add(value)
│   ├─ addError(error)
│   └─ close()
│
├─ .stream (Stream<int>)  → Read-only
│   ├─ listen(...)
│   ├─ map(...)
│   └─ where(...)
│
└─ Direct access
    ├─ .value           → Read last value
    ├─ .hasValue        → Check if a value exists
    ├─ add(value)       → Write (same as .sink.add)
    └─ listen(...)      → Listen (same as .stream.listen)
```

---

## Complete Example: Counter

```dart
import 'package:rxdart/rxdart.dart';

class CounterBloc {
  // BehaviorSubject = Sink + Stream + Current value
  final _counter = BehaviorSubject<int>.seeded(0);

  // Expose as Stream (read-only)
  Stream<int> get counter => _counter.stream;

  // Expose as Sink (write-only)
  Sink<int> get counterSink => _counter.sink;

  // Or expose specific methods
  void increment() {
    _counter.add(_counter.value + 1);
    //           ↑ Read        ↑ Write
  }

  void decrement() {
    _counter.add(_counter.value - 1);
  }

  void reset() {
    _counter.add(0);
  }

  int get currentValue => _counter.value; // Direct access

  void dispose() {
    _counter.close(); // Close the BehaviorSubject
  }
}

// Usage:
void main() {
  final bloc = CounterBloc();

  // Listen to changes
  bloc.counter.listen((count) => print('Count: $count'));

  // Modify via methods
  bloc.increment(); // Count: 1
  bloc.increment(); // Count: 2
  bloc.decrement(); // Count: 1

  // Or via the sink
  bloc.counterSink.add(10); // Count: 10

  // Read current value
  print('Current: ${bloc.currentValue}'); // Current: 10

  bloc.dispose();
}
```

---

## Key Interfaces Comparison

| Feature | StreamController | BehaviorSubject | PublishSubject |
|---------|------------------|-----------------|----------------|
| Implements Sink | ✅ (via `.sink`) | ✅ (direct) | ✅ (direct) |
| Implements Stream | ✅ (via `.stream`) | ✅ (direct) | ✅ (direct) |
| Stores last value | ❌ | ✅ | ❌ |
| New subscribers get last value | ❌ | ✅ | ❌ |
| Direct `.add()` | ❌ | ✅ | ✅ |
| Direct `.listen()` | ❌ | ✅ | ✅ |
| `.value` property | ❌ | ✅ | ❌ |

---

## Advanced Example: Form Validation

```dart
import 'package:rxdart/rxdart.dart';

class LoginFormBloc {
  // Both are Sinks AND Streams
  final _email = BehaviorSubject<String>();
  final _password = BehaviorSubject<String>();

  // Expose as Sinks for input
  Sink<String> get emailSink => _email.sink;
  Sink<String> get passwordSink => _password.sink;

  // Expose as Streams for validation
  Stream<String> get email => _email.stream.transform(validateEmail);
  Stream<String> get password => _password.stream.transform(validatePassword);

  // Combine streams
  Stream<bool> get isValid => Rx.combineLatest2(
    email,
    password,
    (email, password) => true, // Both are valid if we reach here
  );

  // Validators
  final validateEmail = StreamTransformer<String, String>.fromHandlers(
    handleData: (email, sink) {
      if (email.contains('@')) {
        sink.add(email);
      } else {
        sink.addError('Invalid email');
      }
    },
  );

  final validatePassword = StreamTransformer<String, String>.fromHandlers(
    handleData: (password, sink) {
      if (password.length >= 6) {
        sink.add(password);
      } else {
        sink.addError('Password must be at least 6 characters');
      }
    },
  );

  void dispose() {
    _email.close();
    _password.close();
  }
}

// Usage:
void main() {
  final bloc = LoginFormBloc();

  bloc.isValid.listen((valid) => print('Form valid: $valid'));

  // Write to sinks
  bloc.emailSink.add('test');        // Invalid
  bloc.passwordSink.add('123');      // Invalid

  bloc.emailSink.add('test@test.com'); // Valid
  bloc.passwordSink.add('123456');     // Valid
  // Form valid: true

  bloc.dispose();
}
```

---

## Summary

```dart
BehaviorSubject<T>
├─ Implements Sink<T>   → .add(), .addError(), .close()
├─ Implements Stream<T> → .listen(), .map(), .where()
└─ Special property     → .value, .hasValue

Why is it a Sink?
└─ Because it implements the Sink<T> interface
   └─ Can write directly: subject.add(value)
   └─ Can close: subject.close()
   └─ Can send errors: subject.addError(error)

Advantage:
└─ No need to manage sink and stream separately
   └─ Unlike StreamController where you need:
       controller.sink.add(value)
       controller.stream.listen(...)
```

**BehaviorSubject is a Sink** because it implements the `Sink<T>` interface, allowing it to write values directly without going through a separate `.sink`! 🎯

---

## Best Practices

1. **Expose only what's needed**
   ```dart
   // ✅ Good: Expose sink and stream separately
   class MyBloc {
     final _subject = BehaviorSubject<int>();
     Sink<int> get input => _subject.sink;
     Stream<int> get output => _subject.stream;
   }

   // ❌ Bad: Expose the entire BehaviorSubject
   class MyBloc {
     final subject = BehaviorSubject<int>(); // Anyone can close it!
   }
   ```

2. **Use `.value` carefully**
   ```dart
   // ✅ Good: Check hasValue first
   if (subject.hasValue) {
     print(subject.value);
   }

   // ❌ Bad: Can throw if no value
   print(subject.value); // Error if no value emitted yet
   ```

3. **Always dispose**
   ```dart
   // ✅ Good: Close in dispose
   void dispose() {
     _subject.close();
   }
   ```
