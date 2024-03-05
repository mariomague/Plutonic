import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
class LogInForm extends StatefulWidget {
  @override
  _LogInFormState createState() => _LogInFormState();
}

class _LogInFormState extends State<LogInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _logIn() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()), // replace MainScreen with your main screen widget
        );;
        // Navigator.pop(context);
      } catch (e) {
        String message;
        if (e is FirebaseAuthException && e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e is FirebaseAuthException && e.code == 'wrong-password') {
          message = 'Wrong password provided for that user.';
        } else {
          message = 'Something went wrong. Please try again later.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log In'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              // Add validation logic here...
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              // Add validation logic here...
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _logIn,
              child: Text(_isLoading ? 'Loading...' : 'Log In'),
            ),
          ],
        ),
      ),
    );
  }
}

// mariomague123@gmail.com