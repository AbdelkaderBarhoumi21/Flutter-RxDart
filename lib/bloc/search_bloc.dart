import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdart/bloc/search_state.dart';
import 'package:flutter_rxdart/network/api.dart';
import 'package:rxdart/rxdart.dart';

@immutable
class SearchBloc {
  // StreamController is read and write
  final Sink<String>
  search; // write to this to trigger a search => sink is write only
  final Stream<SearchResult?>
  result; // listen to this for search results => stream is read only

  void dispose() {
    // sink must be closed manually to prevent memory leaks, but stream will be closed automatically when sink is closed
    search.close();
  }

  factory SearchBloc({required Api api}) {
    final textChanges = BehaviorSubject<String>();

    final Stream<SearchResult?> results = textChanges
        .distinct()
        .debounceTime(Duration(milliseconds: 300))
        .switchMap<SearchResult?>((String searchTerm) {
          if (searchTerm.isEmpty) {
            // search is empty
            return Stream<SearchResult?>.value(null);
          } else {
            // delay mean after result is success dont emit directly result wait for 1 sec then emit result
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

    return SearchBloc._(search: textChanges.sink, result: results);
  }
  const SearchBloc._({required this.search, required this.result});
}
