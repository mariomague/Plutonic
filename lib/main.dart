import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/group_screen.dart'; 
import 'screens/account_screen.dart';
import 'firebase_options.dart';
import 'screens/barcode_scanner_view_screen.dart';
import 'product_utils.dart';

void main() async {
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
  int _notificationCount = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
  }

  Future<void> _fetchNotificationCount() async {
    final count = await fetchNotificationCount();
    setState(() {
      _notificationCount = count;
    });
  }

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
          GroupScreen(),
          AccountScreen(
            onLogout: () {
              _fetchNotificationCount();
              setState(() {});
            },
            onLogin: () {
              _fetchNotificationCount();
              setState(() {});
            },
          ),
        ],
        onPageChanged: (int index) {
          setState(() {
            _currentIndex = index;
          });
          _fetchNotificationCount();
        },
      ),
      bottomNavigationBar: Stack(
        children: [
          BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: Colors.black,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.barcode_scanner, color: Colors.black),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group, color: Colors.black),
                label: 'Group',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle, color: Colors.black),
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
          // ignore: unnecessary_null_comparison
          if (_notificationCount != null && _notificationCount > 0)
            Positioned(
              right: 45,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_notificationCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
