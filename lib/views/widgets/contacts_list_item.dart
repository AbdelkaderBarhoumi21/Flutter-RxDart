import 'package:flutter/material.dart';
import 'package:flutter_rxdart/dialogs/delete_contact_dialog.dart';
import 'package:flutter_rxdart/models/contact_model.dart';
import 'package:flutter_rxdart/utils/type_def.dart';

class ContactsListItem extends StatelessWidget {
  const ContactsListItem({
    required this.contact,
    required this.deleteContact,
    super.key,
  });
  final ContactModel contact;
  final DeleteContactCallback deleteContact;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(contact.fullName),
      trailing: IconButton(
        onPressed: () async {
          final shouldDelete = await showDeleteContactDialog(context);
          if (shouldDelete) {
            deleteContact(contact);
          }
        },
        icon: Icon(Icons.delete),
      ),
    );
  }
}
