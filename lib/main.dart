// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'vision_detector_views/barcode_scanner_view.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plutonic'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  CustomCard('Add Product', BarcodeScannerView(isAddingProduct: true)),
                  SizedBox(
                    height: 20,
                  ),
                  CustomCard('Remove Product', BarcodeScannerView(isAddingProduct: false)),
                  SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // await _signInAnonymously();
                    },
                    child: Text('Sign in anonymously'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// Future<void> _signInAnonymously() async {
//   try {
//     await FirebaseAuth.instance.signInAnonymously();
//   } catch (e) {
//     print(e);
//   }
// }
class CustomCard extends StatelessWidget {
  final String _label;
  final Widget _viewPage;
  final bool featureCompleted;

  const CustomCard(this._label, this._viewPage, {this.featureCompleted = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Theme.of(context).primaryColor,
        title: Text(
          _label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          if (!featureCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    const Text('This feature has not been implemented yet')));
          } else {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => _viewPage));
          }
        },
      ),
    );
  }
}
