import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../vision_detector_views/barcode_scanner_view.dart';
import 'product_details_screen.dart';
import 'dart:typed_data';

class BarcodeScannerViewScreen extends StatefulWidget {
  @override
  _BarcodeScannerViewScreenState createState() => _BarcodeScannerViewScreenState();
}

class _BarcodeScannerViewScreenState extends State<BarcodeScannerViewScreen> {
  String? selectedStoreId;

  @override
  void initState() {
    super.initState();
    _clearUserDataIfBadUser();
    _getStoreIdFromPrefs();
  }

  Future<void> _clearUserDataIfBadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (user == null || user.uid != prefs.getString('userId')) {
      prefs.remove('userId');
      prefs.remove('currentStore');
      if (user != null) {
        prefs.setString('userId', user.uid);        
      }
      setState(() {
        selectedStoreId = null;
      });
    }
  }

  Future<void> _getStoreIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    selectedStoreId = prefs.getString('currentStore');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Center(child: Text('Sign in to continue'));
    } else if (selectedStoreId == null) {
      return Center(child: Text('Select a store to continue'));
    }

    final storeRef = FirebaseFirestore.instance.collection('stores').doc(selectedStoreId);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: EdgeInsets.all(10),
              child: StreamBuilder<DocumentSnapshot>(
                stream: storeRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container();
                  }
                  final storeData = snapshot.data!.data() as Map<String, dynamic>;
                  final storeName = storeData['name'] ?? 'Unnamed Store';
                  return Text(
                    storeName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('stores/$selectedStoreId/products').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final products = snapshot.data!.docs.map((doc) {
                        final productId = doc.id;
                        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        final productName = data.containsKey('name') ? data['name'] : 'Unnamed Product';
                        final productQuantity = data['quantity'];
                        final imageList = data['image'] as List<dynamic>?;

                        Widget leadingWidget;
                        if (imageList != null && imageList.isNotEmpty) {
                          final _imageBytes = Uint8List.fromList(imageList.cast<int>());
                          leadingWidget = Image.memory(_imageBytes);
                        } else {
                          leadingWidget = Icon(Icons.image);
                        }

                        return ListTile(
                          leading: leadingWidget,
                          title: Text(productName),
                          subtitle: Text('$productId - $productQuantity', style: TextStyle(color: Colors.grey)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(productId: productId, storeId: selectedStoreId!),
                              ),
                            );
                          },
                        );
                      }).toList();

                      return ListView(
                        children: products,
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarcodeScannerView(isAddingProduct: true),
                          ),
                        );
                      },
                      icon: Icon(Icons.add, color: Colors.green),
                      label: Text("Add Product"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarcodeScannerView(isAddingProduct: false),
                          ),
                        );
                      },
                      icon: Icon(Icons.remove, color: Colors.red),
                      label: Text("Remove Product"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
