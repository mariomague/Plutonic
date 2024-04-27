// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../product_utils.dart';

class AddStore extends StatefulWidget {
  const AddStore({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AddStoreState createState() => _AddStoreState();
}

class _AddStoreState extends State<AddStore> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _imageFile;
  bool _pictureTaken = false;

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addStore() async {
    String storeName = _storeNameController.text.trim();
    String description = _descriptionController.text.trim();

    if (storeName.isEmpty || _imageFile == null || description.isEmpty) {
      _showSnackBar(context, 'Please enter a store name, description, and take a photo');
      return;
    }

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference storeRef = FirebaseFirestore.instance.collection('stores').doc();

      List<int> imageBytes = await _imageFile!.readAsBytes();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(storeRef, {
          'name': storeName,
          'description': description,
          'image': imageBytes,
          'users': [FirebaseFirestore.instance.collection('users').doc(userId)],
        });

        transaction.update(FirebaseFirestore.instance.collection('users').doc(userId), {
          'stores': FieldValue.arrayUnion([storeRef]),
        });

        final productsRef = storeRef.collection('products').doc('placeholder');
        transaction.set(productsRef, {'placeholder': true});
        transaction.delete(productsRef);
      });

      Navigator.pop(context);
    } catch (e) {
      // print('Error adding store: $e');
    }
  }

  Future<void> _takePicture() async {
    final imagePicker = ImagePicker();
    final XFile? imageFile = await imagePicker.pickImage(source: ImageSource.camera);

    if (imageFile != null) {
      final File file = File(imageFile.path);
      File compressedImage = await compressImage(file);
      img.Image? originalImage = img.decodeImage(compressedImage.readAsBytesSync());

      int width = originalImage!.width;
      int height = originalImage.height;
      double aspectRatio = width / height;
      int newWidth = 500;
      int newHeight = (newWidth / aspectRatio).round();

      img.Image resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);
      int startX = (resizedImage.width - 500) ~/ 2;
      int startY = (resizedImage.height - 200) ~/ 2;

      img.Image croppedImage = img.copyCrop(resizedImage, x : startX, y : startY, width:  500, height:  200);
      File croppedFile = File('${file.parent.path}/cropped_image.jpg');
      croppedFile.writeAsBytesSync(img.encodeJpg(croppedImage));

      setState(() {
        _imageFile = XFile(croppedFile.path);
        _pictureTaken = true;
      });
    }
  }

  void _resetPicture() {
    setState(() {
      _imageFile = null;
      _pictureTaken = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Store'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 80), // Add additional padding
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_pictureTaken && _imageFile != null)
                SizedBox(
                  width: 500,
                  height: 200,
                  child: Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 20),
              if (!_pictureTaken)
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Picture'),
                ),
              if (_pictureTaken && _imageFile != null)
                ElevatedButton(
                  onPressed: _resetPicture,
                  child: const Text('Take Another Picture'),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _pictureTaken
          ? FloatingActionButton.extended(
              onPressed: _addStore,
              icon: const Icon(Icons.add),
              label: const Text('Add Store'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      resizeToAvoidBottomInset: true,
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
