import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_rxdart/models/thing_model.dart';

enum AnimalType { dog, cat, rabbit, unknown }

@immutable
class AnimalModel extends ThingModel {
  final AnimalType type;
  const AnimalModel({required super.name, required this.type});

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    final AnimalType type;
    switch (json['type'] as String) {
      case 'rabbit':
        type = AnimalType.rabbit;
        break;
      case 'cat':
        type = AnimalType.cat;
        break;
      case 'dog':
        type = AnimalType.dog;
        break;
      default:
        type = AnimalType.unknown;
    }
    return AnimalModel(name: json['name'], type: type);
  }

  /*
  var dog = AnimalModel(name: 'Buddy', type: AnimalType.dog);
  print(dog); // Output: AnimalModel(name: Buddy, type: AnimalType.dog)
  Without the override, you'd see something useless like Instance of 'AnimalModel'
  */
  @override
  String toString() => 'AnimalModel(name: $name, type: $type)';
}
