Firestore Security Rules Explained
These are Firestore security rules that control who can read/write to your database.

Line-by-Line Breakdown
rules_version = '2';
Version of the security rules language (always '2' now).
service cloud.firestore {
Start of the rules for the Cloud Firestore service.
match /databases/{database}/documents {
Applies to all documents in all databases. {database} is a wildcard (usually (default)).
match /{collection}/{document=**} {

{collection} — any collection (users, posts, etc.)
{document=**} — all documents and sub-collections (recursive)
** means "all levels below"


Custom Helper Function
jsfunction isCollectionOwner(collectionId) {
  return request.auth != null && 
         request.auth.uid == collectionId
}
```

This checks two things:
- `request.auth != null` → the user is logged in
- `request.auth.uid == collectionId` → the user's UID matches the collection name

**Example:**
```
/users/abc123/contacts/contact1
If collectionId = "abc123" and request.auth.uid = "abc123" → ✅ Allowed
This means only user abc123 can access /users/abc123/...

The Allow Rule
jsallow create, read, update, write: 
  if isCollectionOwner(collection);
```

Permits `create`, `read`, `update`, and `write` operations — but only if `isCollectionOwner(collection)` returns `true`. Here, `collection` refers to the `{collection}` wildcard from the match block.

---

## Full Schema
```
Firestore
└── (default) database
    └── documents
        ├── users                     ← {collection}
        │   ├── abc123               ← {document}
        │   │   └── contacts         ← sub-collection
        │   │       └── contact1     ← {document=**}
        │   └── xyz789
        └── posts                     ← {collection}
            └── post1                 ← {document}

Scenario Examples
✅ Allowed
js// User UID = "abc123"
firestore.collection('users/abc123/contacts').add({
  'name': 'John',
  'phone': '123-456-7890'
});
// isCollectionOwner('abc123') → true (request.auth.uid == 'abc123')
❌ Denied — wrong user
js// User UID = "abc123"
firestore.collection('users/xyz789/contacts').get();
// isCollectionOwner('xyz789') → false (request.auth.uid != 'xyz789')
❌ Denied — not logged in
js// User NOT logged in (request.auth == null)
firestore.collection('users/abc123/contacts').get();
// isCollectionOwner('abc123') → false (request.auth == null)

Important Variables
VariableDescriptionrequest.authInfo about the logged-in user (null if not logged in)request.auth.uidUnique user ID (e.g. "abc123")request.resource.dataData the user is trying to writeresource.dataCurrent data of the documentcollectionCollection name from the match blockdocumentDocument name from the match block

Operation Types
jsallow read;    // = get + list
allow write;   // = create + update + delete

// Or more granular:
allow get;     // read ONE document
allow list;    // list multiple documents
allow create;  // create a new document
allow update;  // modify an existing document
allow delete;  // delete a document

Improved Example (More Secure)
jsrules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Rule for /users/{userId}/contacts/{contactId}
    match /users/{userId}/contacts/{contactId} {

      // Only the owner can read their contacts
      allow read: if request.auth != null && 
                     request.auth.uid == userId;

      // Only the owner can create/update their contacts
      allow create, update: if request.auth != null && 
                               request.auth.uid == userId &&
                               request.resource.data.name is string &&
                               request.resource.data.phone is string;

      // Only the owner can delete their contacts
      allow delete: if request.auth != null && 
                       request.auth.uid == userId;
    }

    // Block everything else by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}

Summary
Your current rules say:

"Any logged-in user can read/write to a collection only if the collection name matches their UID."

This is a common pattern for per-user private data!