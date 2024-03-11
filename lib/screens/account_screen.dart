import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'log_in_form.dart';
import 'sign_up_form.dart';
import 'notifications_screen.dart'; // Importar la pantalla de notificaciones

class AccountScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onLogin;

  const AccountScreen({Key? key, this.onLogout, this.onLogin}) : super(key: key);

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
          visible: user != null,
          child: ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              _updateUserInfo();
              widget.onLogout?.call();
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
                  ).then((_) {
                    _updateUserInfo();
                    widget.onLogin?.call();
                  });
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
                  ).then((_) {
                    _updateUserInfo();
                    widget.onLogin?.call();
                  });
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
        SizedBox(height: 20), // Add space between buttons and the new notifications button
        Visibility(
          visible: user != null, // Show the notifications button only if the user is logged in
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
              textStyle: TextStyle(fontSize: 18),
              backgroundColor: Colors.blue,
            ),
            child: Text('Notifications'),
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
