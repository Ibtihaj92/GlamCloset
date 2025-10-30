import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'user_login.dart';
import 'database.dart';

class UserRegister extends StatefulWidget {
  final bool isTest;

  const UserRegister({Key? key, this.isTest = false}) : super(key: key);

  @override
  _UserRegisterState createState() => _UserRegisterState();
}

class _UserRegisterState extends State<UserRegister> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController contactNoController = TextEditingController();
  String? selectedCity;
  bool _obscurePassword = true;

  final List<String> cities = [
    'Muscat', 'Dhofar', 'Musandam', 'Al Buraymi', 'Ad Dakhliyah',
    'North Al Batinah', 'South Al Batinah', 'South Ash Sharaqiyah',
    'North Ash Shariqiyah', 'Adh Dhahira', 'Al Wusta'
  ];

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        String email = emailController.text.trim();
        String password = passwordController.text.trim();
        String contactNo = contactNoController.text.trim();
        String city = selectedCity!;

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
            email: email, password: password);

        final uid = userCredential.user!.uid;
        String hashedPassword = hashPassword(password);

        await DatabaseService().saveUserData(
          userId: uid,
          email: email,
          contactNo: contactNo,
          city: city,
          hashedPassword: hashedPassword,
        );

        flutterLocalNotificationsPlugin.show(
          0,
          'Registration Successful',
          'You have successfully registered!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'registration_channel',
              'Registration',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: false,
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = '❌ Failed to register: ${e.message}';
        if (e.code == 'email-already-in-use') {
          errorMessage = '❌ This email is already in use. Please try another.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'images/logo.png',
                    height: 210,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Register to GlamCloset!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                _buildEmailField(),
                const SizedBox(height: 15),
                _buildPasswordField(),
                const SizedBox(height: 15),
                _buildPhoneField(),
                const SizedBox(height: 15),
                _buildCityDropdown(),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "REGISTER",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginPage()),
                        );
                      },
                      child: const Text(
                        "SignIn",
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: "Enter Email",
        hintText: "Enter your email",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter your email";
        if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+").hasMatch(value)) {
          return "Enter a valid email";
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: "Password",
        hintText: "At least 8 chars, 1 capital, 1 special",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        suffixIcon: IconButton(
          icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter password";
        if (value.length < 8) return "Password must be at least 8 characters";
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: contactNoController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: "Phone Number",
        hintText: "Enter 8-digit phone starting with 9 or 7",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      validator: (value) {
        if (value == null || value.isEmpty)
          return "Please enter your phone number";
        if (!RegExp(r'^[97][0-9]{7}$').hasMatch(value))
          return "Phone must start with 9 or 7 and be 8 digits";
        return null;
      },
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCity,
      hint: Text("Select City"),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      onChanged: (value) => setState(() => selectedCity = value),
      items: cities.map((city) {
        return DropdownMenuItem(
          value: city,
          child: Text(city),
        );
      }).toList(),
      validator: (value) => value == null ? "Please select a city" : null,
    );
  }
}
