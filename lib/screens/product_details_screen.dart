import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils.dart';
class ProductDetailsScreen extends StatelessWidget {
  final String storeId;
  final String productId;

  const ProductDetailsScreen({Key? key, required this.storeId, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productRef = FirebaseFirestore.instance.collection('stores/$storeId/products').doc(productId);

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

          final productName = productData['name'] ?? '';
          final productQuantity = productData['quantity'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Name: $productName',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Product Quantity: $productQuantity',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        addProduct(storeId, productId);
                      },
                      child: Text('+'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        deleteProduct(storeId, productId);
                      },
                      child: Text('-'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
