import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'log_in_form.dart';
import 'sign_up_form.dart';
import 'notifications_screen.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onLogin;

  const AccountScreen({Key? key, this.onLogout, this.onLogin}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<User?>(
          future: Future<User?>.value(FirebaseAuth.instance.currentUser),
          builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
            return FadeTransition(
              opacity: _animation,
              child: _buildUserInfo(context, snapshot.data),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAccountInfo('Email', user?.email ?? 'You are not logged in.'),
        const SizedBox(height: 20),
        _buildButton(
          text: user != null ? 'Log Out' : 'Log In',
          onPressed: () async {
            if (user != null) {
              await FirebaseAuth.instance.signOut();
              _controller.reset();
              _controller.forward();
              widget.onLogout?.call();
            } else {
              _navigateToForm(context, const LogInForm());
            }
          },
        ),
        const SizedBox(height: 10),
        if (user == null)
          _buildButton(
            text: 'Sign Up',
            onPressed: () => _navigateToForm(context, const RegisterForm()),
          ),
        const SizedBox(height: 10),
        _buildButton(
          text: 'Notifications',
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()));
          },
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed, Color? color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ), backgroundColor: color ?? Colors.purple[300], // Usa Colors.purple[300] si no se proporciona un color
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white, // El texto del botón siempre es blanco para contrastar con el color del botón
        ),
      ),
    );
  }

  Widget _buildAccountInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800], // Usa Colors.red[300] para el fondo del contenedor
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, color: Colors.white), // El texto de la etiqueta es blanco para contrastar con el fondo rojo
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), // El texto del valor es blanco para contrastar con el fondo rojo
          ),
        ],
      ),
    );
  }

  void _navigateToForm(BuildContext context, Widget form) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => form))
        .then((_) {
      _controller.reset();
      _controller.forward();
      widget.onLogin?.call();
    });
  }
}