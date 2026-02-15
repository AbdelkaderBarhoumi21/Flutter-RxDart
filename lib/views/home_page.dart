import 'package:flutter/material.dart';
import 'package:flutter_rxdart/bloc/search_bloc.dart';
import 'package:flutter_rxdart/network/api.dart';
import 'package:flutter_rxdart/views/search_result_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SearchBloc _searchBloc;
  @override
  void initState() {
    _searchBloc = SearchBloc(api: Api());
    super.initState();
  }

  @override
  void dispose() {
    _searchBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(hintText: 'Enter your search terms'),
              onChanged: _searchBloc.search.add,
            ),
            const SizedBox(height: 20),
            SearchResultView(searchResult: _searchBloc.results),
          ],
        ),
      ),
    );
  }
}
