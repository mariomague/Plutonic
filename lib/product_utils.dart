import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
// Función para comprimir la imagen

Future<File> compressImage(File image) async {
  // return image;
  try {
    // Crear una nueva ruta de archivo para la imagen comprimida
    final filePath = image.absolute.path;
    final lastIndex = filePath.lastIndexOf(new RegExp(r'.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";

    // Comprimir la imagen y obtener el nuevo archivo comprimido
    final result = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      outPath,
      quality: 5, // Ajusta la calidad de compresión según tus necesidades
    );

    if (result != null) {
      final file = File(result.path); // Convertir XFile a File
      print('Tamaño de imagen original: ${image.lengthSync()} bytes');
      print('Tamaño de imagen comprimida: ${file.lengthSync()} bytes');
      return file;
    } else {
      print('Error: El resultado de la compresión es nulo.');
      throw Exception('Error: El resultado de la compresión es nulo.');
    }
  } catch (e) {
    print('Error al comprimir la imagen: $e');
    throw Exception('Error al comprimir la imagen: $e');
  }
}





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
            Map<String, dynamic> result = {
              'name': _productNameController.text,
              'image': _imageFile,
            };
            Navigator.of(context).pop(result); // Devolver el nombre del producto ingresado y la imagen capturada
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
        // Comprimir la imagen antes de subirla (opcional)
        final File? imageFile = result['image'] as File?;
        if (imageFile != null) {
          final compressedImage = await compressImage(imageFile);
        
          // Convertir la imagen comprimida a bytes
          final imageBytes = await compressedImage.readAsBytes();
          // Agregar la imagen al documento del producto en Firestore
          dataToAdd['image'] = imageBytes;
        }
      }
    }
  }

  // Añadir el nuevo producto a Firestore
  await productRef.set(dataToAdd);
}

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