import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:chat_app_frontend/config.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initSocket(); // ← This will create the actual connection
    fetchChatHistory();
  }

  void initSocket() {
    socket = IO.io('http://192.168.1.6:8383', <String, dynamic>{
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
      if (!mounted) return; // ✅ Skip if widget is gone
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
          'http://interroad-nontragical-odessa.ngrok-free.dev/api/messages/${widget.currentUserId}/${widget.otherUserId}',
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

  // Add this function to pick image
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        await _sendImage(File(image.path));
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  // Add this function to send image

  Future<void> _sendImage(File imageFile) async {
    try {
      // For mobile platforms
      if (Platform.isAndroid || Platform.isIOS) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${Config.baseUrl}/api/upload-image'),
        );

        request.fields['sender_id'] = widget.currentUserId.toString();
        request.fields['receiver_id'] = widget.otherUserId;

        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );

        var response = await request.send();

        if (response.statusCode == 201) {
          print('✅ Image sent successfully');
        }
      } else {
        // For web platform, use different approach
        print('Web platform detected - need different implementation');
      }
    } catch (e) {
      print('Error sending image: $e');
    }
  }

  @override
  void dispose() {
    socket?.off('receive_message'); // ✅ Stop the socket listener
    socket?.disconnect();
    socket?.close();
    super.dispose();
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
                final isImage = message['type'] == 'image';
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

                    child: isImage
                        ? GestureDetector(
                            onTap: () {
                              // We'll add image preview later
                              print('Image tapped: ${message['message']}');
                            },
                            child: Image.network(
                              message['message'], // This contains the image URL
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey,
                                  child: Icon(Icons.error),
                                );
                              },
                            ),
                          )
                        : Text(
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
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _pickImage,
                  tooltip: 'Send Image',
                ),
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
