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
            const SizedBox(height: 16.0), // Add spacing between buttons
            ElevatedButton(
              onPressed: () => _inviteToStore(context, storeReference), // Implement _inviteToStore method
              child: Text('Invite'),
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
                Navigator.popUntil(context, ModalRoute.withName('/'));
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
          await _deleteProductsCollection(storeReference.collection('products'));
          await transaction.delete(storeReference);
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentStore', storeReference.id);
      Navigator.popUntil(context, ModalRoute.withName('/'));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Store selected successfully!')),
      );
    } catch (error) {
      print('Error selecting store: $error');
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
}

Future<void> _inviteToStore(BuildContext context, DocumentReference storeReference) async {
  TextEditingController emailController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Invite to Store'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Enter Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {}); // Rebuild the dialog to update the state of the Invite button
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: emailController.text.trim().isEmpty ? null : () async {
                    String email = emailController.text.trim();
                    await inviteToStore(email, storeReference);
                    Navigator.of(context).pop();
                  },
                  child: Text('Invite'),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
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
      print('No user found with email: $receiverEmail');
      return;
    }

    String receiverUserId = querySnapshot.docs.first.id;
    await sendInvitation(receiverUserId, storeRef);

    print('Invitation sent to user with email: $receiverEmail');
  } catch (error) {
    print('Error inviting user: $error');
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

    print('Invitation sent to user with ID: $receiverUserId for store with reference: $storeRef');
  } catch (error) {
    print('Error sending invitation: $error');
    throw Exception('Error sending invitation: $error');
  }
}
