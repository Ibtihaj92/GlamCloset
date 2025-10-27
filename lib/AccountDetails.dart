import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ResetPassword.dart';
import 'user_login.dart';
import 'theme_notifier.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final DatabaseReference userRef =
        FirebaseDatabase.instance.ref().child('users').child(uid);
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map;
          emailController.text = data['email'] ?? '';
          cityController.text = data['city'] ?? '';
          phoneController.text = data['contactNo'] ?? '';
        }
      }
    } catch (e) {
      print('⚠️ Error fetching user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userRef =
        FirebaseDatabase.instance.ref().child('users').child(uid);
        await userRef.update({
          'email': emailController.text.trim(),
          'city': cityController.text.trim(),
          'contactNo': phoneController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Information updated successfully')),
        );
      }
    } catch (e) {
      print('❌ Error updating user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;
    final fieldBgColor = isDark ? Colors.grey[850] : Colors.white;
    final fieldBorderColor = isDark ? Colors.white54 : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Account Details',
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                color: textColor),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.pinkAccent.withOpacity(0.3),
              child: Icon(Icons.person, size: 60, color: Colors.pinkAccent),
            ),
            const SizedBox(height: 30),
            _buildTextField(
                controller: emailController,
                label: 'E-mail',
                textColor: textColor,
                bgColor: fieldBgColor!,
                borderColor: fieldBorderColor),
            const SizedBox(height: 20),
            _buildTextField(
                controller: cityController,
                label: 'City',
                textColor: textColor,
                bgColor: fieldBgColor,
                borderColor: fieldBorderColor),
            const SizedBox(height: 20),
            _buildTextField(
                controller: phoneController,
                label: 'Phone Number',
                textColor: textColor,
                bgColor: fieldBgColor,
                borderColor: fieldBorderColor),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateUserData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  backgroundColor:
                  isDark ? Colors.pinkAccent : Colors.purple,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResetPasswordPage()),
                );
              },
              child: Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.blue[200] : Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
        required String label,
        required Color textColor,
        required Color bgColor,
        required Color borderColor}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.pinkAccent),
        ),
      ),
    );
  }
}
