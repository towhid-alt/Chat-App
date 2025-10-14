import 'package:chat_app_frontend/screens/log_in_screen.dart';
import 'package:chat_app_frontend/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      routes: {
        '/log-in': (context) => LogInScreen(),
        '/sign-up': (context) => SignUpScreen(),
      },
      //Start with SignUpScreen
      initialRoute: SignUpScreen.routeName,
    );
  }
}
