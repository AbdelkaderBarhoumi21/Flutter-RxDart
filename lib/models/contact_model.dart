import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

@immutable
class ContactModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  const ContactModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  });

  ContactModel.withoutId({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  }) : id = const Uuid().v4();
  ContactModel.fromJson(Map<String, dynamic> json, {required this.id})
    : firstName = json[ContactModelKeys.firstNameKey],
      lastName = json[ContactModelKeys.lastNameKey],
      phoneNumber = json[ContactModelKeys.phoneNumberKey];

  @override
  String toString() =>
      'ContactModel(id: $id, firstName: $firstName, lastName: $lastName, phoneNumber: $phoneNumber)';
}

extension ToJson on ContactModel {
  Map<String, dynamic> get toJson => {
    ContactModelKeys.firstNameKey: firstName,
    ContactModelKeys.lastNameKey: lastName,
    ContactModelKeys.phoneNumberKey: phoneNumber,
  };
}

@immutable
class ContactModelKeys {
  const ContactModelKeys._();
  static const firstNameKey = 'first_name';
  static const lastNameKey = 'last_name';
  static const phoneNumberKey = 'phone_number';
}
