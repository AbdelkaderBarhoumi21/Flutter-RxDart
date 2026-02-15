import 'package:flutter/material.dart';
import 'package:flutter_rxdart/bloc/search_state.dart';
import 'package:flutter_rxdart/models/animal_model.dart';
import 'package:flutter_rxdart/models/person_model.dart';

class SearchResultView extends StatelessWidget {
  final Stream<SearchResult?> searchResult;
  const SearchResultView({required this.searchResult, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SearchResult?>(
      stream: searchResult,

      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final result = snapshot.data;
          if (result is SearchResultError) {
            return const Text('Error');
          } else if (result is SearchResultLoading) {
            return const CircularProgressIndicator();
          } else if (result is SearchResultEmpty) {
            return const Text(
              'No result found for your search term. Try with another one',
            );
          } else if (result is SearchResultSuccess) {
            final results = result.results;
            return Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  final String title;
                  if (item is AnimalModel) {
                    title = 'Animal';
                  } else if (item is PersonModel) {
                    title = 'Person';
                  } else {
                    title = 'unknown';
                  }

                  return ListTile(
                    title: Text(title),
                    subtitle: Text(item.toString()),
                  );
                },
              ),
            );
          } else {
            return const Text('Unknown state');
          }
        } else {
          return const Text('Waiting');
        }
      },
    );
  }
}
