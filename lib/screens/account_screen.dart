import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'log_in_form.dart';
import 'sign_up_form.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const AccountScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // ignore: unused_field
  User? _user;

  @override
  void initState() {
    super.initState();
    _updateUserInfo();
  }

  Future<void> _updateUserInfo() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      _user = currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: Future<User?>.value(FirebaseAuth.instance.currentUser),
          builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else {
              final user = snapshot.data;
              return _buildUserInfo(context, user);
            }
          },
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, User? user) {
    return Column(
      children: [
        _buildAccountInfo('Email', user?.email ?? 'You are not logged in.'),
        SizedBox(height: 20),
        Visibility(
          // Show Log Out button when user is logged in
          visible: user != null,
          child: ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              _updateUserInfo();
              widget.onLogout?.call(); // Llama a la función proporcionada por el padre para actualizar la página
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
              textStyle: TextStyle(fontSize: 18),
            ),
            child: Text('Log Out'),
          ),
        ),
        // Show Log In and Sign Up buttons when user is not logged in
        Visibility(
          visible: user == null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterForm()),
                  ).then((_) => _updateUserInfo());
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  textStyle: TextStyle(fontSize: 18),
                  backgroundColor: const Color.fromARGB(255, 191, 226, 255),
                ),
                child: Text('Sign Up'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LogInForm()),
                  ).then((_) => _updateUserInfo());
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Log In'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfo(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 18),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
