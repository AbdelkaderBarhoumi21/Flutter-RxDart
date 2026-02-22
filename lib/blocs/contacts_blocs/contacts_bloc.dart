import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_rxdart/extension/stream_extension.dart';
import 'package:flutter_rxdart/models/contact_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

typedef _Snapshots = QuerySnapshot<Map<String, dynamic>>;
typedef _Document = DocumentReference<Map<String, dynamic>>;

@immutable
class ContactsBloc {
  // Sink like a signal that come form the UI
  final Sink<String?> userId;
  final Sink<ContactModel> createContact;
  final Sink<ContactModel> deleteContact;
  final Stream<Iterable<ContactModel>> contacts;

  final StreamSubscription<void> _onCreateContact;
  final StreamSubscription<void> _onDeleteContact;

  factory ContactsBloc() {
    final _firebase = FirebaseFirestore.instance;
    final userId = BehaviorSubject<String?>();

    //upon changes to user id retrieve our contact
    final Stream<Iterable<ContactModel>> contacts = userId
        .switchMap<_Snapshots>((userId) {
          if (userId == null) {
            return const Stream<_Snapshots>.empty();
          } else {
            return _firebase.collection(userId).snapshots();
          }
        })
        .map<Iterable<ContactModel>>((snapshots) sync* {
          for (final doc in snapshots.docs) {
            yield ContactModel.fromJson(doc.data(), id: doc.id);
          }
        });

    // Create contacts
    final createContactsSubject = BehaviorSubject<ContactModel>();
    final StreamSubscription<void> createContactSubscription =
        createContactsSubject
            .switchMap(
              (ContactModel contactToCreate) => userId
                  .take(1)
                  .unwrap()
                  .asyncMap(
                    (userId) => _firebase
                        .collection(userId)
                        .add(contactToCreate.toJson),
                  ),
            )
            .listen((_) {});
    // delete contacts
    final deleteContactsSubject = BehaviorSubject<ContactModel>();
    final StreamSubscription<void> deleteContactsSubscription =
        deleteContactsSubject
            .switchMap(
              (ContactModel contactToDelete) => userId
                  .take(1)
                  .unwrap()
                  .asyncMap(
                    (userId) => _firebase
                        .collection(userId)
                        .doc(contactToDelete.id)
                        .delete(),
                  ),
            )
            .listen((_) {});

    // create ContactsBloc
    return ContactsBloc._(
      userId: userId,
      createContact: createContactsSubject.sink,
      deleteContact: deleteContactsSubject.sink,
      contacts: contacts,
      onCreateContact: createContactSubscription,
      onDeleteContact: deleteContactsSubscription,
    );
  }

  void dispose() {
    userId.close();
    createContact.close();
    deleteContact.close();
    _onCreateContact.cancel();
    _onDeleteContact.cancel();
  }

  const ContactsBloc._({
    required this.userId,
    required this.createContact,
    required this.deleteContact,
    required this.contacts,
    required StreamSubscription<void> onCreateContact,
    required StreamSubscription<void> onDeleteContact,
  }) : _onCreateContact = onCreateContact,
       _onDeleteContact = onDeleteContact;
}
