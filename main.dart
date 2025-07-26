import 'package:esportapp/authenticate/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
 // your main screen or wrappes

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async operations in main
  await Firebase.initializeApp(); // ✅ Initialize Firebase here
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eSport App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignIn(), // Your app's entry screen
    );
  }
}
