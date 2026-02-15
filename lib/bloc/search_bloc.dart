import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdart/bloc/search_state.dart';
import 'package:flutter_rxdart/network/api.dart';
import 'package:rxdart/rxdart.dart';

/// A BLoC (Business Logic Component) that handles search functionality using RxDart.
///
/// This BLoC follows a unidirectional data flow pattern:
/// - Input: Users write search terms to [search] (write-only Sink)
/// - Output: Users listen to [result] (read-only Stream) for search results
///
/// **Data Flow:**
/// ```
/// User writes → search (Sink) → BehaviorSubject → distinct() → debounceTime()
///     → switchMap() → result (Stream) → User reads
/// ```
///
/// **Example Usage:**
/// ```dart
/// final bloc = SearchBloc(api: MyApi());
///
/// // Listen to results
/// bloc.result.listen((result) {
///   if (result is SearchResultLoading) {
///     // Show loading indicator
///   } else if (result is SearchResultSuccess) {
///     // Display results
///   }
/// });
///
/// // Trigger a search
/// bloc.search.add("flutter");
///
/// // Don't forget to dispose
/// bloc.dispose();
/// ```
@immutable
class SearchBloc {
  /// Write-only sink for search input.
  ///
  /// Add search terms to this sink to trigger a search operation.
  /// The sink feeds into an internal BehaviorSubject that processes the input.
  final Sink<String> search;

  /// Read-only stream of search results.
  ///
  /// Listen to this stream to receive search results. The stream emits:
  /// - `null` when the search term is empty
  /// - [SearchResultLoading] when a search is in progress
  /// - [SearchResultSuccess] when results are found
  /// - [SearchResultEmpty] when no results are found
  /// - [SearchResultError] when an error occurs
  final Stream<SearchResult?> results;

  /// Disposes of the BLoC and closes the search sink.
  ///
  /// Must be called to prevent memory leaks. The sink must be closed manually,
  /// but the result stream will be closed automatically when the sink is closed.
  void dispose() {
    search.close();
  }
  
  /// **The Pipeline:**
  /// - `distinct()`: Filters out duplicate consecutive search terms
  /// - `debounceTime(300ms)`: Waits 300ms after user stops typing
  /// - `switchMap()`: Cancels previous search when new one starts
  /// - `delay(1s)`: Simulates network latency for demo purposes
  /// - `startWith()`: Immediately emits loading state
  /// - `onErrorReturnWith()`: Catches errors and converts to error state
  ///
  /// **Why return like this?**
  /// ```dart
  /// return SearchBloc._(search: textChanges.sink, result: results);
  /// ```
  /// This separates read and write concerns:
  /// - `textChanges.sink` → Write-only interface for input
  /// - `results` → Read-only interface for output
  /// - Internal `textChanges` BehaviorSubject connects them but stays hidden
  ///
  /// This creates unidirectional data flow where input and output are clearly separated.
  factory SearchBloc({required Api api}) {
    final textChanges = BehaviorSubject<String>();

    final Stream<SearchResult?> results = textChanges
        .distinct()
        .debounceTime(Duration(milliseconds: 300))
        .switchMap<SearchResult?>((String searchTerm) {
          if (searchTerm.isEmpty) {
            return Stream<SearchResult?>.value(null);
          } else {
            return Rx.fromCallable(() => api.search(searchTerm))
                .delay(const Duration(seconds: 1))
                .map(
                  (streamResult) => streamResult.isEmpty
                      ? const SearchResultEmpty()
                      : SearchResultSuccess(streamResult),
                )
                .startWith(SearchResultLoading())
                .onErrorReturnWith(
                  (error, stackTrace) => SearchResultError(error),
                );
          }
        });

    return SearchBloc._(search: textChanges.sink, results: results);
  }

  /// Private constructor used by the factory.
  ///
  /// This prevents direct instantiation and ensures the BLoC is always
  /// created with properly configured streams through the factory constructor.
  const SearchBloc._({required this.search, required this.results});
}
