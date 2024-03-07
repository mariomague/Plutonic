import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddStore extends StatefulWidget {
  @override
  _AddStoreState createState() => _AddStoreState();
}

class _AddStoreState extends State<AddStore> {
  final TextEditingController _storeNameController = TextEditingController();

  Future<void> _addStore() async {
  String storeName = _storeNameController.text.trim();

  if (storeName.isNotEmpty) {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference storeRef = FirebaseFirestore.instance.collection('stores').doc();
      await storeRef.set({
        'name': storeName,
        'users': [FirebaseFirestore.instance.collection('users').doc(userId)], // Save user reference
      });

      // Add the store reference to the user's stores list
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'stores': FieldValue.arrayUnion([storeRef]),
      });

      // Create a 'products' subcollection under the store
      await storeRef.collection('products').doc('placeholder').set({
        'placeholder': true // Placeholder document to ensure the 'products' collection is created
      });

      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      print('Error adding store: $e');
      // Handle error
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Store'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _storeNameController,
              decoration: InputDecoration(
                labelText: 'Store Name',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addStore,
              child: Text('Add Store'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    super.dispose();
  }
}
