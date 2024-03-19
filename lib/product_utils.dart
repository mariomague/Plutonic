import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
// import 'dart:typed_data';
// Función para comprimir la imagen

Future<int> fetchNotificationCount() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return 0;

  final userReference = FirebaseFirestore.instance.doc('users/${currentUser.uid}');

  final notificationsCollection = FirebaseFirestore.instance.collection('requests');

  final notificationsSnapshot = await notificationsCollection
      .where('receiver', isEqualTo: userReference)
      .get();

  final notificationDocs = notificationsSnapshot.docs;

  return notificationDocs.length;
}




class NotificationInfo {
  final String requestId;
  final String type;
  final String senderId;
  final String? storeId;
  final String? storeName;
  final String? senderEmail;

  NotificationInfo({
    required this.requestId,
    required this.type,
    required this.senderId,
    this.storeId,
    this.storeName,
    this.senderEmail,
  });
}

Future<List<NotificationInfo>> fetchNotificationsInfo() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return [];

  final userReference = FirebaseFirestore.instance.doc('users/${currentUser.uid}');
  final notificationsCollection = FirebaseFirestore.instance.collection('requests');

  final notificationsSnapshot = await notificationsCollection
      .where('receiver', isEqualTo: userReference)
      .get();

  final notificationDocs = notificationsSnapshot.docs;

  final List<NotificationInfo> notificationsInfo = [];

  for (var doc in notificationDocs) {
    final requestId = doc.id;
    final senderRef = doc['sender'] as DocumentReference;
    final storeRef = doc['store'] as DocumentReference;
    final type = doc['type']; // Obtener el tipo de notificación
    final senderId = senderRef.id;
    final storeId = storeRef.id;

    // Obtener el nombre de la tienda
    final storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
    final storeName = storeSnapshot['name'];

    // Obtener el correo electrónico del remitente
    String? senderEmail;
    // ignore: unnecessary_null_comparison
    if (senderId != null) {
      final senderSnapshot = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      senderEmail = senderSnapshot['email'];
    }

    final notificationInfo = NotificationInfo(
      requestId: requestId,
      type: type,
      senderId: senderId,
      storeId: storeId,
      storeName: storeName,
      senderEmail: senderEmail,
    );

    notificationsInfo.add(notificationInfo);
  }

  return notificationsInfo;
}


Future<void> acceptInvitation(NotificationInfo requestInfo) async {
  try {
    final requestRef = FirebaseFirestore.instance.collection('requests').doc(requestInfo.requestId);
    
    await requestRef.update({'status': 'accepted'}); // Actualiza el estado de la solicitud a "aceptada"
    
    // Obtén la referencia a la tienda usando la ID de la tienda
    final storeRef = FirebaseFirestore.instance.collection('stores').doc(requestInfo.storeId);

    // Obtiene la ID del usuario actualmente autenticado
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;

    // Actualiza el documento del usuario para agregar la referencia de la tienda
    await FirebaseFirestore.instance.collection('users').doc(currentUserID).update({
      'stores': FieldValue.arrayUnion([storeRef]),
    });

    print('Invitation accepted successfully.');
  } catch (e) {
    print('Error accepting invitation: $e');
    throw Exception('Error accepting invitation: $e');
  }
}


Future<void> deleteInvitation(NotificationInfo requestInfo) async {
  try {
    final requestRef = FirebaseFirestore.instance.collection('requests').doc(requestInfo.requestId);
    await requestRef.delete(); // Elimina la solicitud de invitación
    print('Invitation deleted successfully.');
  } catch (e) {
    print('Error deleting invitation: $e');
    throw Exception('Error deleting invitation: $e');
  }
}

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
      quality: 10, // Ajusta la calidad de compresión según tus necesidades
    );

    if (result != null) {
      final file = File(result.path); // Convertir XFile a File
      // print('Tamaño de imagen original: ${image.lengthSync()} bytes');
      // print('Tamaño de imagen comprimida: ${file.lengthSync()} bytes');
      return file;
    } else {
      // print('Error: El resultado de la compresión es nulo.');
      throw Exception('Error: El resultado de la compresión es nulo.');
    }
  } catch (e) {
    // print('Error al comprimir la imagen: $e');
    throw Exception('Error al comprimir la imagen: $e');
  }
}





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
      title: const Text('Nuevo producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _productNameController,
            decoration: const InputDecoration(
              hintText: 'Nombre del producto',
            ),
          ),
          const SizedBox(height: 16),
          _imageFile != null
              ? Image.file(_imageFile!)
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _captureImage,
                    child: const Text('Capturar imagen'),
                  ),
                ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cerrar el diálogo sin agregar el producto
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Map<String, dynamic> result = {
              'name': _productNameController.text,
              'image': _imageFile,
            };
            Navigator.of(context).pop(result); // Devolver el nombre del producto ingresado y la imagen capturada
          },
          child: const Text('Agregar'),
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

Future<void> createInvitation(String receiverId, String storeName, String type, String senderEmail) async {
  try {
    // Obtener el usuario actualmente autenticado
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User is not logged in');
    }

    // Generar una nueva ID para la invitación
    String invitationId = FirebaseFirestore.instance.collection('requests').doc().id;

    // Crear un mapa con los datos de la invitación
    Map<String, dynamic> invitationData = {
      'sender': currentUser.uid, // ID del remitente
      'receiver': receiverId, // ID del receptor
      'storeName': storeName,
      'type': type,
      'senderEmail': senderEmail,
    };

    // Guardar la invitación en Firestore
    await FirebaseFirestore.instance.collection('requests').doc(invitationId).set(invitationData);

    print('Invitation created successfully.');
  } catch (error) {
    print('Error creating invitation: $error');
    throw Exception('Error creating invitation: $error');
  }
}