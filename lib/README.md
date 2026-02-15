# Clean Architecture Structure

This project follows **Clean Architecture** principles with clear separation of concerns across three main layers.

## 📁 Project Structure

```
lib/
├── domain/                     # Business Logic Layer (Pure Dart)
│   └── entities/              # Core business entities
│       └── thing.dart         # Base entity for all searchable items
│
├── data/                      # Data Layer
│   ├── models/               # Data models (extend domain entities)
│   │   ├── animal_model.dart # Animal data model with JSON parsing
│   │   └── person_model.dart # Person data model with JSON parsing
│   │
│   └── datasources/          # Data sources (API, Local DB, etc.)
│       └── search_remote_datasource.dart  # Remote API calls & caching
│
└── presentation/             # UI Layer
    ├── bloc/                 # Business Logic Components (BLoC)
    │   ├── search_bloc.dart  # Search BLoC with RxDart streams
    │   └── search_state.dart # Search result states
    │
    ├── pages/                # Full screen pages
    │   └── home_page.dart    # Main search page
    │
    └── widgets/              # Reusable UI components
        └── search_result_view.dart  # Search results display widget
```

## 🏗️ Architecture Layers

### 1️⃣ Domain Layer (`domain/`)
**Pure business logic - Framework independent**

- **Entities**: Core business objects that represent your domain
  - `thing.dart`: Base entity for all searchable items (animals, persons)
- **No dependencies** on Flutter or external packages
- Contains only pure Dart code

### 2️⃣ Data Layer (`data/`)
**Handles data operations and external sources**

- **Models**: Data representations that extend domain entities
  - Include JSON serialization/deserialization
  - `animal_model.dart`: Animal with type enum
  - `person_model.dart`: Person with age property

- **Data Sources**: External data access
  - `search_remote_datasource.dart`: HTTP API calls, caching, search logic
  - Handles network requests and data transformation

### 3️⃣ Presentation Layer (`presentation/`)
**UI and state management**

- **BLoC**: Business Logic Components using RxDart
  - `search_bloc.dart`: Manages search state with reactive streams
  - `search_state.dart`: Defines all possible search states (Loading, Success, Error, Empty)

- **Pages**: Complete screen implementations
  - `home_page.dart`: Main search interface

- **Widgets**: Reusable UI components
  - `search_result_view.dart`: Displays search results with StreamBuilder

## 🔄 Data Flow

```
User Input → SearchBloc (Presentation)
    ↓
SearchRemoteDataSource (Data)
    ↓
Models & Entities (Data → Domain)
    ↓
SearchBloc State Update (Presentation)
    ↓
UI Updates (Presentation)
```

## ✅ Benefits

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Testability**: Layers can be tested independently
3. **Maintainability**: Changes in one layer don't affect others
4. **Scalability**: Easy to add new features without breaking existing code
5. **Reusability**: Domain entities and data sources can be shared across features
6. **Dependency Rule**: Dependencies point inward (Presentation → Data → Domain)

## 📝 Key Principles

- **Domain layer** has no dependencies on other layers
- **Data layer** depends only on Domain
- **Presentation layer** can depend on both Data and Domain
- Use **dependency injection** for loose coupling (e.g., `SearchBloc(dataSource: ...)`)
