import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(SavorySyncApp());
}

class SavorySyncApp extends StatelessWidget {
  const SavorySyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _error = '';
  bool _isPasswordVisible = false; // Toggle for password visibility
  bool _isConfirmPasswordVisible = false; // Toggle for confirm password visibility

  void _register() async {
  if (_passwordController.text != _confirmPasswordController.text) {
    setState(() {
      _error = "Passwords do not match!";
    });
    return;
  }

  try {
    // Check if username already exists
    final usernameDoc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(_usernameController.text.trim())
        .get();

    if (usernameDoc.exists) {
      setState(() {
        _error = "Username already taken!";
      });
      return;
    }

    final navigator = Navigator.of(context);
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final user = userCredential.user;
    if (user != null) {
   
      await user.updateDisplayName(_usernameController.text.trim());
      await user.reload();
      User? updatedUser = FirebaseAuth.instance.currentUser; 

      // Save username to Firestore for login via username
      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(_usernameController.text.trim())
          .set({
        'uid': updatedUser?.uid,
        'email': updatedUser?.email,
      });

      // Navigate to login page
      navigator.pushReplacementNamed('/login');
    }
  } catch (e) {
    setState(() {
      _error = 'Registration failed: ${e.toString()}';
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, color: Colors.orange, size: 80.0),
                SizedBox(height: 20.0),
                Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30.0),

                // Username field
                TextField(
                  controller: _usernameController,
                  style: TextStyle(color: Colors.white), 
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black12, 
                    hintText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),

                // Email field
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: Colors.white), 
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black12,
                    hintText: 'Email Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),

                // Password field with visibility toggle
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black12, 
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20.0),

                // Confirm Password field with visibility toggle
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: TextStyle(color: Colors.white), 
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black12, 
                    hintText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10),

                if (_error.isNotEmpty)
                  Text(_error, style: TextStyle(color: Colors.red)),

                SizedBox(height: 30.0),
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                  ),
                  child: Text('Create Account'),
                ),
                SizedBox(height: 20.0),

                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
                SizedBox(height: 10.0),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/'),
                  child: Text(
                    'Back to Home',
                    style: TextStyle(color: Colors.orange),
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
