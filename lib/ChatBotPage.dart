import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    const ChatMessage(
      text: '👋 Hello! How can I help you today?',
      isUser: false,
    ),
    const ChatMessage(
      text: 'How do I list my clothing for rent?',
      isUser: false,
      isOption: true,
    ),
    const ChatMessage(
      text: 'How do I rent an outfit?',
      isUser: false,
      isOption: true,
    ),
  ];
  bool _isTyping = false;

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _messageController.clear();
      _isTyping = true;
    });

    // Simulated bot response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isTyping = false;
        _messages.insert(
          0,
          ChatMessage(
            text:
            'Thanks for asking: "$text". Our support team will get back to you soon 💬',
            isUser: false,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text("GlamCloset Bot", style: TextStyle(color: textColor)),
          ],
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == 0) {
                  return _buildTypingIndicator();
                }
                final message = _messages[_isTyping ? index - 1 : index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: message.isOption
                      ? _buildOptionButton(message.text, textColor)
                      : _buildMessageBubble(message, isDark),
                );
              },
            ),
          ),
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        gradient: message.isUser
            ? const LinearGradient(
          colors: [Colors.deepPurple, Colors.pinkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: message.isUser
            ? null
            : (isDark ? Colors.grey[800] : Colors.white),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: message.isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildOptionButton(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () => _sendMessage(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Colors.black, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: 4),
          SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Colors.black, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: 4),
          SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Colors.black, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.deepPurple,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isOption;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isOption = false,
  });
}
