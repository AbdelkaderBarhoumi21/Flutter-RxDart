# BLoC Architecture - Complete Guide

This document explains how all the BLoCs in this application work together, their responsibilities, and how they communicate.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [AuthBloc - Authentication Management](#authbloc---authentication-management)
3. [ViewsBloc - Navigation Management](#viewsbloc---navigation-management)
4. [ContactsBloc - Contact Management](#contactsbloc---contact-management)
5. [AppBloc - Central Coordinator](#appbloc---central-coordinator)
6. [Data Flow Examples](#data-flow-examples)
7. [Best Practices](#best-practices)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         AppBloc                             │
│                    (Central Coordinator)                    │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  AuthBloc    │  │  ViewsBloc   │  │ ContactsBloc │    │
│  │              │  │              │  │              │    │
│  │ - Login      │  │ - Navigation │  │ - CRUD Ops   │    │
│  │ - Register   │  │ - View State │  │ - Firestore  │    │
│  │ - Logout     │  │              │  │              │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   Firebase Auth         UI State            Firestore
```

**Key Principles:**
- Each BLoC has a **single responsibility**
- BLoCs communicate through **AppBloc** (no direct communication)
- UI interacts **only** with AppBloc
- Data flows unidirectionally

---

## AuthBloc - Authentication Management

### Responsibility
Handles all authentication-related operations with Firebase Auth.

### File: `lib/blocs/auth_blocs/auth_bloc.dart`

### Structure

```dart
@immutable
class AuthBloc {
  // READ-ONLY STREAMS (Output to UI)
  final Stream<AuthStatus> authStatus;      // Logged in or out
  final Stream<AuthError?> authError;       // Authentication errors
  final Stream<bool> isLoading;             // Loading state
  final Stream<String?> userId;             // Current user ID

  // WRITE-ONLY SINKS (Input from UI)
  final Sink<LoginCommand> login;           // Login action
  final Sink<RegisterCommand> register;     // Register action
  final Sink<void> logout;                  // Logout action
}
```

---

### Key Components

#### 1. AuthStatus Stream
Monitors Firebase authentication state changes.

```dart
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

**Flow:**
```
Firebase Auth State Changes
    ↓
User logged in? → AuthStatusLoggedIn
User logged out? → AuthStatusLoggedOut
    ↓
AppBloc listens and updates currentView
```

---

#### 2. Login Stream
Handles user login with error handling and loading states.

```dart
final login = BehaviorSubject<LoginCommand>();

final Stream<AuthError?> loginError = login
    .setLoadingTo(true, onSink: isLoading.sink)   // Set loading true
    .asyncMap((loginCommand) async {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: loginCommand.email,
          password: loginCommand.password,
        );
        return null;  // Success
      } on FirebaseAuthException catch (e) {
        return AuthError.fromFirebase(e);  // Firebase error
      } catch (_) {
        return const AuthErrorUnknown();   // Unknown error
      }
    })
    .setLoadingTo(false, onSink: isLoading.sink);  // Set loading false
```

**Flow:**
```
UI: authBloc.login.add(LoginCommand(...))
    ↓
1. isLoading → true
2. Call Firebase signInWithEmailAndPassword
3. Success? → null (no error)
   Failure? → AuthError
4. isLoading → false
    ↓
UI: Listen to authError stream to show error
```

---

#### 3. Register Stream
Similar to login, handles user registration.

```dart
final register = BehaviorSubject<RegisterCommand>();

final Stream<AuthError?> registerError = register
    .setLoadingTo(true, onSink: isLoading.sink)
    .asyncMap((registerCommand) async {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: registerCommand.email,
          password: registerCommand.password,
        );
        return null;
      } on FirebaseAuthException catch (e) {
        return AuthError.fromFirebase(e);
      } catch (_) {
        return const AuthErrorUnknown();
      }
    })
    .setLoadingTo(false, onSink: isLoading.sink);
```

---

#### 4. Logout Stream
Handles user logout.

```dart
final logout = BehaviorSubject<void>();

final Stream<AuthError?> logoutError = logout
    .setLoadingTo(true, onSink: isLoading.sink)
    .asyncMap((_) async {
      try {
        await FirebaseAuth.instance.signOut();
        return null;
      } on FirebaseAuthException catch (e) {
        return AuthError.fromFirebase(e);
      } catch (_) {
        return const AuthErrorUnknown();
      }
    })
    .setLoadingTo(false, onSink: isLoading.sink);
```

---

#### 5. Merged Error Stream
All errors combined into one stream using `Rx.merge`.

```dart
final Stream<AuthError?> authError = Rx.merge([
  loginError,
  registerError,
  logoutError,
  deleteAccountError,
]);
```

**Why merge?**
- UI needs only **ONE** StreamBuilder for all auth errors
- Any error from login/register/logout/delete is emitted immediately
- Simplifies error handling in the UI

---

### AuthError - Error Mapping

### File: `lib/blocs/auth_blocs/auth_error.dart`

Maps Firebase error codes to user-friendly error messages.

```dart
const Map<String, AuthError> authErrorMapping = {
  'user-not-found': AuthErrorUserNotFound(),
  'weak-password': AuthErrorWeakPassword(),
  'invalid-email': AuthErrorInvalidEmail(),
  'email-already-in-use': AuthErrorEmailAlreadyInUse(),
  // ... more mappings
};

factory AuthError.fromFirebase(FirebaseAuthException exception) =>
    authErrorMapping[exception.code.toLowerCase().trim()] ??
    const AuthErrorUnknown();
```

**Example Error Classes:**

```dart
@immutable
class AuthErrorInvalidEmail extends AuthError {
  const AuthErrorInvalidEmail()
    : super(
        dialogTitle: 'Invalid email',
        dialogText: 'Please double check your email and try again',
      );
}

@immutable
class AuthErrorWeakPassword extends AuthError {
  const AuthErrorWeakPassword()
    : super(
        dialogTitle: 'Weak password',
        dialogText: 'Please choose a stronger password',
      );
}
```

---

## ViewsBloc - Navigation Management

### Responsibility
Manages which view (screen) should be displayed in the app.

### File: `lib/blocs/view_blocs/views_bloc.dart`

### Structure

```dart
@immutable
class ViewsBloc {
  final Sink<CurrentView> goToView;      // Input: navigate to view
  final Stream<CurrentView> currentView;  // Output: current view
}
```

---

### Implementation

```dart
factory ViewsBloc() {
  final goToViewSubject = BehaviorSubject<CurrentView>.seeded(
    CurrentView.login,  // Default view
  );

  return ViewsBloc._(
    goToView: goToViewSubject.sink,
    currentView: goToViewSubject.startWith(CurrentView.login),
  );
}
```

**Key Points:**
- `seeded(CurrentView.login)` → App always starts on login view
- `startWith(CurrentView.login)` → Ensures initial value is emitted
- BehaviorSubject → Retains last view, new subscribers get current view

---

### CurrentView Enum

```dart
enum CurrentView {
  login,
  register,
  contactList,
  createContact,
}
```

---

### Usage Flow

```
UI: appBloc.goToContactListView()
    ↓
AppBloc: _viewsBloc.goToView.add(CurrentView.contactList)
    ↓
ViewsBloc: currentView stream emits CurrentView.contactList
    ↓
UI: StreamBuilder rebuilds with new view
```

---

## ContactsBloc - Contact Management

### Responsibility
Handles all contact CRUD operations with Firestore.

### File: `lib/blocs/contacts_blocs/contacts_bloc.dart`

### Structure

```dart
@immutable
class ContactsBloc {
  // INPUT SINKS
  final Sink<String?> userId;              // User ID to filter contacts
  final Sink<ContactModel> createContact;  // Create contact
  final Sink<ContactModel> deleteContact;  // Delete contact

  // OUTPUT STREAM
  final Stream<Iterable<ContactModel>> contacts;  // All contacts

  // INTERNAL SUBSCRIPTIONS
  final StreamSubscription<void> _onCreateContact;
  final StreamSubscription<void> _onDeleteContact;
}
```

---

### Key Components

#### 1. Contacts Stream
Reactively fetches contacts from Firestore based on userId.

```dart
final Stream<Iterable<ContactModel>> contacts = userId
    .switchMap<QuerySnapshot<Map<String, dynamic>>>((userId) {
      if (userId == null) {
        return const Stream.empty();  // No user = no contacts
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

**Flow:**
```
userId changes
    ↓
switchMap cancels previous Firestore listener
    ↓
Subscribe to new Firestore collection (userId)
    ↓
On any Firestore change:
    ↓
Map documents to ContactModel
    ↓
Emit Iterable<ContactModel>
    ↓
UI updates automatically
```

**Why `switchMap`?**
- When userId changes, **cancel** the previous Firestore listener
- Start a **new** listener for the new userId
- Prevents memory leaks from old listeners

---

#### 2. Create Contact Stream

```dart
final createContactsSubject = BehaviorSubject<ContactModel>();

final StreamSubscription<void> createContactSubscription =
    createContactsSubject
        .switchMap((ContactModel contactToCreate) =>
          userId
              .take(1)           // Get current userId
              .unwrap()          // Remove null values
              .asyncMap((userId) =>
                _firebase
                    .collection(userId)
                    .add(contactToCreate.toJson),
              ),
        )
        .listen((_) {});  // Execute the operation
```

**Flow:**
```
UI: appBloc.createContact(...)
    ↓
AppBloc: _contactsBloc.createContact.add(contact)
    ↓
ContactsBloc:
  1. Get current userId (.take(1))
  2. Filter out null (.unwrap())
  3. Add contact to Firestore (.asyncMap)
    ↓
Firestore: Contact added
    ↓
contacts stream automatically emits updated list
    ↓
UI: Rebuilds with new contact
```

**Key Techniques:**
- `.take(1)` → Get only the current userId value, then complete
- `.unwrap()` → Filter out null values (custom extension)
- `.asyncMap()` → Perform async Firestore operation
- `.listen((_) {})` → Execute the stream (side effect)

---

#### 3. Delete Contact Stream

```dart
final deleteContactsSubject = BehaviorSubject<ContactModel>();

final StreamSubscription<void> deleteContactsSubscription =
    deleteContactsSubject
        .switchMap((ContactModel contactToDelete) =>
          userId
              .take(1)
              .unwrap()
              .asyncMap((userId) =>
                _firebase
                    .collection(userId)
                    .doc(contactToDelete.id)
                    .delete(),
              ),
        )
        .listen((_) {});
```

**Similar flow to create, but calls `.delete()` instead.**

---

### Why StreamSubscription?

```dart
final StreamSubscription<void> _onCreateContact;
final StreamSubscription<void> _onDeleteContact;
```

**Reasons:**
1. **Execute side effects** - Firestore operations need to run
2. **Lifecycle management** - Can cancel subscriptions in `dispose()`
3. **Memory leak prevention** - Properly clean up resources

```dart
void dispose() {
  userId.close();
  createContact.close();
  deleteContact.close();
  _onCreateContact.cancel();   // ← Cancel subscription
  _onDeleteContact.cancel();   // ← Cancel subscription
}
```

---

## AppBloc - Central Coordinator

### Responsibility
Orchestrates all other BLoCs and provides a unified API to the UI.

### File: `lib/blocs/app_bloc.dart`

### Structure

```dart
@immutable
class AppBloc {
  // PRIVATE BLOCS
  final AuthBloc _authBloc;
  final ViewsBloc _viewsBloc;
  final ContactsBloc _contactsBloc;
  final StreamSubscription<String?> _userIdChanges;

  // PUBLIC STREAMS
  final Stream<CurrentView> currentView;
  final Stream<bool> isLoading;
  final Stream<AuthError?> authError;

  // PUBLIC METHODS
  void login({required String email, required String password});
  void register({required String email, required String password});
  void logout();
  void createContact({...});
  void deleteContact(ContactModel contact);
  void goToContactListView();
  void goToCreateContactView();
  void goToLoginView();
  void goToRegisterView();
}
```

---

### Key Responsibilities

#### 1. BLoC Initialization

```dart
factory AppBloc() {
  final AuthBloc authBloc = AuthBloc();
  final ViewsBloc viewsBloc = ViewsBloc();
  final ContactsBloc contactsBloc = ContactsBloc();

  // ... coordinate them
}
```

---

#### 2. Connect AuthBloc → ContactsBloc

Pass userId from AuthBloc to ContactsBloc automatically.

```dart
final userIdChanges = authBloc.userId.listen((String? userId) {
  contactsBloc.userId.add(userId);
});
```

**Flow:**
```
User logs in
    ↓
AuthBloc.userId emits user ID
    ↓
AppBloc listens and forwards to ContactsBloc
    ↓
ContactsBloc.userId receives user ID
    ↓
ContactsBloc.contacts stream updates with user's contacts
```

---

#### 3. Merge Current View

Combine authentication-based view with manual navigation.

```dart
// Auto-navigate based on auth status
final Stream<CurrentView> currentViewBasedOnAuthStatus = authBloc.authStatus
    .map<CurrentView>((authStatus) {
      if (authStatus is AuthStatusLoggedIn) {
        return CurrentView.contactList;  // Show contacts when logged in
      } else {
        return CurrentView.login;         // Show login when logged out
      }
    });

// Merge with manual navigation from ViewsBloc
final Stream<CurrentView> currentView = Rx.merge([
  currentViewBasedOnAuthStatus,
  viewsBloc.currentView,
]);
```

**Flow:**
```
Two sources of view changes:
1. Auth status changes (automatic)
2. User navigates manually (buttons)

Rx.merge combines both:
- When user logs in → auto-navigate to contacts
- When user clicks "Register" → navigate to register
- When user logs out → auto-navigate to login
```

---

#### 4. Broadcast Streams

```dart
return AppBloc._(
  authBloc: authBloc,
  viewsBloc: viewsBloc,
  contactsBloc: contactsBloc,
  userIdChanges: userIdChanges,
  currentView: currentView,
  isLoading: isLoading.asBroadcastStream(),      // ← Multiple listeners
  authError: authBloc.authError.asBroadcastStream(), // ← Multiple listeners
);
```

**Why `asBroadcastStream()`?**
- Multiple widgets may listen to `isLoading` (AppBar, Button, Overlay)
- Multiple widgets may listen to `authError` (Dialog, SnackBar)
- Without broadcast → ERROR: "Stream already listened to"

---

#### 5. Unified API for UI

Instead of UI accessing multiple BLoCs, everything goes through AppBloc.

```dart
// Login
void login({required String email, required String password}) {
  _authBloc.login.add(LoginCommand(email: email, password: password));
}

// Register
void register({required String email, required String password}) {
  _authBloc.register.add(RegisterCommand(email: email, password: password));
}

// Logout
void logout() {
  _authBloc.logout.add(null);
}

// Create contact
void createContact({
  required String firstName,
  required String lastName,
  required String phoneNumber,
}) {
  _contactsBloc.createContact.add(
    ContactModel.withoutId(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    ),
  );
}

// Delete contact
void deleteContact(ContactModel contact) {
  _contactsBloc.deleteContact.add(contact);
}

// Navigation
void goToContactListView() => _viewsBloc.goToView.add(CurrentView.contactList);
void goToCreateContactView() => _viewsBloc.goToView.add(CurrentView.createContact);
void goToLoginView() => _viewsBloc.goToView.add(CurrentView.login);
void goToRegisterView() => _viewsBloc.goToView.add(CurrentView.register);

// Contacts stream
Stream<Iterable<ContactModel>> get contacts => _contactsBloc.contacts;
```

---

#### 6. Dispose All Resources

```dart
void dispose() {
  _authBloc.dispose();
  _contactsBloc.dispose();
  _viewsBloc.dispose();
  _userIdChanges.cancel();
}
```

---

## Data Flow Examples

### Example 1: User Login Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      USER LOGIN FLOW                        │
└─────────────────────────────────────────────────────────────┘

1. UI: User enters email/password and clicks "Login"
   │
   ▼
2. UI calls: appBloc.login(email: '...', password: '...')
   │
   ▼
3. AppBloc forwards to AuthBloc:
   _authBloc.login.add(LoginCommand(...))
   │
   ▼
4. AuthBloc:
   ├─ Sets isLoading.add(true)
   ├─ Calls Firebase: signInWithEmailAndPassword()
   ├─ Success? → authError emits null
   │  Failure? → authError emits AuthError
   └─ Sets isLoading.add(false)
   │
   ▼
5. Firebase Auth: User logged in
   │
   ▼
6. AuthBloc.authStatus: Emits AuthStatusLoggedIn
   │
   ▼
7. AppBloc.currentView: Emits CurrentView.contactList
   │
   ▼
8. AuthBloc.userId: Emits user ID
   │
   ▼
9. AppBloc forwards userId to ContactsBloc
   │
   ▼
10. ContactsBloc: Fetches contacts from Firestore
    │
    ▼
11. UI: Rebuilds showing contact list
```

---

### Example 2: Create Contact Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   CREATE CONTACT FLOW                       │
└─────────────────────────────────────────────────────────────┘

1. UI: User enters contact details and clicks "Save"
   │
   ▼
2. UI calls: appBloc.createContact(
     firstName: '...',
     lastName: '...',
     phoneNumber: '...'
   )
   │
   ▼
3. AppBloc forwards to ContactsBloc:
   _contactsBloc.createContact.add(ContactModel.withoutId(...))
   │
   ▼
4. ContactsBloc:
   ├─ Gets current userId (.take(1))
   ├─ Filters out null (.unwrap())
   └─ Adds contact to Firestore collection(userId).add(...)
   │
   ▼
5. Firestore: Contact added
   │
   ▼
6. Firestore snapshots() emits updated collection
   │
   ▼
7. ContactsBloc.contacts: Emits updated contact list
   │
   ▼
8. UI: Rebuilds with new contact in list
```

---

### Example 3: Delete Contact Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   DELETE CONTACT FLOW                       │
└─────────────────────────────────────────────────────────────┘

1. UI: User clicks delete icon on contact
   │
   ▼
2. UI calls: appBloc.deleteContact(contact)
   │
   ▼
3. AppBloc forwards to ContactsBloc:
   _contactsBloc.deleteContact.add(contact)
   │
   ▼
4. ContactsBloc:
   ├─ Gets current userId
   └─ Deletes from Firestore: collection(userId).doc(contact.id).delete()
   │
   ▼
5. Firestore: Contact deleted
   │
   ▼
6. Firestore snapshots() emits updated collection
   │
   ▼
7. ContactsBloc.contacts: Emits updated list (without deleted contact)
   │
   ▼
8. UI: Rebuilds without deleted contact
```

---

### Example 4: Logout Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      LOGOUT FLOW                            │
└─────────────────────────────────────────────────────────────┘

1. UI: User clicks "Logout"
   │
   ▼
2. UI calls: appBloc.logout()
   │
   ▼
3. AppBloc forwards to AuthBloc:
   _authBloc.logout.add(null)
   │
   ▼
4. AuthBloc:
   ├─ Sets isLoading.add(true)
   ├─ Calls Firebase: signOut()
   └─ Sets isLoading.add(false)
   │
   ▼
5. Firebase Auth: User logged out
   │
   ▼
6. AuthBloc.authStatus: Emits AuthStatusLoggedOut
   │
   ▼
7. AppBloc.currentView: Emits CurrentView.login
   │
   ▼
8. AuthBloc.userId: Emits null
   │
   ▼
9. AppBloc forwards null to ContactsBloc.userId
   │
   ▼
10. ContactsBloc.contacts: Emits empty (no userId = no contacts)
    │
    ▼
11. UI: Navigates to login screen
```

---

## Best Practices

### 1. Single Responsibility Principle

Each BLoC has one clear responsibility:
- **AuthBloc** → Authentication only
- **ViewsBloc** → Navigation only
- **ContactsBloc** → Contact CRUD only
- **AppBloc** → Coordination only

---

### 2. No Direct BLoC-to-BLoC Communication

❌ **Bad:**
```dart
class ContactsBloc {
  final AuthBloc authBloc;  // Direct dependency

  void fetchContacts() {
    final userId = authBloc.userId;  // Direct access
  }
}
```

✅ **Good:**
```dart
class ContactsBloc {
  final Sink<String?> userId;  // Input from outside

  // AppBloc connects AuthBloc.userId → ContactsBloc.userId
}
```

---

### 3. Always Dispose Resources

```dart
@override
void dispose() {
  // Close all sinks
  _subject.close();

  // Cancel all subscriptions
  _subscription?.cancel();

  // Dispose child BLoCs
  _authBloc.dispose();
  _contactsBloc.dispose();

  super.dispose();
}
```

---

### 4. Use Broadcast Streams for Multiple Listeners

```dart
// ❌ Without broadcast
final stream = Rx.merge([...]);
widget1.listen(stream);  // OK
widget2.listen(stream);  // ERROR!

// ✅ With broadcast
final stream = Rx.merge([...]).asBroadcastStream();
widget1.listen(stream);  // OK
widget2.listen(stream);  // OK
```

---

### 5. Separate Read and Write

```dart
class MyBloc {
  // Write-only (Sink)
  final Sink<String> input;

  // Read-only (Stream)
  final Stream<String> output;
}
```

**Benefits:**
- UI cannot close streams
- UI cannot access internal state
- Clear intent (input vs output)

---

### 6. Handle Errors Gracefully

```dart
.asyncMap((command) async {
  try {
    await performOperation();
    return null;  // Success
  } on SpecificException catch (e) {
    return SpecificError.from(e);
  } catch (e) {
    return UnknownError();
  }
})
```

---

### 7. Use Loading States

```dart
.setLoadingTo(true, onSink: isLoading.sink)
.asyncMap((command) async { ... })
.setLoadingTo(false, onSink: isLoading.sink)
```

**UI can show spinners/disable buttons during operations.**

---

## Summary

### BLoC Hierarchy

```
AppBloc (Coordinator)
├── AuthBloc (Authentication)
│   ├── Login
│   ├── Register
│   ├── Logout
│   └── User ID
├── ViewsBloc (Navigation)
│   └── Current View
└── ContactsBloc (Contacts)
    ├── Create
    ├── Delete
    └── List
```

### Communication Flow

```
UI → AppBloc → Individual BLoCs → Firebase/Firestore
                    ↓
                Streams back
                    ↓
                AppBloc
                    ↓
                   UI
```

### Key Techniques

- **BehaviorSubject** → Retain last value, multiple subscribers
- **switchMap** → Cancel previous, start new
- **Rx.merge** → Combine multiple streams
- **asBroadcastStream** → Allow multiple listeners
- **StreamSubscription** → Execute side effects, manage lifecycle
- **Sink/Stream separation** → Read-only outputs, write-only inputs

---

This architecture provides:
✅ **Separation of concerns**
✅ **Testability**
✅ **Maintainability**
✅ **Scalability**
✅ **Reactive data flow**

🎯 **Result:** Clean, predictable, and reactive Flutter application!
