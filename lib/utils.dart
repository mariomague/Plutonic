import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addProduct(String storeId, String productId, {String? productName}) async {
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
    }
    await productRef.set(dataToAdd);
  }
}
Future<void> deleteProduct(String storeId, String productId) async {
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