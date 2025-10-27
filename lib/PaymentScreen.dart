import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'PaymentSuccessScreen.dart';
import 'theme_notifier.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful! 🎉')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    final textColor = isDark ? Colors.white : Colors.black;
    final fieldColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;
    final hintColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Payment', style: TextStyle(color: textColor)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Preview
              Center(
                child: Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.deepPurple.shade800, Colors.indigo.shade700]
                          : [Colors.amber.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Text(
                          "Credit Card",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: 20,
                        child: Text(
                          _cardNumberController.text.isEmpty
                              ? "**** **** **** 1234"
                              : _cardNumberController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        left: 20,
                        child: Text(
                          _cardHolderController.text.isEmpty
                              ? "Card Holder"
                              : _cardHolderController.text,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        right: 20,
                        child: Text(
                          _expiryDateController.text.isEmpty
                              ? "MM/YY"
                              : _expiryDateController.text,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cardholder Name
              const Text("Cardholder Name", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8.0),
              _buildTextFormField(
                controller: _cardHolderController,
                hint: "John Doe",
                textColor: textColor,
                fieldColor: fieldColor,
                hintColor: hintColor,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter cardholder name';
                  return null;
                },
              ),
              const SizedBox(height: 20.0),

              // Card Number
              const Text("Card Number", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8.0),
              _buildTextFormField(
                controller: _cardNumberController,
                hint: "1234 5678 9012 3456",
                textColor: textColor,
                fieldColor: fieldColor,
                hintColor: hintColor,
                keyboard: TextInputType.number,
                maxLength: 16,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter card number';
                  final cleaned = value.replaceAll(' ', '');
                  if (cleaned.length != 16 || int.tryParse(cleaned) == null) {
                    return 'Enter valid 16-digit card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),

              // Expiry + CVV
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Expiry Date", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8.0),
                        _buildTextFormField(
                          controller: _expiryDateController,
                          hint: "MM/YY",
                          textColor: textColor,
                          fieldColor: fieldColor,
                          hintColor: hintColor,
                          keyboard: TextInputType.datetime,
                          maxLength: 5,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter expiry date';
                            final regex = RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$');
                            if (!regex.hasMatch(value)) return 'Enter valid MM/YY';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("CVV", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8.0),
                        _buildTextFormField(
                          controller: _cvvController,
                          hint: "123",
                          textColor: textColor,
                          fieldColor: fieldColor,
                          hintColor: hintColor,
                          keyboard: TextInputType.number,
                          maxLength: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter CVV';
                            if (value.length != 3 || int.tryParse(value) == null) {
                              return 'Enter valid 3-digit CVV';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40.0),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: _processPayment,
                  child: const Text("Pay", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required Color textColor,
    required Color fieldColor,
    required Color hintColor,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: TextStyle(color: textColor),
      maxLength: maxLength,
      validator: validator,
      onChanged: (_) => setState(() {}), // refresh card preview
      decoration: InputDecoration(
        hintText: hint,
        counterText: "",
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}
