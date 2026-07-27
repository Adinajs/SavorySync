import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';
  bool _isPasswordVisible = false;

  void _login() async {
    try {
      final navigator = Navigator.of(context);
      String loginInput = _emailController.text.trim();
      String password = _passwordController.text.trim();

      String emailToLogin;

      // If the input contains '@', it's an email, otherwise it's assumed to be a username.
      if (loginInput.contains('@')) {
        emailToLogin = loginInput;
      } else {
        // If it's a username, query Firestore to get the associated email using the username as the document ID.
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('usernames')
              .doc(loginInput.toLowerCase()) // Use lowercase username to avoid case sensitivity issues
              .get();

          if (!userDoc.exists) {
            setState(() {
              _error = 'No account found for username: $loginInput';
            });
            return;
          }

          // Successfully retrieved the document, now extract the email
          emailToLogin = userDoc['email'];
        } catch (e) {
          setState(() {
            _error = 'Error retrieving username: $e';
          });
          return;
        }
      }

      // Use Firebase Authentication to sign in using the email
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToLogin,
        password: password,
      );

      if (userCredential.user != null) {
        // Successfully logged in
        navigator.pushReplacementNamed('/profile'); // Replace with your desired route
      }
    } catch (e) {
      setState(() {
        _error = 'Login failed: ${e.toString()}';
      });
    }
  }

void _forgotPassword() {
  if (_emailController.text.trim().isNotEmpty) {
    FirebaseAuth.instance
        .sendPasswordResetEmail(email: _emailController.text.trim())
        .then((value) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password reset email sent!'))))
        .catchError((error) {
      setState(() => _error = error.toString());
      return ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reset email: $error')));
    });
  } else {
    setState(() => _error = "Please enter your email to reset password.");
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email to reset password.')));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Colors.orange,
                  size: 80.0,
                ),
                SizedBox(height: 20.0),
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.0),
                Text(
                  'Sign in to your SavorySync account',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.0,
                  ),
                ),
                SizedBox(height: 30.0),
                TextField(
                  controller: _emailController, 
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black12,
                    hintText: 'Username or Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black12,
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 10.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _forgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Colors.orange,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _error,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding:
                        EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                  ),
                  child: Text('Sign In'),
                ),
                SizedBox(height: 20.0),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    "Don't have an account? Create account",
                    style: TextStyle(
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
