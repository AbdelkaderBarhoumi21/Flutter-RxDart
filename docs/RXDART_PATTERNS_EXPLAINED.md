# RxDart Patterns Explained - Complete Guide

## Table of Contents
1. [Streams, Sinks, and Subscriptions](#streams-sinks-and-subscriptions)
2. [BehaviorSubject - When and Why](#behaviorsubject---when-and-why)
3. [Stream Operators (switchMap, asyncMap, map)](#stream-operators)
4. [Real Examples from This Project](#real-examples-from-this-project)
5. [Common Patterns and Best Practices](#common-patterns-and-best-practices)

---

## Streams, Sinks, and Subscriptions

### 🌊 Stream
**What it is:** A **read-only** source of asynchronous data. Think of it like a river flowing with data.

```dart
Stream<int> numbers = Stream.fromIterable([1, 2, 3, 4, 5]);
```

**Used for:** Exposing data that others can listen to but cannot add data to.

**In this project:**
```dart
// From AuthBloc - READ ONLY
final Stream<AuthStatus> authStatus;
final Stream<AuthError?> authError;
final Stream<bool> isLoading;
final Stream<String?> userId;
```

---

### 🚰 Sink
**What it is:** A **write-only** endpoint for adding data into a stream. Think of it like a funnel you pour data into.

```dart
Sink<String> messages = controller.sink;
messages.add("Hello"); // Sending data INTO the stream
```

**Used for:** Accepting commands/events from the UI that will trigger actions.

**In this project:**
```dart
// From AuthBloc - WRITE ONLY (Commands from UI)
final Sink<LoginCommand> login;
final Sink<RegisterCommand> register;
final Sink<void> logout;
final Sink<void> deleteAccount;
```

**Why separate Sink and Stream?**
- **Security & Control:** UI can only send commands (via Sink), not mess with internal stream logic
- **Clear Intent:** Sink = "I want to trigger an action", Stream = "I want to listen to data"

---

### 📡 StreamSubscription
**What it is:** A connection to a stream that listens to its data. You must **cancel** it when done to prevent memory leaks.

```dart
final subscription = myStream.listen((data) {
  print('Received: $data');
});

// Later...
subscription.cancel(); // IMPORTANT: Always cancel!
```

**In this project:**
```dart
// From AppBloc - Passing userId changes to ContactsBloc
final StreamSubscription<String?> _userIdChanges =
    authBloc.userId.listen((String? userId) {
      contactsBloc.userId.add(userId);  // Add to sink!
    });

// Must cancel in dispose()
void dispose() {
  _userIdChanges.cancel();
}
```

**Why use `.listen()` with `.add()`?**
This creates a **data pipeline**: When `authBloc.userId` emits a new user ID, we immediately push it into `contactsBloc.userId` sink.

---

## BehaviorSubject - When and Why

### 🎯 What is BehaviorSubject?

`BehaviorSubject` is a **special type** of stream controller that:
1. **Remembers its last value** (can access via `.value`)
2. **Acts as both Stream AND Sink** (you can read from it and write to it)
3. **Immediately emits the last value** to new listeners

```dart
// BehaviorSubject implements both Stream and Sink
final subject = BehaviorSubject<int>();

// Writing (Sink behavior)
subject.add(10);
subject.add(20);

// Reading (Stream behavior)
subject.stream.listen((value) => print(value)); // Prints: 20 (last value)

// Accessing current value
print(subject.value); // 20
```

---

### 🤔 When to Use BehaviorSubject vs Regular Stream?

| Use BehaviorSubject When... | Use Regular Stream When... |
|------------------------------|---------------------------|
| You need to **trigger actions** (write) | You only need to **listen** (read) |
| You want the **latest value immediately** | You don't care about past values |
| You're handling **user commands** | You're transforming existing streams |
| You need to check **current state** (`.value`) | You're dealing with Firebase/external streams |

---

### 📋 Examples from This Project

#### ✅ Using BehaviorSubject (Commands from UI)

```dart
// From AuthBloc
final login = BehaviorSubject<LoginCommand>();
final register = BehaviorSubject<RegisterCommand>();
final logout = BehaviorSubject<void>();
```

**WHY?**
- UI sends **commands** to these subjects: `login.add(LoginCommand(...))`
- We can process these commands asynchronously
- BehaviorSubject acts as a **command queue**

---

#### ✅ Using BehaviorSubject with `.seeded()` (Initial Value)

```dart
// From AuthBloc
final isLoading = BehaviorSubject<bool>.seeded(false);
```

**WHY?**
- **Seeded** means it starts with a default value (`false`)
- New listeners immediately get the current loading state
- No need to wait for the first event

```dart
// From ViewsBloc
final goToViewSubject = BehaviorSubject<CurrentView>.seeded(
  CurrentView.login,
);
```

**WHY?**
- App always starts at login view
- `.seeded()` provides this initial value
- You can access `goToViewSubject.value` to get current view

---

#### ❌ NOT Using BehaviorSubject (External Streams)

```dart
// From AuthBloc
final Stream<AuthStatus> authStatus = FirebaseAuth.instance
    .authStateChanges()
    .map((user) {
      if (user != null) {
        return const AuthStatusLoggedIn();
      } else {
        return const AuthStatusLoggedOut();
      }
    });
```

**WHY NOT BehaviorSubject?**
- Firebase **already provides** a stream
- We only need to **transform** it (read-only)
- No need to write/add values manually
- Using `.map()` is enough

---

## Stream Operators

### 🗺️ map() - Transform Each Item

**What it does:** Transforms each value in the stream **synchronously**.

```dart
Stream<int> numbers = Stream.fromIterable([1, 2, 3]);
Stream<String> strings = numbers.map((n) => 'Number: $n');
// Output: "Number: 1", "Number: 2", "Number: 3"
```

**In this project:**
```dart
// From AuthBloc - Transform User to UserId
final Stream<String?> userId = FirebaseAuth.instance
    .authStateChanges()
    .map((user) => user?.uid)  // Extract user ID
    .startWith(FirebaseAuth.instance.currentUser?.uid);
```

**Use map() when:**
- You need **instant, synchronous** transformation
- No async operations (no `await`)
- Simple data conversion

---

### ⚡ asyncMap() - Transform with Async Operations

**What it does:** Transforms each value **asynchronously** (with `async/await`).

```dart
Stream<String> urls = Stream.fromIterable(['url1', 'url2']);
Stream<Data> results = urls.asyncMap((url) async {
  return await fetchData(url);  // Async operation!
});
```

**In this project:**
```dart
// From AuthBloc - Login with async Firebase call
final Stream<AuthError?> loginError = login
    .asyncMap((loginCommand) async {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: loginCommand.email,
          password: loginCommand.password,
        );
        return null;
      } catch (e) {
        return AuthError.fromFirebase(e);
      }
    });
```

**Use asyncMap() when:**
- You need to perform **async operations** (API calls, database queries)
- Each input must wait for the previous one to complete
- You want **sequential processing**

---

### 🔀 switchMap() - Cancel Previous, Switch to New

**What it does:** When a new value arrives, **cancels** the previous stream and switches to a new one.

```dart
Stream<String> searchQuery = ...;
Stream<Results> searchResults = searchQuery.switchMap((query) {
  return performSearch(query);  // Returns a Stream
});
```

**If user types:** `"h"` → `"he"` → `"hel"` → `"hello"`
- Search for "h" starts... **CANCELLED**
- Search for "he" starts... **CANCELLED**
- Search for "hel" starts... **CANCELLED**
- Search for "hello" **COMPLETES**

**In this project:**
```dart
// From ContactsBloc - Switch to new contacts when userId changes
final Stream<Iterable<ContactModel>> contacts = userId
    .switchMap<_Snapshots>((userId) {
      if (userId == null) {
        return const Stream<_Snapshots>.empty();
      } else {
        return _firebase.collection(userId).snapshots();
      }
    })
    .map<Iterable<ContactModel>>((snapshots) sync* {
      for (final doc in snapshots.docs) {
        yield ContactModel.fromJson(doc.data(), id: doc.id);
      }
    });
```

**WHY switchMap() here?**
- When user logs in/out, `userId` changes
- We **cancel** listening to the old user's contacts
- We **switch** to listening to the new user's contacts
- Prevents mixing contacts from different users!

---

### 🔄 switchMap() vs asyncMap()

| `switchMap()` | `asyncMap()` |
|--------------|-------------|
| **Cancels** previous operation when new value arrives | **Waits** for each operation to complete |
| Returns a **Stream** | Returns a **Future** |
| Used when you want **latest result only** | Used when **all results matter** |
| Example: Live search, real-time updates | Example: Processing queue of commands |

**Example:**
```dart
// switchMap - Only care about latest user's contacts
userId.switchMap((id) => firestore.collection(id).snapshots())

// asyncMap - Process every login attempt
loginCommands.asyncMap((cmd) async => await doLogin(cmd))
```

---

### 🔗 Chaining Operators

You can chain multiple operators together:

```dart
// From ContactsBloc - Create Contact Flow
createContactsSubject
    .switchMap((ContactModel contactToCreate) =>
        userId
            .take(1)              // Take only current userId
            .unwrap()             // Remove null values
            .asyncMap((userId) => // Async Firebase operation
                _firebase
                    .collection(userId)
                    .add(contactToCreate.toJson),
            ),
    )
    .listen((_) {});  // Execute the pipeline
```

**What happens:**
1. UI sends contact → `createContactsSubject.add(contact)`
2. `switchMap` → Get current userId stream
3. `take(1)` → Only take the first (current) userId value
4. `unwrap()` → Remove nulls (custom extension)
5. `asyncMap` → Add contact to Firebase (async)
6. `listen()` → Execute everything (must subscribe!)

---

## Real Examples from This Project

### Example 1: Login Flow (AuthBloc)

```dart
// Step 1: Create BehaviorSubject for login commands
final login = BehaviorSubject<LoginCommand>();

// Step 2: Process login commands
final Stream<AuthError?> loginError = login
    .setLoadingTo(true, onSink: isLoading.sink)  // Set loading = true
    .asyncMap((loginCommand) async {             // Async Firebase call
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: loginCommand.email,
          password: loginCommand.password,
        );
        return null;  // Success
      } on FirebaseAuthException catch (e) {
        return AuthError.fromFirebase(e);  // Error
      }
    })
    .setLoadingTo(false, onSink: isLoading.sink);  // Set loading = false

// Step 3: Expose sink to UI
final Sink<LoginCommand> loginSink = login.sink;
```

**How it works:**
1. UI calls: `authBloc.login.add(LoginCommand(email: "...", password: "..."))`
2. `setLoadingTo(true)` → Sets `isLoading` to `true`
3. `asyncMap` → Calls Firebase auth (waits for result)
4. `setLoadingTo(false)` → Sets `isLoading` to `false`
5. Error (if any) flows to `authError` stream
6. UI listens to `isLoading` and `authError` streams

---

### Example 2: User ID Sync (AppBloc)

```dart
// Sync userId from AuthBloc to ContactsBloc
final userIdChanges = authBloc.userId.listen((String? userId) {
  contactsBloc.userId.add(userId);  // Push to ContactsBloc
});
```

**Why this pattern?**
- `authBloc.userId` is a **Stream** (read-only)
- `contactsBloc.userId` is a **Sink** (write-only)
- `.listen()` creates a subscription
- Whenever `authBloc.userId` emits, we push to `contactsBloc.userId.add()`
- This keeps ContactsBloc in sync with auth state!

---

### Example 3: Delete All Contacts (ContactsBloc)

```dart
// Step 1: Create command sink
final deleteAllContacts = BehaviorSubject<void>();

// Step 2: Process command
final StreamSubscription<void> deleteAllContactsSubscription =
    deleteAllContacts
        .switchMap((_) => userId.take(1).unwrap())      // Get current userId
        .asyncMap((userId) =>                           // Get all docs
            _firebase.collection(userId).get()
        )
        .switchMap((collection) =>                      // Delete each doc
            Stream.fromFutures(
              collection.docs.map((doc) => doc.reference.delete()),
            ),
        )
        .listen((_) {});  // Execute

// Step 3: Must cancel subscription!
void dispose() {
  deleteAllContacts.close();
  deleteAllContactsSubscription.cancel();
}
```

**Flow breakdown:**
1. UI calls: `contactsBloc.deleteAllContacts.add(null)` (trigger command)
2. `switchMap` → Get current userId (cancels if another delete starts)
3. `take(1)` → Only need userId once
4. `unwrap()` → Remove null
5. `asyncMap` → Fetch all contacts from Firestore
6. `switchMap` → Create stream of delete futures
7. `listen()` → Execute the entire chain

**Why `switchMap` twice?**
- First `switchMap`: Cancel if userId changes mid-delete
- Second `switchMap`: Transform collection into multiple delete operations

---

### Example 4: Current View Logic (AppBloc)

```dart
// Determine view based on auth status
final Stream<CurrentView> currentViewBasedOnAuthStatus =
    authBloc.authStatus.map<CurrentView>((authStatus) {
      if (authStatus is AuthStatusLoggedIn) {
        return CurrentView.contactList;
      } else {
        return CurrentView.login;
      }
    });

// Merge auth-based view with manual navigation
final Stream<CurrentView> currentView = Rx.merge([
  currentViewBasedOnAuthStatus,
  viewsBloc.currentView,
]);
```

**What's happening:**
- `Rx.merge()` combines multiple streams into one
- If user logs in → `currentViewBasedOnAuthStatus` emits `contactList`
- If user clicks "Create Contact" → `viewsBloc.currentView` emits `createContact`
- UI listens to `currentView` and shows the right screen

---

## Common Patterns and Best Practices

### ✅ Pattern 1: Command Pattern (Sink for Actions)

```dart
// Commands that UI can send
final Sink<LoginCommand> login;
final Sink<void> logout;

// UI sends commands
authBloc.login.add(LoginCommand(email: "...", password: "..."));
authBloc.logout.add(null);
```

**Why?** Clean separation: UI triggers actions, BLoC handles logic.

---

### ✅ Pattern 2: Expose Streams, Hide Subjects

```dart
// PRIVATE - Internal subject
final _isLoading = BehaviorSubject<bool>.seeded(false);

// PUBLIC - Expose only stream (read-only)
Stream<bool> get isLoading => _isLoading.stream;

// Or expose sink for writing
Sink<bool> get loadingSink => _isLoading.sink;
```

**Why?** Encapsulation - outside code can't mess with internal state.

---

### ✅ Pattern 3: Always Dispose/Close

```dart
void dispose() {
  // Close sinks
  login.close();
  register.close();
  logout.close();

  // Cancel subscriptions
  _userIdChanges.cancel();
  _onCreateContact.cancel();
}
```

**Why?** Prevent memory leaks! Streams and subscriptions hold references.

---

### ✅ Pattern 4: Loading State Management

```dart
// Custom extension in stream_extension.dart
extension Loading<E> on Stream<E> {
  Stream<E> setLoadingTo(bool isLoading, {required Sink<bool> onSink}) =>
      doOnEach((_) {
        onSink.add(isLoading);
      });
}

// Usage
login
    .setLoadingTo(true, onSink: isLoading.sink)   // Start loading
    .asyncMap((cmd) async => await doLogin(cmd))   // Do work
    .setLoadingTo(false, onSink: isLoading.sink);  // Stop loading
```

**Why?** Automatic loading state without manual `isLoading.add()` calls.

---

### ✅ Pattern 5: Null Safety with unwrap()

```dart
// Custom extension in stream_extension.dart
extension Unwrap<T> on Stream<T?> {
  Stream<T> unwrap() => switchMap((optional) async* {
    if (optional != null) {
      yield optional;
    }
  });
}

// Usage: Transform Stream<String?> to Stream<String>
userId.take(1).unwrap()  // Only non-null values pass through
```

**Why?** Type-safe stream transformations, filters out nulls.

---

## Summary Table

| Component | Purpose | Example |
|-----------|---------|---------|
| **Stream** | Read-only data source | `Stream<AuthStatus> authStatus` |
| **Sink** | Write-only command input | `Sink<LoginCommand> login` |
| **StreamSubscription** | Active listener to a stream | `subscription.cancel()` |
| **BehaviorSubject** | Stream + Sink + remembers last value | `BehaviorSubject<bool>.seeded(false)` |
| **.map()** | Synchronous transformation | `.map((user) => user.uid)` |
| **.asyncMap()** | Async transformation (awaits) | `.asyncMap((cmd) async => await login(cmd))` |
| **.switchMap()** | Cancel previous, switch to new stream | `.switchMap((id) => firestore.snapshots())` |
| **.listen()** | Subscribe and execute stream | `.listen((data) => print(data))` |
| **Rx.merge()** | Combine multiple streams | `Rx.merge([stream1, stream2])` |

---

## Key Takeaways

1. **Streams** = read-only rivers of data
2. **Sinks** = write-only funnels to add data
3. **BehaviorSubject** = Swiss army knife (stream + sink + memory)
4. **Use `.listen()` to connect streams to sinks** for data pipelines
5. **Always cancel subscriptions** in `dispose()`
6. **switchMap** = cancel old, use new (latest wins)
7. **asyncMap** = process each item with async operation
8. **map** = quick sync transformations

---

Generated for the `flutter_rxdart` project - a contacts app demonstrating clean RxDart patterns with Firebase.
