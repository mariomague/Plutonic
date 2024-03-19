import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../vision_detector_views/barcode_scanner_view.dart';
import 'product_details_screen.dart';
import 'dart:typed_data';
import 'package:animated_widgets/animated_widgets.dart';

class BarcodeScannerViewScreen extends StatefulWidget {
  @override
  _BarcodeScannerViewScreenState createState() => _BarcodeScannerViewScreenState();
}

class _BarcodeScannerViewScreenState extends State<BarcodeScannerViewScreen> {
  String? selectedStoreId;
  bool _display = false;

  @override
  void initState() {
    super.initState();
    _clearUserDataIfBadUser();
    _getStoreIdFromPrefs();
    _display = true;
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

    // ignore: unused_local_variable
    final storeRef = FirebaseFirestore.instance.collection('stores').doc(selectedStoreId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.purple[200], // Morado claro
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              title: StreamBuilder<DocumentSnapshot>(
                stream: storeRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container();
                  }
                  final storeData = snapshot.data!.data() as Map<String, dynamic>;
                  final storeName = storeData['name'] ?? 'Unnamed Store';
                  return Text(
                    storeName,
                    style: const TextStyle(fontSize: 18), textAlign: TextAlign.center,
                  );
                },
              ),
              background: Image.network(
                'https://via.placeholder.com/500x200', // Placeholder de imagen del almacén
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed: () {
                  // Implementar la funcionalidad de establecer una foto del almacén
                },
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(10.0),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('stores/$selectedStoreId/products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(child: Center(child: Text('Error: ${snapshot.error}')));
                }

                if (!snapshot.hasData) {
                  return SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                }

                List<Widget> productsWidgets = [];
                List<Widget> outOfStockWidgets = [];

                final products = snapshot.data!.docs;
                products.sort((a, b) => a['quantity'].compareTo(b['quantity'])); // Ordena por cantidad

                for (var doc in products) {
                  final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  final productName = data.containsKey('name') ? data['name'] : 'Unnamed Product';
                  final productQuantity = data['quantity'] ?? 0;
                  final imageList = data['image'] as List<dynamic>?;

                  Widget leadingWidget;
                  if (imageList != null && imageList.isNotEmpty) {
                    final _imageBytes = Uint8List.fromList(imageList.cast<int>());
                    leadingWidget = Image.memory(_imageBytes, width: 50, height: 50, fit: BoxFit.cover);
                  } else {
                    leadingWidget = Icon(Icons.image, size: 50);
                  }

                  Widget productWidget = OpacityAnimatedWidget.tween(
                    opacityEnabled: 1,
                    opacityDisabled: 0,
                    enabled: _display,
                    duration: Duration(milliseconds: 500),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 5,
                            blurRadius: 10,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        leading: Container(
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: Colors.purple[200], // Morado claro
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: leadingWidget,
                        ),
                        title: Text(
                          productName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Quantity: $productQuantity',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(productId: doc.id, storeId: selectedStoreId!),
                            ),
                          );
                        },
                      ),
                    ),
                  );

                  if (productQuantity == 0) {
                    outOfStockWidgets.add(productWidget);
                  } else {
                    productsWidgets.add(productWidget);
                  }
                }

                return SliverList(
                  delegate: SliverChildListDelegate([
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: outOfStockWidgets.isNotEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.only(left: 20, bottom: 10),
                                child: Text('Out Of:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                color: Colors.grey[200],
                                child: Column(
                                  children: outOfStockWidgets,
                                ),
                              ),
                              SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.only(left: 20, bottom: 10),
                                child: Text('Products on hand:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              ...productsWidgets,
                            ]
                          : productsWidgets,
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BarcodeScannerView(isAddingProduct: true),
                ),
              );
            },
            child: Icon(Icons.add),
            backgroundColor: Colors.purple[200], // Morado claro
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BarcodeScannerView(isAddingProduct: false),
                ),
              );
            },
            child: Icon(Icons.remove),
            backgroundColor: Colors.purple[200], // Morado claro
          ),
        ],
      ),
    );
  }
}
