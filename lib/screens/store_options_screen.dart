// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreOptionsScreen extends StatelessWidget {
  final DocumentReference storeReference;
  final String storeName; // Nombre de la tienda

  const StoreOptionsScreen(this.storeReference, this.storeName, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(storeName), // Mostrar el nombre de la tienda en la barra de aplicaciones
      ),
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 200,
            child: FutureBuilder(
              future: _getStoreImage(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('Error loading image'));
                }
                Uint8List imageData = snapshot.data as Uint8List;
                return Image.memory(
                  imageData,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity, // Make the button full width
                  child: ElevatedButton(
                    onPressed: () => _deleteStore(context),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.red[500],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Delete Warehouse',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0), // Add spacing between buttons
                SizedBox(
                  width: double.infinity, // Make the button full width
                  child: ElevatedButton(
                    onPressed: () => _selectStore(context),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.purple[500],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Select Warehouse',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0), // Add spacing between buttons
                SizedBox(
                  width: double.infinity, // Make the button full width
                  child: ElevatedButton(
                    onPressed: () => _inviteToStore(context, storeReference),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Invite',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _getStoreImage() async {
    try {
      DocumentSnapshot storeSnapshot = await storeReference.get();
      List<int> imageBytes = List<int>.from(storeSnapshot['image']);
      return Uint8List.fromList(imageBytes);
    } catch (e) {
      // print('Error loading store image: $e');
      return null;
    }
  }


  Future<void> _deleteStore(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this Warehouse?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _performDelete(context);
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: const Text('Delete'),
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
          await _deleteProductsCollection(storeReference.collection('products'));
          transaction.delete(storeReference);
          transaction.update(FirebaseFirestore.instance.collection('users').doc(userId), {
            'stores': FieldValue.arrayRemove([storeReference]),
          });
        }
      });

      Navigator.pop(context);
    } catch (e) {
      // print('Error deleting store: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete Warehouse. Please try again.')));
    }
  }

  Future<void> _selectStore(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentStore', storeReference.id);
      Navigator.popUntil(context, ModalRoute.withName('/'));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warehouse selected successfully!')),
      );
    } catch (error) {
      // print('Error selecting store: $error');
    }
  }

  Future<void> _deleteProductsCollection(CollectionReference productsCollection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentStore');
    QuerySnapshot querySnapshot = await productsCollection.get();
    for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
      await documentSnapshot.reference.delete();
    }
  }

  Future<void> _inviteToStore(BuildContext context, DocumentReference storeReference) async {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Invite to Warehouse'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Enter Email'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      setState(() {}); // Rebuild the dialog to update the state of the Invite button
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: emailController.text.trim().isEmpty ? null : () async {
                      String email = emailController.text.trim();
                      await inviteToStore(email, storeReference);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Invite'),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> inviteToStore(String receiverEmail, DocumentReference storeRef) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: receiverEmail)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // print('No user found with email: $receiverEmail');
        return;
      }

      String receiverUserId = querySnapshot.docs.first.id;
      await sendInvitation(receiverUserId, storeRef);

      // print('Invitation sent to user with email: $receiverEmail');
    } catch (error) {
      // print('Error inviting user: $error');
      throw Exception('Error inviting user: $error');
    }
  }

  Future<void> sendInvitation(String receiverUserId, DocumentReference storeRef) async {
    try {
      String invitationId = FirebaseFirestore.instance.collection('requests').doc().id;
      String senderId = FirebaseAuth.instance.currentUser!.uid;

      DocumentReference senderRef = FirebaseFirestore.instance.collection('users').doc(senderId);
      DocumentReference receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverUserId);

      DocumentSnapshot storeSnapshot = await storeRef.get();
      String storeName = storeSnapshot['name'];

      Map<String, dynamic> invitationData = {
        'sender': senderRef,
        'receiver': receiverRef,
        'store': storeRef,
        'storeName': storeName,
        'type': 'Invitation',
        'senderEmail': FirebaseAuth.instance.currentUser!.email,
      };

      await FirebaseFirestore.instance.collection('requests').doc(invitationId).set(invitationData);

      // print('Invitation sent to user with ID: $receiverUserId for store with reference: $storeRef');
    } catch (error) {
      // print('Error sending invitation: $error');
      throw Exception('Error sending invitation: $error');
    }
  }
}
