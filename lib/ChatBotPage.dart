import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'theme_notifier.dart';

const String openAiApiKey = "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";

class FAQItem {
  final List<String> keywords;
  final String answer;
  FAQItem({required this.keywords, required this.answer});
}

final List<FAQItem> chatbotFAQs = [
  FAQItem(keywords: ['rent period','to rent period','rental period', 'rental', 'duration', 'how long', 'days', 'rental days'], answer: 'The rental period is 5 days.'),
  FAQItem(keywords: ['renting', 'rent', 'how to rent', 'hire dress', 'book outfit', 'rent a dress', 'rental process'], answer: 'To rent a dress you can enter as a customer and browse all the available dresses in the app. '
      'You can view each item’s details, check the sizes,availability, and click the image to see it in bigger size before renting.'
      'You can also specify the number of items you want and add them to your cart.'
      'Once you’re ready, you can proceed to the payment page to complete your rental. '),
  FAQItem(keywords: ['extend rental', 'longer rental', 'extra days'], answer: 'We don’t have this kind of feature .'),
  FAQItem(keywords: ['payment', 'pay', 'how can i pay', 'payment method', 'pay option', 'checkout'], answer: 'You can pay easily through the app using the integrated payment gateway. After selecting your outfit, go to the payment page to see the final amount and payment options.'),
  FAQItem(keywords: ['cash on delivery', 'cod', 'pay on delivery'], answer: 'No, cash on delivery is not available.'),
  FAQItem(keywords: ['refund', 'deposit', 'security deposit', 'get my money back'], answer: 'Your security deposit will be refunded automatically after confirming the outfit condition.'),
  FAQItem(keywords: ['verification code', 'otp', 'login code', 'why otp', 'security code'], answer: 'We use a 6-digit OTP for your security. After logging in, we send the code to your email to confirm your identity.'),
  FAQItem(keywords: ['forget my password','forget password','forgot password', 'reset password','to reset password', 'lost password','forgot my password', 'reset my password', 'lost my password'], answer: 'No worries! Tap "Forgot Password", enter your email, we’ll send an OTP. After entering it, you can set a new password.'),
  FAQItem(keywords: ['reset password', 'reset password', 'lost password','forgot my password', 'reset my password', 'lost my password'], answer: 'No worries! You can set a new password from the profile screen . First go to settings and then profile.'),
  FAQItem(keywords: ['small image', 'outfit image', 'picture small', 'image not clear', 'see full image'], answer: 'If you want to see the full image, just tap on the picture and it will open clearly.'),
  FAQItem(keywords: ['order arrive', 'delivery','to delivery', 'when will my order arrive', 'delivery time', 'shipping'], answer: 'It will arrive within 2 to 3 days.'),
  FAQItem(keywords: ['delivery oman', 'all areas', 'delivery coverage', 'shipping area'], answer: 'Yes, we deliver to all areas in Oman.'),
  FAQItem(keywords: ['track order', 'order status'], answer: 'We don’t have this feature in our app for now .'),
  FAQItem(keywords: ['return outfit', 'return clothes', 'return policy', 'return period', 'how to return'], answer: 'It must be returned to the nearest office within 5 days.'),
  FAQItem(keywords: ['outfit arrived', 'received outfit', 'did the outfit arrive'], answer: 'Hello! Did the outfit arrive?\n✅ It arrived in good condition\n❌ There is an issue'),
  FAQItem(keywords: ['yes arrived', 'arrived fine', 'all good'], answer: 'Thank you for confirming!'),
  FAQItem(keywords: ['issue', 'problem', 'damage', 'not okay', 'complaint'], answer: 'Sorry! What type of issue?\n• Tear\n• Stain\n• Other'),
  FAQItem(keywords: ['tear', 'rip', 'hole'], answer: "The issue has been recorded as 'Tear'. Admin will be notified."),
  FAQItem(keywords: ['stain', 'dirty', 'spot', 'mark'], answer: "The issue has been recorded as 'Stain'. Admin will be notified."),
  FAQItem(keywords: ['other', 'other problem', 'something else'], answer: 'The issue has been recorded. Admin will be notified.'),
  FAQItem(keywords: ['outfit returned good', 'returned fine'], answer: 'Confirmed. Your deposit will be refunded in your Wallet.'),
  FAQItem(keywords: ['outfit returned bad', 'returned damaged', 'not good'], answer: 'Please select the type of issue: Tear / Stain / Other'),
  FAQItem(keywords: ['account', 'profile', 'update info', 'edit profile'], answer: 'You can update your account information from the Profile page in the app.'),
  FAQItem(keywords: ['change email', 'update email'], answer: 'You can update your email from the Profile settings.'),
  FAQItem(keywords: ['change password', 'update password'], answer: 'You can change your password from the Profile settings if you are logged in.'),
  FAQItem(keywords: ['promot', 'discount', 'offer', 'coupon'], answer: 'Any current promotions will be displayed on the Home page. Keep an eye on it!'),
  FAQItem(keywords: ['support', 'help', 'contact', 'customer service'], answer: 'You can contact our support team via the app chat or email at support@glamcloset.com'),
  FAQItem(keywords: ['earnings this month', 'monthly profit', 'monthly earnings'], answer: 'You generate renter reports from renter dashboard.'),
  FAQItem(keywords: ['download revenue report', 'revenue report', 'download earnings', 'financial report'], answer: 'You can generate all details from renter dashboard. Also, you can download it as PDF.'),
  FAQItem(keywords: ['app issue', 'bug', 'error', 'problem in app'], answer: 'Sorry for the inconvenience! We are aware of the issue and working to fix it.'),
  FAQItem(keywords: ['terms','terms and condition','see terms and condition','terms and conditions','conditions','condition',  'policy', 'rules','rules of','rule of', 'guidelines','see guidelines'],answer: 'The total rental includes the price plus a 5 OMR security deposit. Items must be returned within 5 days; late returns incur extra fees. The deposit is refunded if the item is returned in good condition.'),
  FAQItem(keywords: ['register','to register','how to register', 'signup','Signup', 'sign up','Sign up','how to sign up','how to signup', 'create account','create new account', 'registration', 'new account', 'join', 'signing up', 'register now', 'create new account', 'account creation', 'how to register']
      ,answer: 'To register, please open the app and follow the sign-up process. You can create an account using your email or phone number.'
  ),

];

class ChatMessage {
  final String text;
  final bool isUser;
  final bool hasButtons;
  final List<String> buttons;
  final void Function(String)? onButtonPressed;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.hasButtons = false,
    this.buttons = const [],
    this.onButtonPressed,
  });
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});
  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(text: '👋 Hello! How can I help you today?', isUser: false)
  ];
  bool _isTyping = false;

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      // Add the user message to the chat
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _messageController.clear();
      _isTyping = true;
    });

    final botReply = await _getBotResponse(text.toLowerCase());

    // Check if the message contains Yes/No options (✅ / ❌)
    if (botReply.contains('\n✅') && botReply.contains('\n❌')) {
      // Yes/No question
      final parts = botReply.split('\n');
      String questionText = parts[0];
      String yesText = parts.firstWhere((p) => p.startsWith('✅')).replaceFirst('✅', '').trim();
      String noText = parts.firstWhere((p) => p.startsWith('❌')).replaceFirst('❌', '').trim();

      setState(() {
        _isTyping = false;
        _messages.insert(
          0,
          ChatMessage(
            text: questionText,
            isUser: false,
            hasButtons: true,
            buttons: ['Yes', 'No'],
            onButtonPressed: (button) {
              String reply = button == 'Yes' ? yesText : noText;
              setState(() {
                _messages.insert(0, ChatMessage(text: reply, isUser: false));
              });
            },
          ),
        );
      });
    } else if (botReply.contains('•')) {
      // Question with multiple options
      final parts = botReply.split('\n');
      String questionText = parts[0];
      List<String> options = parts.sublist(1).map((p) => p.replaceAll(RegExp(r'^[•]?\s*'), '').trim()).toList();

      setState(() {
        _isTyping = false;
        _messages.insert(
          0,
          ChatMessage(
            text: questionText,
            isUser: false,
            hasButtons: true,
            buttons: options,
            onButtonPressed: (button) {
              String reply = "The issue has been recorded: $button. Admin will be notified.";
              setState(() {
                _messages.insert(0, ChatMessage(text: reply, isUser: false));
              });
              // Here you can add code to send the details to the admin in the database
            },
          ),
        );
      });
    } else {
      // Default response
      setState(() {
        _isTyping = false;
        _messages.insert(0, ChatMessage(text: botReply, isUser: false));
      });
    }
  }



  Future<String> _getBotResponse(String userMessage) async {
    for (var faq in chatbotFAQs) {
      for (var keyword in faq.keywords) {
        if (userMessage.contains(keyword.toLowerCase())) {
          return faq.answer;
        }
      }
    }

    try {
      final prompt = """
You are a chatbot for the GlamCloset project only. Answer **only in English**. 
Answer only questions related to GlamCloset. 
If the question is outside GlamCloset, reply: "I can only answer questions about GlamCloset."

User question: "$userMessage"
""";

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $openAiApiKey",
        },
        body: jsonEncode({
          "model": "text-davinci-003",
          "prompt": prompt,
          "max_tokens": 150,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['text'].toString().trim();
      } else {
        return "I can only answer questions about GlamCloset.";
      }
    } catch (e) {
      return "I can only answer questions about GlamCloset.";
    }
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
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor), onPressed: () => themeNotifier.toggleTheme()),
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
                if (_isTyping && index == 0) return _buildTypingIndicator();
                final message = _messages[_isTyping ? index - 1 : index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: _buildMessageBubble(message, isDark),
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
    bool isIssueMessage = message.text.contains('•'); // Detect message with bullet points

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // More padding
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
      decoration: BoxDecoration(
        gradient: message.isUser
            ? const LinearGradient(colors: [Colors.deepPurple, Colors.pinkAccent], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: message.isUser ? null : (isDark ? Colors.grey[850] : Colors.white),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main message text
          Text(
            message.text,
            style: TextStyle(
              color: message.isUser
                  ? Colors.white
                  : (isIssueMessage ? Colors.white : (isDark ? Colors.white : Colors.black87)), // White for bullet message
              fontSize: 16,
              height: 1.5, // More line spacing
            ),
          ),
          if (message.hasButtons)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: message.buttons.map((btn) {
                  return ElevatedButton(
                    onPressed: () {
                      if (message.onButtonPressed != null) message.onButtonPressed!(btn);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white, // button text color white
                    ),
                    child: Text(btn),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
          SizedBox(width: 4),
          SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle))),
          SizedBox(width: 4),
          SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle))),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))]),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(radius: 25, backgroundColor: Colors.deepPurple, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => _sendMessage(_messageController.text))),
          ],
        ),
      ),
    );
  }
}
