import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
      ),
      body: Center(
        child: Text(
          'This is the Product List Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}