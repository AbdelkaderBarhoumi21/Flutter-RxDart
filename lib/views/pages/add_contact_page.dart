import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_rxdart/helpers/debug.dart';
import 'package:flutter_rxdart/utils/type_def.dart';

class AddContactPage extends HookWidget {
  const AddContactPage({
    required this.createContact,
    required this.goBack,
    super.key,
  });

  final CreateContactCallback createContact;
  final GoBackCallback goBack;

  @override
  Widget build(BuildContext context) {
    final firstNameController = useTextEditingController(
      text: 'Abdelkader'.isDebugging,
    );
    final lastNameController = useTextEditingController(
      text: 'Barhoumi'.isDebugging,
    );
    final phoneNumberController = useTextEditingController(
      text: '+21698962120'.isDebugging,
    );
    final firstName = firstNameController.text;
    final lastName = lastNameController.text;
    final phoneNumber = phoneNumberController.text;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: goBack, icon: Icon(Icons.close)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            spacing: 12,
            children: [
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(hintText: 'Enter your first name'),
                keyboardType: TextInputType.name,
                keyboardAppearance: Brightness.dark,
              ),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(hintText: 'Enter your last name'),
                keyboardType: TextInputType.name,
                keyboardAppearance: Brightness.dark,
              ),
              TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(
                  hintText: 'Enter your phone number',
                ),
                keyboardType: TextInputType.name,
                keyboardAppearance: Brightness.dark,
              ),

              TextButton(
                onPressed: () {
                  createContact(firstName, lastName, phoneNumber);
                },
                child: Text('Create contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
