import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProductDialog extends StatefulWidget {
  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  TextEditingController _productNameController = TextEditingController();
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
          onPressed: () {
            // IMPLEMENTAR AQUI AÑADIR PRODUCTO CON SU NOMBRE Y
            Navigator.of(context).pop(); // Devolver el nombre del producto ingresado y la imagen capturada
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
}

Future<void> addProduct(BuildContext context, String? storeId, String? productId, {String? productName, File? image}) async {
  final productRef = FirebaseFirestore.instance.collection('stores/$storeId/products').doc(productId);

  // Verificar si el producto ya existe en la base de datos
  final existingProduct = await productRef.get();

  if (existingProduct.exists) {
    // Si el producto ya existe, actualizamos la cantidad sumando 1
    final currentQuantity = existingProduct.data()!['quantity'] ?? 0;
    await productRef.update({'quantity': currentQuantity + 1});
  } else {
    // Si el producto no existe, lo agregamos con cantidad 1 (y nombre si se proporciona)
    final dataToAdd = <String, dynamic>{'quantity': 1};
    if (productName != null) {
      dataToAdd['name'] = productName;
    } else {
      // Si no se proporciona el nombre del producto, mostramos un diálogo para que el usuario lo ingrese
      final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (BuildContext context) {
          return AddProductDialog();
        },
      );
      if (result != null) {
        if (result.containsKey('name')) {
          productName = result['name'] as String?;
          if (productName != null && productName.isNotEmpty) {
            dataToAdd['name'] = productName;
          }
        }
        if (result.containsKey('image')) {
          image = result['image'] as File?;
        }
      }
    }

    // Subir la imagen al Firebase Storage si se proporciona
    if (image != null) {
      // Comprimir la imagen antes de subirla
      final compressedImage = await compressImage(image);

      // Subir la imagen comprimida al Firebase Storage
      final storageRef = firebase_storage.FirebaseStorage.instance.ref().child('product_images').child(productId!);
      final uploadTask = storageRef.putFile(compressedImage);
      await uploadTask.whenComplete(() => null);

      // Obtener la URL de la imagen subida
      final imageUrl = await storageRef.getDownloadURL();

      // Agregar la URL de la imagen al documento del producto en Firestore
      dataToAdd['image'] = imageUrl;
    }

    await productRef.set(dataToAdd);
  }
}

// Función para comprimir la imagen
Future<File> compressImage(File image) async {
  // Implementa la lógica para comprimir la imagen aquí
  // Por ejemplo, puedes usar flutter_image_compress
  // Consulta la documentación de flutter_image_compress para más detalles
  return image;
}

Future<void> deleteProduct(String? storeId, String? productId) async {
  final productRef = FirebaseFirestore.instance.collection('stores/$storeId/products').doc(productId);

  // Obtenemos el producto actual
  final existingProduct = await productRef.get();

  if (existingProduct.exists) {
    // Verificamos si la cantidad es mayor que 0 antes de restar
    final currentQuantity = existingProduct.data()!['quantity'] ?? 0;
    if (currentQuantity > 0) {
      // Restamos 1 a la cantidad
      final newQuantity = currentQuantity - 1;
      // Actualizamos la cantidad con el nuevo valor
      await productRef.update({'quantity': newQuantity});
    }
  }
}

Future<void> updateProductName(String storeId, String productId, String newName) async {
  final productRef = FirebaseFirestore.instance.collection('stores/$storeId/products').doc(productId);

  // Verificamos si el producto existe antes de intentar actualizar su nombre
  final existingProduct = await productRef.get();
  if (existingProduct.exists) {
    // Actualizamos el nombre del producto
    await productRef.update({'name': newName});
  }
}

Future<void> removeProduct(String storeId, String productId) async {
  final productRef = FirebaseFirestore.instance.collection('stores/$storeId/products').doc(productId);

  // Eliminamos el producto de la base de datos
  await productRef.delete();
}
