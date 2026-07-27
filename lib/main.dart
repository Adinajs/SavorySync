import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'package:firebase_core/firebase_core.dart';
import 'package:savorysync/pages/Home_page.dart';
import 'package:savorysync/pages/login_page.dart';
import 'package:savorysync/pages/profile_page.dart';
import 'package:savorysync/pages/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SavorySyncApp());
}

class SavorySyncApp extends StatelessWidget {
  const SavorySyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(backgroundColor: Colors.orange),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
      ),
      initialRoute: '/', 
      routes: {
        '/': (context) => SplashScreen(), 
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/profile': (context) => ProfilePage(),
        '/register': (context) => RegisterPage(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => HomePage());
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6),
    )..repeat(reverse: true); // Makes the animation repeat back and forth
    _animation = Tween<double>(begin: 0.7, end: 1.2).animate(_controller!);

    Timer(Duration(seconds: 4), () {
      Navigator.pushReplacementNamed(context, '/home'); 
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ScaleTransition(
          scale: _animation!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 100,
                color: Colors.orange,
              ),
              SizedBox(height: 20),
              Text(
                'SavorySync',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Recipe Finder App',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
