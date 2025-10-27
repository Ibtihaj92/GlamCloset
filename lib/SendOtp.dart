import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'AdminDashboardPage.dart';
import 'HomePage.dart';

class OTPPage extends StatefulWidget {
  final String email;
  final String userType; // 'admin' or 'user'
  final String? expectedOTP;

  OTPPage({
    required this.email,
    required this.userType,
    this.expectedOTP,
  });

  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  String otpCode = '';
  String userInput = '';
  bool isSending = false;
  bool isVerifying = false;
  DateTime otpExpiryTime = DateTime.now();
  Timer? resendTimer;
  int resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    otpCode = widget.expectedOTP ?? generateOTP();
    otpExpiryTime = DateTime.now().add(Duration(minutes: 5));

    if (widget.expectedOTP == null) {
      sendAndHandleOTP();
    }
  }

  String generateOTP() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString(); // 6-digit OTP
  }

  Future<void> sendAndHandleOTP() async {
    setState(() => isSending = true);
    bool sent = await sendOTPEmail(otpCode, widget.email);
    setState(() => isSending = false);
    if (sent) startResendCooldown();
  }

  Future<bool> sendOTPEmail(String otpCode, String userEmail) async {
    final serviceId = 'service_own0afb';
    final templateId = 'template_yj1cssd';
    final userId = 'ybXdQIW0yCMOnc88u';
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {'user_email': userEmail, 'otp': otpCode},
        }),
      );

      print('EmailJS status: ${response.statusCode}');
      print('EmailJS body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to $userEmail')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP. Check your EmailJS')),
        );
        return false;
      }
    } catch (e) {
      print('Error sending OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e')),
      );
      return false;
    }
  }

  void startResendCooldown() {
    setState(() => resendSeconds = 30);
    resendTimer?.cancel();
    resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (resendSeconds > 0) {
          resendSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void verifyOTP() {
    setState(() => isVerifying = true);
    Future.delayed(Duration(seconds: 1), () {
      setState(() => isVerifying = false);

      if (DateTime.now().isAfter(otpExpiryTime)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('OTP expired')));
        return;
      }

      if (userInput.trim() == otpCode.trim()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => widget.userType == 'admin'
                  ? AdminDashboardPage()
                  : HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Incorrect OTP')));
      }
    });
  }

  void resendOTP() {
    if (resendSeconds > 0) return; // prevent spamming
    otpCode = generateOTP();
    otpExpiryTime = DateTime.now().add(Duration(minutes: 5));
    sendAndHandleOTP();
  }

  @override
  void dispose() {
    resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Image.asset('images/Verification.png', height: 210),
              SizedBox(height: 20),
              Text("Enter OTP",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                "Code sent to ${widget.email}",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.grey),
              ),
              SizedBox(height: 30),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 10),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  border: UnderlineInputBorder(),
                ),
                onChanged: (value) {
                  final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                  setState(() => userInput = digitsOnly);
                },
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                  userInput.length == 6 && !isVerifying ? verifyOTP : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isVerifying
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Verify", style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed:
                (isSending || resendSeconds > 0) ? null : resendOTP,
                child: isSending
                    ? CircularProgressIndicator()
                    : Text(
                  resendSeconds > 0
                      ? 'Resend OTP in $resendSeconds s'
                      : 'Resend OTP',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
