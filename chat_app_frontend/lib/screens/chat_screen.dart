import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUsername;
  static String routeName = '/chat-screen';
  final String otherUserId;
  final String otherUsername;
  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUsername,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  IO.Socket? socket; // ← Declare the socket variable

  @override
  void dispose() {
    socket?.disconnect();
    socket?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initSocket(); // ← This will create the actual connection
    fetchChatHistory();
  }

  void initSocket() {
    socket = IO.io('http://localhost:8383', <String, dynamic>{
      // ← Now socket has a real connection
      'transports': ['websocket'],
    });

    // Add connection logging
    socket!.on('connect', (_) {
      print('✅ Socket connected: ${socket!.id}');
    });

    socket!.on('error', (error) {
      print('❌ Socket error: $error');
    });

    socket!.connect();

    // Join user's personal room
    socket!.emit('join_chat', widget.currentUserId.toString());

    // Listen for new messages
    socket!.on('receive_message', (data) {
      print('📨 Received message via socket: $data');
      setState(() {
        messages.add(data);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> fetchChatHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8383/api/messages/${widget.currentUserId}/${widget.otherUserId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = data['messages']; //Here messages are stored into the list
          //variable, fetching from the server
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error fetching chat history: $e');
    }
  }

  Future<void> sendMessage() async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty) return;

    // Send via socket instead of HTTP
    socket!.emit('send_message', {
      'senderId': widget.currentUserId,
      'receiverId': int.parse(widget.otherUserId),
      'message': messageText,
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUsername)),
      body: Column(
        children: [
          // Message list will go here
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                final isMe =
                    message['sender_id'] == widget.currentUserId; //Main Issue

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['message'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
