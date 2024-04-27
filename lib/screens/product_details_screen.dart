import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../product_utils.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String storeId;
  final String productId;
  final String heroTag; // Add heroTag property

  const ProductDetailsScreen({Key? key, required this.storeId, required this.productId, required this.heroTag}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}


class _ProductDetailsScreenState extends State<ProductDetailsScreen> {

  Future<void> _updateImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      await updateProductImage(widget.storeId, widget.productId, imageFile);

      // Actualizar la imagen en el estado
      setState(() {
        _imageBytes = imageFile.readAsBytesSync();
      });
    }
  }
  bool _isEditing = false;
  late String _productName = '';
  late Uint8List _imageBytes = Uint8List(0);
  bool _imageLoaded = false;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final productRef = FirebaseFirestore.instance.collection('stores/${widget.storeId}/products').doc(widget.productId);

    final snapshot = await productRef.get();
    final productData = snapshot.data();

    if (productData != null && productData.containsKey('image')) {
      final imageList = productData['image'] as List<dynamic>;
      _imageBytes = Uint8List.fromList(imageList.cast<int>());
      setState(() {
        _imageLoaded = true;
      });
    }
  }


  Widget _buildActionButton({VoidCallback? onPressed, required String buttonType}) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: buttonType == 'edit' ? Colors.purple[300] : Colors.red[300],
      onPressed: onPressed,
      child: Icon(buttonType == 'edit' ? (_isEditing ? Icons.done : Icons.edit) : Icons.delete, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productRef = FirebaseFirestore.instance.collection('stores/${widget.storeId}/products').doc(widget.productId);
    Image.memory(
      _imageBytes,
      fit: BoxFit.cover,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.purple[300],
      ),
      body: SingleChildScrollView( 
        child: StreamBuilder<DocumentSnapshot>(
          stream: productRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.data() == null) {
              return const Center(child: Text('Product not found'));
            }

            final productData = snapshot.data!.data()! as Map<String, dynamic>;

            _productName = productData['name'] ?? '';
            final productQuantity = productData['quantity'] ?? 0;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Card(
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Product Name:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                        ),
                        Text(
                          _productName,
                          style: const TextStyle(fontSize: 18, fontFamily: 'Roboto'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Product Quantity:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                        ),
                        Text(
                          '$productQuantity',
                          style: const TextStyle(fontSize: 18, fontFamily: 'Roboto'),
                        ),
                      ],
                    ),
                  ),
                ),
                  const SizedBox(height: 20),
                  if (_isEditing) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            addProduct(context, widget.storeId, widget.productId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[300],
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            deleteProduct(widget.storeId, widget.productId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[300],
                          ),
                          child: const Icon(Icons.remove, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_imageLoaded)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Hero(
                            tag: '${widget.productId}_${widget.storeId}',
                            child: Image.memory(
                              _imageBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isEditing) ...[
                    Center(
                      child: ElevatedButton(
                        onPressed: _updateImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[300],
                        ),
                        child: const Text('Change Image', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _buildActionButton(
            onPressed: () {
              if (_isEditing) {
                productRef.update({'name': _productName});
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            buttonType: 'edit',
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            onPressed:  () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text('Are you sure you want to delete this product?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          removeProduct(widget.storeId, widget.productId);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            },
            buttonType: 'delete',
          ),
        ],
      ),
    );
  }
}