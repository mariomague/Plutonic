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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  int _notificationCount = 0;
  final PageController _pageController = PageController(initialPage: 0);
  bool _isPageChanging = false; // Bandera para indicar si la página está cambiando

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
    _tabController.addListener(_handleTabSelection);
    _fetchNotificationCount();
  }

  void _handleTabSelection() {
    if (!_isPageChanging) {
      setState(() {
        _currentIndex = _tabController.index;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      });
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
        backgroundColor: Colors.transparent, // Hacer el fondo transparente
        elevation: 0, // Eliminar la sombra debajo de la AppBar
        automaticallyImplyLeading: false, // Para ocultar el botón de retroceso
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purple[200], // Hacer el indicador de tab transparente
          tabs: [
            const Tab(icon: Icon(Icons.barcode_scanner)),
            const Tab(icon: Icon(Icons.group)),
            Tab(
              icon: Stack(
                children: [
                  const Icon(Icons.account_circle),
                  if (_notificationCount > 0)
                    Positioned(
                      right: -1,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(0),
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            _currentIndex = index;
            _isPageChanging = true; // Establecer la bandera como verdadera cuando cambia la página
          });
          _tabController.animateTo(index); // Seleccionar el ícono correspondiente al cambiar de página
          _fetchNotificationCount();
        },
        children: [
          BarcodeScannerViewScreen(),
          const GroupScreen(),
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
