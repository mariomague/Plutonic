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

Future<void> _inviteToStore(BuildContext context, DocumentReference storeReference) async {
  TextEditingController emailController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Invite to Store'),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: 'Enter Email'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              String email = emailController.text.trim();
              await inviteToStore(email, storeReference); // Call function to invite to store
              Navigator.of(context).pop();
            },
            child: Text('Invite'),
          ),
        ],
      );
    },
  );
}


Future<void> inviteToStore(String receiverEmail, DocumentReference storeRef) async {
  try {
    // Realizar una consulta para buscar un usuario con el correo electrónico proporcionado
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: receiverEmail)
        .get();

    // Comprobar si se encontraron resultados
    if (querySnapshot.docs.isEmpty) {
      print('No user found with email: $receiverEmail');
      return; // Salir de la función si no se encontró ningún usuario
    }

    // Obtener el ID de usuario del primer usuario encontrado (debería haber solo uno)
    String receiverUserId = querySnapshot.docs.first.id;

    // Invitar al usuario usando el ID de usuario y la referencia a la tienda
    await sendInvitation(receiverUserId, storeRef);

    print('Invitation sent to user with email: $receiverEmail');
  } catch (error) {
    print('Error inviting user: $error');
    throw Exception('Error inviting user: $error');
  }
}

Future<void> sendInvitation(String receiverUserId, DocumentReference storeRef) async {
  try {
    // Generar una nueva ID para la invitación
    String invitationId = FirebaseFirestore.instance.collection('requests').doc().id;

    // Obtener el ID del usuario actualmente autenticado
    String senderId = FirebaseAuth.instance.currentUser!.uid;

    // Obtener las referencias a los documentos de usuario para el remitente y el receptor
    DocumentReference senderRef = FirebaseFirestore.instance.collection('users').doc(senderId);
    DocumentReference receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverUserId);

    // Obtener el nombre de la tienda
    DocumentSnapshot storeSnapshot = await storeRef.get();
    String storeName = storeSnapshot['name'];

    // Construir el mapa de datos para la invitación
    Map<String, dynamic> invitationData = {
      'sender': senderRef,
      'receiver': receiverRef,
      'store': storeRef,
      'storeName': storeName, // Obtener el nombre de la tienda de storeRef
      'type': 'Invitation',
      'senderEmail': FirebaseAuth.instance.currentUser!.email,
    };

    // Guardar los datos de la invitación en Firestore bajo la nueva ID generada
    await FirebaseFirestore.instance.collection('requests').doc(invitationId).set(invitationData);

    print('Invitation sent to user with ID: $receiverUserId for store with reference: $storeRef');
  } catch (error) {
    print('Error sending invitation: $error');
    throw Exception('Error sending invitation: $error');
  }
}

