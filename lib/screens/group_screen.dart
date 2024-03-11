import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'store_options_screen.dart';
import 'add_store.dart';

class GroupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Warehouses & Groups'),
        actions: [
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddStore()),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, AsyncSnapshot<User?> authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!authSnapshot.hasData || authSnapshot.data == null) {
            return Center(child: Text('No user logged in'));
          }

          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('No data available'));
              }

              Map<String, dynamic>? userData = snapshot.data!.data() as Map<String, dynamic>?;

              if (userData == null || !userData.containsKey('stores')) {
                return Center(child: Text('No stores available'));
              }

              List<DocumentReference> storeReferences =
                  List<DocumentReference>.from(userData['stores']);
              if (storeReferences.isEmpty) {
                return Center(child: Text('No stores associated with this user'));
              }

              return ListView.builder(
                itemCount: storeReferences.length,
                itemBuilder: (context, index) {
                  return FutureBuilder(
                    future: storeReferences[index].get(),
                    builder: (context, AsyncSnapshot<DocumentSnapshot> storeSnapshot) {
                      if (storeSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!storeSnapshot.hasData || !storeSnapshot.data!.exists) {
                        return SizedBox(); // Placeholder or error message
                      }

                      Map<String, dynamic>? storeData = storeSnapshot.data!.data() as Map<String, dynamic>?;

                      if (storeData == null || !storeData.containsKey('name')) {
                        return SizedBox(); // Placeholder or error message
                      }

      
                      final bool isUserOwner = storeData.containsKey('users') &&
                        (storeData['users'] as List<dynamic>).any((userRef) => userRef.id == authSnapshot.data!.uid);


                      return ListTile(
                        leading: isUserOwner ? Icon(Icons.star) : null,
                        title: Text(storeData['name']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StoreOptionsScreen(storeSnapshot.data!.reference)),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
