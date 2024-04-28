import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../vision_detector_views/barcode_scanner_view.dart';
import 'product_details_screen.dart';
import 'dart:typed_data';

class BarcodeScannerViewScreen extends StatefulWidget {
  const BarcodeScannerViewScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _BarcodeScannerViewScreenState createState() =>
      _BarcodeScannerViewScreenState();
}

class _BarcodeScannerViewScreenState extends State<BarcodeScannerViewScreen> {
  String? selectedStoreId;
  final bool _display = true;

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
      return const Center(child: Text('Sign in to continue'));
    } else if (selectedStoreId == null) {
      return const Center(child: Text('Select a warehouse to continue'));
    }

    final storeRef =
        FirebaseFirestore.instance.collection('stores').doc(selectedStoreId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.purple[300], // Ajusta el color de fondo
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              title: StreamBuilder<DocumentSnapshot>(
                stream: storeRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container();
                  }
                  final storeData = snapshot.data!.data() as Map<String, dynamic>;
                  final storeName = storeData['name'] ?? 'Unnamed Warehouse';
                  return Text(
                    storeName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Modifica el estilo del texto
                    textAlign: TextAlign.center,
                  );
                },
              ),
              background: StreamBuilder<DocumentSnapshot>(
                stream: storeRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Container(
                      color: Colors.grey[300], // Default background color
                    );
                  }
                  final storeData = snapshot.data!.data() as Map<String, dynamic>;
                  final imageList = storeData['image'] as List<dynamic>?;
                  return _buildImageWidget(imageList);
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(10.0),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stores/$selectedStoreId/products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                      child: Center(child: Text('Error: ${snapshot.error}')));
                }

                if (!snapshot.hasData) {
                  return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()));
                }

                final products = snapshot.data!.docs;
                products.sort((a, b) => a['quantity'].compareTo(b['quantity']));

                List<Widget> productWidgets = [];
                List<Widget> outOfStockWidgets = [];

                for (var doc in products) {
                  final Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  final productName =
                      data.containsKey('name') ? data['name'] : 'Unnamed Product';
                  final productQuantity = data['quantity'] ?? 0;
                  final imageList = data['image'] as List<dynamic>?;

                  Widget leadingWidget;
                  if (imageList != null && imageList.isNotEmpty) {
                    final imageBytes =
                        Uint8List.fromList(imageList.cast<int>());
                    leadingWidget = Image.memory(imageBytes,
                        width: 50, height: 50, fit: BoxFit.cover);
                  } else {
                    leadingWidget = const Icon(Icons.image, size: 50);
                  }

                  Widget productWidget = Opacity(
                    opacity: _display ? 1.0 : 0.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          leading: Container(
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              color: productQuantity == 0 ? Colors.red[200] : Colors.purple[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: leadingWidget,
                          ),
                          title: Text(
                            productName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                          ),
                          subtitle: Text(
                            'Quantity: $productQuantity',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey, fontFamily: 'Roboto'),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                  productId: doc.id,
                                  storeId: selectedStoreId!,
                                  heroTag: '${doc.id}_$selectedStoreId!',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );

                  if (productQuantity == 0) {
                    outOfStockWidgets.add(productWidget);
                  } else {
                    productWidgets.add(productWidget);
                  }
                }

                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (outOfStockWidgets.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 20, bottom: 10),
                            child: Text(
                              'Out Of Stock:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: outOfStockWidgets,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: productWidgets,
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
            heroTag: "addButton",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const BarcodeScannerView(isAddingProduct: true),
                ),
              );
            },
            backgroundColor: Colors.purple[300], // Morado menos oscuro
            child: const Icon(Icons.add, color: Colors.white), // Blanco
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "removeButton",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeScannerView(isAddingProduct: false),
                ),
              );
            },
            backgroundColor: Colors.red[300], // Morado menos oscuro
            child: const Icon(Icons.remove, color: Colors.white), // Blanco
          ),
        ],
      ),
    );
  }
}

Widget _buildImageWidget(List<dynamic>? imageList) {
  if (imageList != null && imageList.isNotEmpty) {
    final imageBytes = Uint8List.fromList(imageList.cast<int>());
    return Image.memory(imageBytes, fit: BoxFit.cover);
  } else {
    return Image.network(
      'https://via.placeholder.com/500x200', // Imagen de marcador de posición
      fit: BoxFit.cover,
    );
  }
}