import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class StoreOptionsScreen extends StatelessWidget {
  final DocumentReference storeReference;

  const StoreOptionsScreen(this.storeReference);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Store Options'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _deleteStore(context);
              },
              child: Text('Delete Store'),
            ),
            // Add more options as needed
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStore(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot storeSnapshot = await transaction.get(storeReference);
        List<DocumentReference> users = List<DocumentReference>.from(storeSnapshot['users']);
        String userId = FirebaseAuth.instance.currentUser!.uid;

        if (users.length == 1 && users[0].id == userId) {
          // Only the owner can delete the store
          await _deleteProductsCollection(storeReference.collection('products'));
          await transaction.delete(storeReference);
          
          // Remove the store reference from the user's stores list
          await transaction.update(FirebaseFirestore.instance.collection('users').doc(userId), {
            'stores': FieldValue.arrayRemove([storeReference]),
          });
        }
      });

      Navigator.pop(context);
    } catch (e) {
      print('Error deleting store: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete store. Please try again.')));
    }
  }

  Future<void> _deleteProductsCollection(CollectionReference productsCollection) async {
    QuerySnapshot querySnapshot = await productsCollection.get();
    for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
      await documentSnapshot.reference.delete();
    }
  }


}
