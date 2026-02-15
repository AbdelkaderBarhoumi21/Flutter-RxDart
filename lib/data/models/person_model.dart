import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdart/domain/entities/thing.dart';

@immutable
class PersonModel extends ThingModel {
  final int age;
  const PersonModel({required super.name, required this.age});

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(name: json['name'], age: json['age']);
  }

  @override
  String toString() => 'PersonModel(name:$name, age:$age)';
}
