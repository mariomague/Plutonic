// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animated_widgets/animated_widgets.dart';

import 'store_options_screen.dart';
import 'add_store.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late Future<List<DocumentSnapshot>> _storesFuture;
  bool _display = false;

  @override
  void initState() {
    super.initState();
    _loadStores();
    _display = true;
  }

  Future<void> _loadStores() async {
    setState(() {
      _storesFuture = _getStores();
    });
  }

  Future<List<DocumentSnapshot>> _getStores() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final userData =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userData.exists || !userData.data()!.containsKey('stores')) {
      return [];
    }

    final List<DocumentReference> storeReferences =
        List<DocumentReference>.from(userData['stores']);
    if (storeReferences.isEmpty) {
      return [];
    }

    return Future.wait(storeReferences.map((ref) => ref.get()));
  }

  Future<void> _refreshStores() async {
    await _loadStores();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text('Sign in to continue'),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Warehouses & Groups',
            style: TextStyle(color: Colors.white), // Cambia el color del texto a blanco
          ),
          backgroundColor: Colors.purple[300], // Morado oscuro
        ),
        body: RefreshIndicator(
          onRefresh: _refreshStores,
          color: Colors.purple[300], // Morado oscuro
          child: FutureBuilder<List<DocumentSnapshot>>(
            future: _storesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No stores available'));
              }

              return Padding(
                padding: EdgeInsets.all(16.0),
                child: ListView.separated(
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final storeData = snapshot.data![index].data() as Map<String, dynamic>;
                    final bool isUserOwner = storeData.containsKey('users') &&
                        (storeData['users'] as List<dynamic>).any(
                              (userRef) => userRef.id == FirebaseAuth.instance.currentUser!.uid,
                            );
                    final String description = storeData.containsKey('description')
                        ? storeData['description']
                        : 'Empty description';

                    return OpacityAnimatedWidget.tween(
                      opacityEnabled: 1,
                      opacityDisabled: 0,
                      enabled: _display,
                      duration: Duration(milliseconds: 500),
                      child: ListTile(
                        leading: isUserOwner ? Icon(Icons.star, color: Colors.purple[300]) : null, // Morado oscuro
                        title: Text(storeData['name']),
                        subtitle: Text(description),
                        onTap: () async {
                          final storeData = snapshot.data![index].data() as Map<String, dynamic>;
                          final String storeName = storeData['name']; // Obtener el nombre de la tienda
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                StoreOptionsScreen(snapshot.data![index].reference, storeName),
                            ),
                          );
                          await _loadStores(); // Reload stores after returning from StoreOptionsScreen
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddStore()),
            );
            await _loadStores(); // Reload stores after adding a new one
          }, 
          backgroundColor: Colors.purple[300],
          child: Icon(Icons.add, color: Colors.white), // Morado oscuro
        ),
      );
    }
  }
}