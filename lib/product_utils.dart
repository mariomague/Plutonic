import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProductDialog extends StatefulWidget {
  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController _productNameController = TextEditingController();
  File? _imageFile;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuevo producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _productNameController,
            decoration: InputDecoration(
              hintText: 'Nombre del producto',
            ),
          ),
          SizedBox(height: 16),
          _imageFile != null
              ? Image.file(_imageFile!)
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _captureImage,
                    child: Text('Capturar imagen'),
                  ),
                ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cerrar el diálogo sin agregar el producto
          },
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            final productId = await addProduct(context, _productNameController.text, _imageFile);
            Navigator.of(context).pop(productId);
          },
          child: Text('Agregar'),
        ),
      ],
    );
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    super.dispose();
  }

  Future<String?> addProduct(BuildContext context, String productName, File? image) async {
    final productRef = FirebaseFirestore.instance.collection('products');

    try {
      final imageUrl = await _uploadImage(image);
      final newProductRef = await productRef.add({'name': productName, 'image': imageUrl});
      return newProductRef.id;
    } catch (error) {
      print('Error al agregar el producto: $error');
      return null;
    }
  }

  Future<String?> _uploadImage(File? image) async {
    if (image == null) return null;

    try {
      final storageRef = firebase_storage.FirebaseStorage.instance.ref().child('product_images/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (error) {
      print('Error al subir la imagen: $error');
      return null;
    }
  }
}

Future<void> deleteProduct(String? productId) async {
  if (productId == null) return;

  final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
  await productRef.delete();
}

Future<void> updateProductName(String productId, String newName) async {
  if (productId.isEmpty || newName.isEmpty) return;

  final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
  await productRef.update({'name': newName});
}

Future<void> removeProduct(String productId) async {
  if (productId.isEmpty) return;

  final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
  await productRef.delete();
}
