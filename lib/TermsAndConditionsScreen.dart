import 'package:flutter/material.dart';
import 'PaymentScreen.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  @override
  _TermsAndConditionsScreenState createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.black : Colors.pink.shade400,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black87, Colors.black54] // Dark mode gradient
                : [Colors.pink.shade100, Colors.purple.shade100], // Light mode
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Terms in a Card
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 6,
                    shadowColor:
                    isDark ? Colors.black54 : Colors.pink.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Security Deposit and Return Policy:\n\n'
                            '• The total rental amount includes the outfit rental price plus a security deposit of 20 OMR, payable at the time of rental.\n\n'
                            '• The rented outfit must be returned within 5 days from the rental date.\n\n'
                            '• In case of late returns, additional fees will be charged for each day of delay.\n\n'
                            '• The security deposit will be refunded after the rented item is returned in good condition.',
                        style: TextStyle(
                          fontSize: 16.0,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Checkbox for Agreement
              Row(
                children: [
                  Checkbox(
                    activeColor: isDark ? Colors.purple : Colors.pink.shade400,
                    checkColor: Colors.white,
                    value: _agreed,
                    onChanged: (bool? value) {
                      setState(() {
                        _agreed = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      "I agree with the terms and conditions",
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _agreed
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PaymentScreen()),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor:
                    _agreed ? (isDark ? Colors.purple : Colors.pink.shade400) : null,
                    disabledBackgroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
