import 'dart:convert';
import 'package:chat_app_frontend/config.dart';
import 'package:chat_app_frontend/responsive/responsive.dart';
import 'package:chat_app_frontend/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LogInScreen extends StatefulWidget {
  static String routeName = '/log-in';
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 150),
              Center(
                child: Text(
                  'Log In',
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
                width: 380,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final response = await http.post(
                        Uri.parse('${Config.baseUrl}/api/login'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'username': usernameController.text,
                          'password': passwordController.text,
                        }),
                      );

                      if (response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        final userId = data['user']['id'];
                        final username = data['user']['username'];

                        // Store user info (we'll use simple method for now)
                        print('Logged in as: $username (ID: $userId)');

                        //Success
                        print('Login Successful');
                        // Navigate to login screen or show success message
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(
                              currentUserId: userId,
                              currentUsername: username,
                            ),
                          ),
                        );
                      } else {
                        print('Login Failed');
                      }
                    } catch (e) {
                      print('Error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Network error: $e')),
                      );
                    }
                  },
                  child: Text('Log In'),
                ),
              ),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  const SizedBox(width: 5),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/sign-up');
                    },
                    child: const Text(
                      'Sign Up',
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
        ),
      ),
    );
  }
}
