import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/product_list_screen.dart'; 
import 'screens/group_screen.dart'; 
import 'screens/account_screen.dart';
import 'firebase_options.dart';
import 'screens/barcode_scanner_view_screen.dart';

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
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plutonic'),
        centerTitle: true,
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        children: [
          BarcodeScannerViewScreen(),
          ProductListScreen(),
          GroupScreen(),
          AccountScreen(
            onLogout: () {
              // Esta función se llamará cuando se cierre la sesión en AccountScreen
              setState(() {}); // Actualiza el estado para reconstruir la pantalla
            },
          ),
        ],
        onPageChanged: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.barcode_scanner,color: Colors.black),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt,color: Colors.black),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group,color: Colors.black),
            label: 'Group',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle,color: Colors.black),
            label: 'Account',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(index, duration: Duration(milliseconds: 500), curve: Curves.ease);
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

