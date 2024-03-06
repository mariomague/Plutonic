import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback? onRegister;

  const RegisterForm({Key? key, this.onRegister}) : super(key: key);

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register(BuildContext context) async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match')));
        return;
      }

      setState(() {
        _isLoading = true;
      });
      
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        
        // Obtener el ID del usuario
        String userId = userCredential.user!.uid;
        
        // Guardar información adicional del usuario en Firestore
        await saveUserInfoToDatabase(userId, _emailController.text);
        
        widget.onRegister?.call(); // Llama a la función proporcionada por el padre para actualizar la página
        Navigator.popUntil(context, ModalRoute.withName('/')); // Cierra la pantalla de registro después de registrarse correctamente y regresa al inicio
      } catch (e) {
        String message;
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
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

  // Función para guardar información del usuario en Firestore
  Future<void> saveUserInfoToDatabase(String userId, String email) async {
    try {
      // Referencia a la colección de usuarios
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
      
      // Guardar información del usuario en Firestore
      await usersCollection.doc(userId).set({
        'email': email,
        'stores': [], // Array vacío para almacenar los IDs de los almacenes asociados
      });
      
      print('Información del usuario guardada en Firestore');
    } catch (e) {
      print('Error al guardar información del usuario en Firestore: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _register(context),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text('Register'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

