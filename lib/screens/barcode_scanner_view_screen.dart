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

    // Verificar si el usuario actual es diferente al usuario almacenado en las preferencias compartidas
    if (user == null || user.uid != prefs.getString('userId')) {
      // Si el usuario actual es nulo o su UID es diferente al UID almacenado en las preferencias
      // Remover los datos almacenados en las preferencias
      prefs.remove('userId');
      prefs.remove('currentStore');
      if (user != null) {
        // Si el usuario actual no es nulo, añadir a userId en las preferencias
        prefs.setString('userId', user.uid);
        
      }
      // Llamar a setState para actualizar la UI, en este caso, establecer selectedStoreId en null
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
          // Camera preview (placeholder for BarcodeScannerView)
          Container(
            // color: Colors.black, // Simulate camera preview
            width: double.infinity,
            height: double.infinity,
          ),
          // Nombre de la tienda
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
          // Contenido de la pantalla
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

                      // Convierte los documentos a una lista de widgets
                      final products = snapshot.data!.docs.map((doc) {
                        // Accede a la ID del producto
                        final productId = doc.id;

                        // Accede a los datos del documento como un mapa
                        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                        // Accede al nombre del producto si existe, de lo contrario usa un valor predeterminado
                        final productName = data.containsKey('name') ? data['name'] : 'Unnamed Product';

                        // Accede a la cantidad del producto
                        final productQuantity = data['quantity'];

                        // Accede a la lista de bytes de la imagen del producto si existe
                        final imageList = data['image'] as List<dynamic>;
                        final _imageBytes = Uint8List.fromList(imageList.cast<int>());

                        return ListTile(
                          leading: Image.memory(_imageBytes),
                          title: Text(productName),
                          subtitle: Text('$productId - $productQuantity', style: TextStyle(color: Colors.grey)),
                          onTap: () {
                            // Navega a la pantalla de detalles del producto
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
                // Action buttons
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
