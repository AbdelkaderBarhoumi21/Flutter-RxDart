import 'package:flutter/material.dart';
import 'package:flutter_rxdart/features/contacts/domain/contact_model.dart';
import 'package:flutter_rxdart/core/utils/type_def.dart';
import 'package:flutter_rxdart/core/widgets/app_pop_menu.dart';
import 'package:flutter_rxdart/features/contacts/presentation/widgets/contacts_list_item.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({
    required this.logoutCallback,
    required this.deleteAccountCallback,
    required this.deleteContactCallback,

    required this.createNewContact,
    required this.contacts,
    super.key,
  });

  final LogoutCallback logoutCallback;
  final DeleteAccountCallback deleteAccountCallback;
  final DeleteContactCallback deleteContactCallback;
  final void Function() createNewContact;
  final Stream<Iterable<ContactModel>> contacts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts Page'),
        actions: [
          AppPopMenu(
            logout: logoutCallback,
            deleteAccount: deleteAccountCallback,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        onPressed: createNewContact,
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<Iterable<ContactModel>>(
        stream: contacts,
        builder: (context, snapshot) {
          // done when stream is closed
          // active when stream is open
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            case ConnectionState.active:
            case ConnectionState.done:
              final contacts = snapshot.requireData;
              return ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return ContactsListItem(
                    contact: contacts.elementAt(index),
                    deleteContact: deleteContactCallback,
                  );
                },
              );
          }
        },
      ),
    );
  }
}
