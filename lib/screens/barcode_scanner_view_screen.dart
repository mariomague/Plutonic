import '../vision_detector_views/barcode_scanner_view.dart';
import 'package:flutter/material.dart';

class BarcodeScannerViewScreen extends StatefulWidget {
  @override
  _BarcodeScannerViewScreenState createState() => _BarcodeScannerViewScreenState();
}

class _BarcodeScannerViewScreenState extends State<BarcodeScannerViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview (placeholder for BarcodeScannerView)
          Container(
            // color: Colors.black, // Simulate camera preview
            width: double.infinity,
            height: double.infinity,
          ),
          // Action buttons
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BarcodeScannerView(isAddingProduct: true),
                      ),
                    );
                    },
                  icon: Icon(Icons.add, color: Colors.green),
                  label: Text("Add Product"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BarcodeScannerView(isAddingProduct: false),
                      ),
                    );
                  },
                  icon: Icon(Icons.remove, color: Colors.red),
                  label: Text("Remove Product"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
