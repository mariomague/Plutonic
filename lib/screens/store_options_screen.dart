import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
              onPressed: () => _deleteStore(context),
              child: Text('Delete Store'),
            ),
            const SizedBox(height: 16.0), // Add spacing between buttons
            ElevatedButton(
              onPressed: () => _selectStore(context), // Implement _selectStore method
              child: Text('Select Store'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStore(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this store?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _performDelete(context);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDelete(BuildContext context) async {
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

  Future<void> _selectStore(BuildContext context) async {
    // print('-------------------------------------------------------------------');
    // print(storeReference.id);
    // print('-------------------------------------------------------------------');
    try {
      // Get the SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Store the store reference in SharedPreferences
      await prefs.setString('currentStore', storeReference.id);
      Navigator.pop(context); // Go back to the previous screen

      // Display a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Store selected successfully!')),
      );
    } catch (error) {
      print('Error selecting store: $error');
      // Handle the error appropriately, e.g., display an error message to the user
    }
  }

  Future<void> _deleteProductsCollection(CollectionReference productsCollection) async {
    // we remove the store from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentStore');
    QuerySnapshot querySnapshot = await productsCollection.get();
    for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
      await documentSnapshot.reference.delete();
    }
  }
}
