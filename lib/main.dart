// C:\Users\smmg\AppData\Local\Pub\Cache\bin
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/group_screen.dart'; 
import 'screens/account_screen.dart';
import 'firebase_options.dart';
import 'screens/barcode_scanner_view_screen.dart';
import 'product_utils.dart';
import 'dart:async'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set system UI mode and overlay style
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Set status bar color to transparent
    statusBarIconBrightness: Brightness.dark, // Make status bar icons dark
    systemNavigationBarColor: Colors.white, // Set system navigation bar color to white
    systemNavigationBarIconBrightness: Brightness.light, // Make system navigation bar icons light (grey)
  ));
  
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  int _notificationCount = 0;
  final PageController _pageController = PageController(initialPage: 0);
  bool _isPageChanging = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
    _tabController.addListener(_handleTabSelection);
    _fetchNotificationCount();
  }

  void _handleTabSelection() {
    if (!_isPageChanging) {
      _isPageChanging = true;
      _currentIndex = _tabController.index;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      ).then((_) => _isPageChanging = false);
    }
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
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0), // Set the preferred height for the TabBar
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.purple[200],
            onTap: (index) {
              if (!_isPageChanging) {
                _isPageChanging = true;
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.ease,
                ).then((_) => _isPageChanging = false);
              }
            },
            tabs: [
              const Tab(icon: Icon(Icons.barcode_reader)),
              const Tab(icon: Icon(Icons.group)),
              Tab(
                icon: Stack(
                  clipBehavior: Clip.none, // Añade esta línea
                  children: [
                    const Icon(Icons.account_circle),
                    if (_notificationCount > 0)
                      Positioned(
                        right: -4,
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          if (!_isPageChanging) {
            _isPageChanging = true;
            _tabController.animateTo(index);
            setState(() {
              _currentIndex = index;
            });
            _fetchNotificationCount().then((_) => _isPageChanging = false);
          }
        },
        children: [
          const BarcodeScannerViewScreen(),
          const GroupScreen(),
          AccountScreen(
            onLogout: _fetchNotificationCount,
            onLogin: _fetchNotificationCount,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
