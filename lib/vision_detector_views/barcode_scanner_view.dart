import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'detector_view.dart';
import '../product_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeScannerView extends StatefulWidget {
  final bool isAddingProduct;

  BarcodeScannerView({required this.isAddingProduct});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;

  @override
  void dispose() {
    _canProcess = false;
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetectorView(
      title: 'Barcode Scanner',
      customPaint: _customPaint,
      text: _text,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;

    setState(() {
      _text = '';
    });

    _isBusy = true;

    final barcodes = await _barcodeScanner.processImage(inputImage);

    if (barcodes.isNotEmpty) {
      _canProcess = false;
      final prefs = await SharedPreferences.getInstance();
      var storeId = prefs.getString('currentStore');
      var productId = barcodes.removeAt(0).rawValue;

      // Check if the last scanned productId matches the current one
      var lastScannedProductId = prefs.getString('lastScannedProductId');

      if (lastScannedProductId == productId) {
        await prefs.remove('lastScannedProductId');
        _canProcess = true;
      } else {
        await prefs.setString('lastScannedProductId', productId!);

        if (widget.isAddingProduct) {
          addProduct(context, storeId, productId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully!')),
          );
        } else {
          deleteProduct(storeId, productId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product removed successfully!')),
          );
        }

        Navigator.pop(context);
      }

      barcodes.clear();
    }

    _isBusy = false;

    if (mounted) {
      setState(() {});
    }
  }
}
