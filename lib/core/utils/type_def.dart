import 'package:flutter/material.dart';
import 'package:flutter_rxdart/features/contacts/domain/contact_model.dart';

typedef LogoutCallback = VoidCallback;
typedef GoBackCallback = VoidCallback;
typedef LoginFunction = void Function({required String email, required String password});
typedef RegisterFunction = void Function({required String email, required String password});
typedef DeleteAccountCallback = VoidCallback;
typedef CreateContactCallback =
    void Function({required String firstName, required String lastName, required String phoneNumber});
typedef DeleteContactCallback = void Function(ContactModel contact);
