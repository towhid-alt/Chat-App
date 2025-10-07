import 'package:chat_app_frontend/screens/log_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  static String routeName = '/sign-up';

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text("Sign Up")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 150),
          Center(
            child: Text(
              'Sign Up',
              style: TextStyle(fontSize: 90, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 50),
          SizedBox(
            width: 390,
            child: TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
              ),
            ),
          ),

          const SizedBox(height: 50),
          SizedBox(
            width: 390,
            child: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your Password',
              ),
            ),
          ),

          const SizedBox(height: 50),
          SizedBox(
            width: 390,
            child: TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your Password',
              ),
            ),
          ),

          const SizedBox(height: 50),
          SizedBox(
            width: 380,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.post(
                    Uri.parse('http://localhost:8383/api/signup'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'username': usernameController.text,
                      'password': passwordController.text,
                    }),
                  );

                  if (response.statusCode == 201) {
                    // Success
                    print('Signup successful!');
                    // Navigate to login screen or show success message
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogInScreen()),
                    );
                  } else {
                    // Error
                    final errorData = jsonDecode(response.body);
                    print('Signup failed: ${errorData['error']}');
                  }
                  ;
                } catch (e) {
                  print('Error: $e');
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Network error: $e')));
                }
                ;

                child:
                Text('Sign Up');
              },
              child: null,
            ),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account?'),
              const SizedBox(width: 5),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/log-in');
                },
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    color: Colors.blue, // Customize color
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
