import 'dart:convert';
import 'dart:io';

import 'package:flutter_rxdart/models/animal_model.dart';
import 'package:flutter_rxdart/models/person_model.dart';
import 'package:flutter_rxdart/models/thing_model.dart';

typedef SearchTerm = String;

class Api {
  Api();
  List<AnimalModel>? _animals;
  List<PersonModel>? _persons;

  // Fetches animals and persons from the API and caches them in memory.
  List<ThingModel>? _extractThingUsingSearchTerm(SearchTerm term) {
    final cachedAnimal = _animals;
    final cachedPerson = _persons;
    if (cachedAnimal != null && cachedPerson != null) {
      List<ThingModel> results = [];

      // go through animals
      for (final animal in cachedAnimal) {
        if (animal.name.trimmedContains(term) ||
            animal.type.name.trimmedContains(term)) {
          results.add(animal);
        }
      }
      // go through persons
      for (final person in cachedPerson) {
        if (person.name.trimmedContains(term) ||
            person.age.toString().trimmedContains(term)) {
          results.add(person);
        }
      }

      // IMPORTANT: Return the results!
      return results;
    } else {
      // If we don't have cached data, we need to fetch it first and then search.
      return null;
    }
  }

  Future<List<ThingModel>> search(SearchTerm term) async {
    final trimmedTerm = term.trim().toLowerCase();
    // search in the cach first
    final cachedResult = _extractThingUsingSearchTerm(term);
    if (cachedResult != null) {
      return cachedResult;
    }

    // If we don't have cached data, we need to fetch it first and then search.
    // Note: Use 10.0.2.2 for Android emulator to access host machine's localhost
    // Use 127.0.0.1 for iOS simulator or web
    const baseUrl = 'http://10.0.2.2:5500/api';

    // Fetch persons
    final persons = await _getJson(
      '$baseUrl/persons.json',
    ).then((json) => json.map((value) => PersonModel.fromJson(value)).toList());
    _persons = persons;

    // Fetch animals
    final animals = await _getJson(
      '$baseUrl/animals.json',
    ).then((json) => json.map((value) => AnimalModel.fromJson(value)).toList());
    _animals = animals;

    return _extractThingUsingSearchTerm(term) ?? [];
  }

  /// Http response is a stream of bytes, so we need to transform it to a string and then decode the JSON.
  /// utf8.decoder converts those raw bytes into readable text (UTF-8 characters)
  /// Think of it like translating binary data [72, 101, 108, 108, 111] → "Hello"
  Future<List<dynamic>> _getJson(String url) => HttpClient()
      .getUrl(Uri.parse(url)) // 1. Send request
      .then((req) => req.close()) // 2. Finalize request, get response
      .then(
        (response) => // 3. Response = Stream<List<int>> (bytes)
        response
            .transform(utf8.decoder) //    → Stream<String> (text chunks)
            .join(),
      ) //    → String (complete JSON string)
      .then(
        (jsonString) => // 4. Now we can parse the JSON
            json.decode(jsonString) as List<dynamic>,
      );
}

extension TrimmedCaseInsensitiveContain on String {
  bool trimmedContains(String other) =>
      trim().toLowerCase().contains(other.trim().toLowerCase());
}
