import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'vision_detector_views/barcode_scanner_view.dart';
import 'screens/log_in_form.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
                    onPressed: FirebaseAuth.instance.currentUser != null 
                      ? () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Home()), // replace MainScreen with your main screen widget
                          );;
                        } 
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LogInForm()),
                          );
                        },
                    child: Text(FirebaseAuth.instance.currentUser != null ? 'Log Out' : 'Log In'),
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
      ),
    );
  }
}
