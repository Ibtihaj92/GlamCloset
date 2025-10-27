import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();

  Future<void> _resetPassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ New password and confirm password do not match.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not logged in')),
        );
        return;
      }

      if (currentPassword == newPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ New password cannot be the same as the current password.')),
        );
        return;
      }

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Password successfully updated.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required Function() toggleObscure,
    required String? Function(String?) validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final fillColor = isDark ? Colors.grey[850] : Colors.white;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: textColor),
          onPressed: toggleObscure,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset('images/reset_password.png', height: 210),
                    const SizedBox(height: 30),
                    Text(
                      "Reset Your Password",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Enter your current password and new password",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, color: isDark ? Colors.grey[300] : Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    _buildPasswordField(
                      controller: currentPasswordController,
                      label: "Current Password",
                      obscureText: _obscureCurrentPassword,
                      toggleObscure: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter current password";
                        if (value.contains(" ")) return "Current password cannot contain spaces";
                        if (value.length < 8) return "Current password must be at least 8 characters";
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildPasswordField(
                      controller: newPasswordController,
                      label: "New Password",
                      obscureText: _obscureNewPassword,
                      toggleObscure: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please enter new password";
                        if (value.contains(" ")) return "New password cannot contain spaces";
                        if (value.length < 8) return "New password must be at least 8 characters";
                        if (!RegExp(r'[A-Z]').hasMatch(value)) return "Must contain at least one capital letter";
                        if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) return "Must contain at least one special character";
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildPasswordField(
                      controller: confirmPasswordController,
                      label: "Confirm Password",
                      obscureText: _obscureConfirmPassword,
                      toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Please confirm your password";
                        if (value != newPasswordController.text) return "Passwords do not match";
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Reset Password",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "← Back to Profile",
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
