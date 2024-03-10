import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../product_utils.dart';
import 'dart:typed_data';

class ProductDetailsScreen extends StatefulWidget {
  final String storeId;
  final String productId;

  const ProductDetailsScreen({Key? key, required this.storeId, required this.productId}) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isEditing = false;
  late String _productName = '';
  late Uint8List _imageBytes = Uint8List(0); // Nueva variable para almacenar los bytes de la imagen

  @override
  Widget build(BuildContext context) {
    final productRef = FirebaseFirestore.instance.collection('stores/${widget.storeId}/products').doc(widget.productId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: productRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return Center(child: Text('Product not found'));
          }

          final productData = snapshot.data!.data()! as Map<String, dynamic>;

          _productName = productData['name'] ?? '';
          final productQuantity = productData['quantity'] ?? 0;
          if (productData.containsKey('image')) {
            final imageList = productData['image'] as List<dynamic>;
            _imageBytes = Uint8List.fromList(imageList.cast<int>());
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_imageBytes.isNotEmpty) // Mostrar la imagen si existen bytes
                  Image.memory(_imageBytes), // Mostrar la imagen desde los bytes
                _isEditing
                    ? TextField(
                        decoration: InputDecoration(labelText: 'Product Name', hintText: _productName),
                        onChanged: (value) {
                          _productName = value;
                        },
                      )
                    : Text(
                        'Product Name: $_productName',
                        style: TextStyle(fontSize: 18),
                      ),
                SizedBox(height: 10),
                Text(
                  'Product Quantity: $productQuantity',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                if (_isEditing) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          addProduct(context,widget.storeId, widget.productId);
                        },
                        child: Icon(Icons.add),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          deleteProduct(widget.storeId, widget.productId);
                        },
                        child: Icon(Icons.remove),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 212, 212, 212),
        shape: CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 115, 105),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: IconButton(
                  onPressed: () {
                    // Muestra un diálogo de confirmación antes de borrar
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Confirm Delete'),
                          content: Text('Are you sure you want to delete this product?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                removeProduct(widget.storeId, widget.productId);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.delete),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 108, 208, 255),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: IconButton(
                  onPressed: () {
                    if (_isEditing) {
                      productRef.update({'name': _productName});
                    }
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  icon: Icon(_isEditing ? Icons.done : Icons.edit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
