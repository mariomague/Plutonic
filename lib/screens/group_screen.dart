import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animated_widgets/animated_widgets.dart'; // Importa el paquete

import 'store_options_screen.dart';
import 'add_store.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late Future<List<DocumentSnapshot>> _storesFuture;
  bool _display = false;

  @override
  void initState() {
    super.initState();
    _storesFuture = _loadStores();
    _display = true; // Cambiamos _display a true al cargar la página
  }

  Future<List<DocumentSnapshot>> _loadStores() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userData.exists || !userData.data()!.containsKey('stores')) {
      return [];
    }

    final List<DocumentReference> storeReferences = List<DocumentReference>.from(userData['stores']);
    if (storeReferences.isEmpty) {
      return [];
    }

    return Future.wait(storeReferences.map((ref) => ref.get()));
  }

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
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _storesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No stores available'));
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 16),
            itemCount: snapshot.data!.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final storeData = snapshot.data![index].data() as Map<String, dynamic>;
              final bool isUserOwner = storeData.containsKey('users') &&
                  (storeData['users'] as List<dynamic>).any(
                        (userRef) => userRef.id == FirebaseAuth.instance.currentUser!.uid,
                      );

              return OpacityAnimatedWidget.tween(
                opacityEnabled: 1,
                opacityDisabled: 0,
                enabled: _display,
                duration: Duration(milliseconds: 500),
                child: ListTile(
                  leading: isUserOwner ? Icon(Icons.star) : null,
                  title: Text(storeData['name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoreOptionsScreen(snapshot.data![index].reference),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddStore()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
