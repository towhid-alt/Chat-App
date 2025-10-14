import 'dart:convert';

import 'package:chat_app_frontend/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUsername;
  static String routeName = '/home-screen';
  const HomeScreen({
    super.key,
    required this.currentUserId,
    required this.currentUsername,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8383/api/users'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = data['users']; //The list of students from the office
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // We'll implement logout later
              Navigator.pushReplacementNamed(context, '/log-in');
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUsers,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user['username'][0].toUpperCase()),
                    ),
                    title: Text(user['username']),
                    subtitle: Text('Tap to start chatting'),
                    trailing: Icon(Icons.chat),
                    //Important OnTap logic here
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            currentUserId: widget.currentUserId,
                            currentUsername: widget.currentUsername,
                            otherUserId: user['id'].toString(),
                            otherUsername: user['username'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
