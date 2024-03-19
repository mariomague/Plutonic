import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../product_utils.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

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
  bool _imageLoaded = false;
  final picker = ImagePicker(); // Instancia de ImagePicker

  @override
  void initState() {
    super.initState();
    // Cargar la imagen al inicio
    _loadImage();
  }

  // Método para cargar la imagen desde la base de datos
  Future<void> _loadImage() async {
    final productRef = FirebaseFirestore.instance.collection('stores/${widget.storeId}/products').doc(widget.productId);

    final snapshot = await productRef.get();
    final productData = snapshot.data() as Map<String, dynamic>?;

    if (productData != null && productData.containsKey('image')) {
      final imageList = productData['image'] as List<dynamic>;
      _imageBytes = Uint8List.fromList(imageList.cast<int>());
      setState(() {
        _imageLoaded = true;
      });
    }
  }

  // Método para seleccionar una imagen de la galería
  Future<void> _selectImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() async {
        _imageBytes = Uint8List.fromList(await pickedFile.readAsBytes());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productRef = FirebaseFirestore.instance.collection('stores/${widget.storeId}/products').doc(widget.productId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
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
                Text(
                  'Product Name: $_productName',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  'Product Quantity: $productQuantity',
                  style: const TextStyle(fontSize: 18),
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
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          deleteProduct(widget.storeId, widget.productId);
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectImage, // Llama al método para seleccionar una imagen
                    child: const Text('Change Image'),
                  ),
                ],
                const SizedBox(height: 20),
                if (_imageLoaded) // Mostrar la imagen si está cargada
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 300,
                      maxWidth: MediaQuery.of(context).size.width,
                    ),
                    child: Center(
                      child: Image.memory(
                        _imageBytes,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 212, 212, 212),
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 115, 105),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: IconButton(
                  onPressed: () {
                    // Muestra un diálogo de confirmación antes de borrar
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
                  icon: const Icon(Icons.delete),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 108, 208, 255),
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
