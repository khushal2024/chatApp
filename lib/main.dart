
import 'dart:html' as html;
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebSocketPage(),
    );
  }
}

class WebSocketPage extends StatefulWidget {
  @override
  _WebSocketPageState createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  final TextEditingController _numberController = TextEditingController();
  final List<String> _userNumbers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Enter new user number'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addUserNumber,
                  child: Text('Add User Number'),
                ),
                SizedBox(height: 16),
                Text('Select User:'),
                ..._userNumbers.map((number) => ListTile(
                      title: Text('User $number'),
                      onTap: () => _navigateToUserChat(context, number),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addUserNumber() {
    final number = _numberController.text;
    if (number.isNotEmpty && !_userNumbers.contains(number)) {
      setState(() {
        _userNumbers.add(number);
      });
      _numberController.clear();
    }
  }

  void _navigateToUserChat(BuildContext context, String userNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserChatPage(userNumber: userNumber),
      ),
    );
  }
}

class UserChatPage extends StatefulWidget {
  final String userNumber;

  UserChatPage({required this.userNumber});

  @override
  _UserChatPageState createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  late html.WebSocket _webSocket;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messageHistory = [];
  String _status = 'Offline';

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final url = 'ws://localhost:8080/${widget.userNumber}';
    _webSocket = html.WebSocket(url);

    _webSocket.onOpen.listen((_) {
      setState(() {
        _status = 'Online';
      });
      print('WebSocket connection opened to $url');
    });

    _webSocket.onMessage.listen((event) {
      setState(() {
        _messageHistory.add({
          'number': widget.userNumber,
          'message': event.data,
          'isCurrentUser': 'false',
        });
      });
    });

    _webSocket.onClose.listen((event) {
      setState(() {
        _status = 'Offline';
      });
      print('WebSocket closed, attempting to reconnect...');
      _reconnectWebSocket();
    });

    _webSocket.onError.listen((event) {
      print('WebSocket error: $event');
    });
  }

  void _reconnectWebSocket() {
    Future.delayed(Duration(seconds: 5), () {
      if (_webSocket.readyState == html.WebSocket.CLOSED) {
        _connectWebSocket();
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text;
    if (message.isNotEmpty) {
      _webSocket.send(message);
      setState(() {
        _messageHistory.add({
          'number': widget.userNumber,
          'message': message,
          'isCurrentUser': 'true',
        });
      });
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _webSocket.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with User ${widget.userNumber}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Status: $_status',
              style: TextStyle(
                color: _status == 'Online' ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _messageHistory.map((message) {
                          bool isCurrentUser = message['isCurrentUser'] == 'true';
                          return Align(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.blueAccent
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${isCurrentUser ? 'me' : 'you'}: ${message['message']}',
                                style: TextStyle(
                                  color: isCurrentUser ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(16),
                  ),
                  child: Icon(Icons.send, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
