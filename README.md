# 🏗️ Clean Architecture - Flutter RxDart App

This Flutter application follows **Clean Architecture** principles with a clear separation between **Core** functionality and **Features**.

## 📁 Project Structure

```
lib/
├── core/                          # Shared functionality across all features
│   ├── dialogs/                  # Generic dialog components
│   │   └── app_dialog.dart       # Base dialog implementation
│   │
│   ├── extensions/               # Dart extensions
│   │   └── stream_extension.dart # RxDart stream helpers (setLoadingTo, etc.)
│   │
│   ├── loading/                  # Global loading overlay
│   │   ├── loading_screen.dart
│   │   └── loading_screen_controller.dart
│   │
│   ├── utils/                    # Utilities and type definitions
│   │   ├── debug.dart            # Debug helpers (isDebugging extension)
│   │   └── type_def.dart         # Type definitions (Callbacks, etc.)
│   │
│   └── widgets/                  # Reusable widgets
│       └── app_pop_menu.dart     # Popup menu component
│
├── features/                      # Feature modules (vertical slices)
│   ├── app/                      # App-level state management
│   │   └── presentation/
│   │       └── bloc/
│   │           ├── app_bloc.dart      # Main app BLoC (orchestrates auth + contacts)
│   │           ├── current_view.dart  # Current view enum
│   │           └── views_bloc.dart    # View navigation logic
│   │
│   ├── auth/                     # Authentication feature
│   │   ├── domain/              # Business entities and logic
│   │   │   ├── auth_error.dart   # Auth error types
│   │   │   └── auth_state.dart   # Auth states (LoggedIn, LoggedOut)
│   │   │
│   │   └── presentation/         # UI layer
│   │       ├── bloc/
│   │       │   └── auth_bloc.dart # Auth BLoC (login, register, logout)
│   │       │
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── register_page.dart
│   │       │
│   │       └── widgets/          # Auth-specific widgets and dialogs
│   │           ├── auth_error_dialog.dart
│   │           ├── logout_dialog.dart
│   │           └── delete_account_dialog.dart
│   │
│   └── contacts/                 # Contacts management feature
│       ├── domain/              # Business entities
│       │   └── contact_model.dart # Contact entity
│       │
│       └── presentation/         # UI layer
│           ├── bloc/
│           │   └── contacts_bloc.dart # Contacts BLoC (CRUD operations)
│           │
│           ├── pages/
│           │   ├── contacts_page.dart    # Contact list page
│           │   └── add_contact_page.dart # Create contact page
│           │
│           └── widgets/
│               ├── contacts_list_item.dart      # Contact list item
│               └── delete_contact_dialog.dart   # Delete confirmation
│
├── config/                       # App configuration
│   └── firebase_options.dart    # Firebase configuration
│
└── main.dart                     # App entry point
```

## 🎯 Architecture Layers

### 1️⃣ Core Layer
**Shared functionality used across multiple features**

- **Extensions**: Reusable Dart extensions (e.g., `setLoadingTo` for streams)
- **Utils**: Helper functions, type definitions, debug tools
- **Widgets**: UI components shared across features (popup menus, etc.)
- **Loading**: Global loading overlay with singleton pattern
- **Dialogs**: Generic dialog implementations

**Key Principle**: Core should NEVER depend on features!

### 2️⃣ Features Layer
**Vertical slices of functionality** - Each feature is self-contained

#### Feature Structure:
```
feature/
├── domain/           # Business logic (entities, states, errors)
└── presentation/     # UI layer
    ├── bloc/        # State management (BLoC pattern with RxDart)
    ├── pages/       # Full-screen pages
    └── widgets/     # Feature-specific widgets and dialogs
```

#### Current Features:

**🔐 Auth Feature**
- Login, Register, Logout, Delete Account
- Firebase Authentication integration
- Error handling with specific error types
- State management with `AuthBloc`

**📇 Contacts Feature**
- CRUD operations for contacts (Create, Read, Delete)
- Firebase Firestore integration
- Real-time contact list with RxDart streams
- State management with `ContactsBloc`

**🎯 App Feature**
- Global app state orchestration
- View navigation management
- Combines Auth + Contacts state

### 3️⃣ Config Layer
**App-wide configuration** (Firebase, API keys, etc.)

## 🔄 Data Flow (BLoC Pattern with RxDart)

```
User Action → Sink (Input)
       ↓
  BLoC Logic (Stream Transformations)
       ↓
   Stream (Output) → UI Updates
```

**Example: Login Flow**
```dart
// User enters credentials and clicks login
LoginPage → appBloc.login.add(LoginCommand(email, password))
                ↓
         AuthBloc processes
                ↓
    Firebase Authentication
                ↓
      AuthStatus Stream emits
                ↓
    HomePage rebuilds with new view
```

## 🧩 Key Components

### BLoC Pattern
All state management uses **BLoC (Business Logic Component)** with RxDart:

- **`AuthBloc`**: Handles authentication (login, register, logout)
- **`ContactsBloc`**: Manages contacts CRUD operations
- **`AppBloc`**: Orchestrates app-level state (combines Auth + Contacts + Views)

### Stream Extensions
Custom RxDart extensions in `core/extensions/stream_extension.dart`:

```dart
// Automatically manages loading state
stream.setLoadingTo(true, onSink: isLoading.sink)
```

### Singleton Pattern
Used for global services:
- `LoadingScreen.instance()`: Global loading overlay

## 📦 Dependencies

- **`rxdart`**: Reactive programming with streams
- **`firebase_core`**: Firebase initialization
- **`firebase_auth`**: Authentication
- **`cloud_firestore`**: Database
- **`flutter_hooks`**: Widget lifecycle management

## ✅ Benefits of This Architecture

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Testability**: Layers can be tested independently
3. **Maintainability**: Changes in one feature don't affect others
4. **Scalability**: Easy to add new features without touching existing code
5. **Reusability**: Core utilities shared across features
6. **Feature Independence**: Each feature is a vertical slice (can be developed in parallel)
7. **Clear Dependencies**: Dependencies flow inward (Presentation → Domain)

## 🚀 Adding a New Feature

To add a new feature (e.g., "Settings"):

```bash
lib/features/settings/
├── domain/
│   └── settings_model.dart
└── presentation/
    ├── bloc/
    │   └── settings_bloc.dart
    ├── pages/
    │   └── settings_page.dart
    └── widgets/
        └── settings_item.dart
```

## 📝 Best Practices

1. **Core never depends on Features** - Keep core generic
2. **Features are independent** - One feature should NOT import another feature
3. **Use BLoC for state management** - Consistent pattern across app
4. **Type safety** - Use type definitions in `core/utils/type_def.dart`
5. **Error handling** - Create specific error types in domain layer
6. **Stream management** - Always dispose streams in `dispose()`

## 🎨 Code Style

- **Immutable classes**: Use `@immutable` annotation
- **Named parameters**: Use for constructors
- **Documentation**: Add comments for complex logic
- **Const constructors**: Use `const` when possible

## 🔍 Quick Navigation

- **App entry**: [main.dart](main.dart)
- **Main BLoC**: [features/app/presentation/bloc/app_bloc.dart](features/app/presentation/bloc/app_bloc.dart)
- **Auth logic**: [features/auth/presentation/bloc/auth_bloc.dart](features/auth/presentation/bloc/auth_bloc.dart)
- **Contacts logic**: [features/contacts/presentation/bloc/contacts_bloc.dart](features/contacts/presentation/bloc/contacts_bloc.dart)
- **Stream helpers**: [core/extensions/stream_extension.dart](core/extensions/stream_extension.dart)

---

**Architecture**: Clean Architecture with Feature-based structure
**State Management**: BLoC Pattern with RxDart
**Backend**: Firebase (Auth + Firestore)
