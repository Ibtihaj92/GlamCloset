import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SendOtp.dart';
import 'user_register.dart';
import 'ForgotPasswor.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final RegExp _emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*");

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a valid password';
    }
    return null;
  }

  Future<void> _sendOTP(String userEmail, String otpCode) async {
    const serviceId = 'service_own0afb';
    const templateId = 'template_yj1cssd';
    const publicKey = 'ybXdQIW0yCMOnc88u';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'user_email': userEmail,
          'otp': otpCode,
        }
      }),
    );

    if (response.statusCode == 200) {
      print('✅ OTP email sent!');
    } else {
      print('❌ Failed to send OTP. ${response.body}');
      throw Exception('Failed to send OTP');
    }
  }

  String generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  Future<void> handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      // Ensure email and password are not empty
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter email and password.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        final uid = userCredential.user!.uid;

        final dbRef = FirebaseDatabase.instance.ref();
        final userSnapshot = await dbRef.child('users/$uid').get();
        final adminSnapshot = await dbRef.child('admin').get();

        String? userType;

        if (userSnapshot.exists) {
          userType = userSnapshot.child('userType').value.toString();
        } else if (adminSnapshot.exists) {
          for (final child in adminSnapshot.children) {
            final adminEmail = child.child('email').value.toString();
            if (adminEmail == email) {
              userType = 'admin';
              break;
            }
          }
        }

        if (userType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User data not found in the database.')),
          );
          return;
        }

        final otp = generateOTP();
        await _sendOTP(email, otp);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPPage(
              email: email,
              expectedOTP: otp,
              userType: userType!,
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter the correct email and password')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${e.message}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset('images/logo.png', height: 210),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Login to GlamCloset!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: emailController,
                  validator: validateEmail,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  validator: validatePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3.0)
                        : const Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserRegister()),
                      ),
                      child: const Text("Sign Up",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
