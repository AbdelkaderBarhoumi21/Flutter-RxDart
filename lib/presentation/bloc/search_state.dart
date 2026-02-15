import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdart/domain/entities/thing.dart';

@immutable
abstract class SearchResult {
  const SearchResult();
}

@immutable
class SearchResultLoading extends SearchResult {
  const SearchResultLoading();
}

@immutable
class SearchResultEmpty extends SearchResult {
  const SearchResultEmpty();
}

@immutable
class SearchResultError extends SearchResult {
  final Object error;
  const SearchResultError(this.error);
}

@immutable
class SearchResultSuccess extends SearchResult {
  final List<ThingModel> results;
  const SearchResultSuccess(this.results);
}
