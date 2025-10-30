import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'AccountDetails.dart';
import 'ChatBotPage.dart';
import 'WalletPage.dart';
import 'theme_notifier.dart';

class SettingsPage extends StatefulWidget {
  final Widget? previousPage; // optional previous page
  final bool? testIsAdmin; // for tests to bypass Firebase

  const SettingsPage({super.key, this.previousPage, this.testIsAdmin});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool isAdmin = false; // default, will fetch dynamically

  @override
  void initState() {
    super.initState();

    // Use testIsAdmin if provided (for widget tests)
    if (widget.testIsAdmin != null) {
      isAdmin = widget.testIsAdmin!;
    } else {
      _loadUserType();
    }
  }

  // Fetch user type from Firebase
  void _loadUserType() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userRef = FirebaseDatabase.instance.ref('users/$userId');
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        isAdmin = data['userType'] == 'admin';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.grey[50];
    final cardGradient = isDark
        ? [Colors.deepPurple.shade700, Colors.purple.shade900]
        : [Colors.teal.shade300, Colors.green.shade400];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.previousPage != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => widget.previousPage!),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGradientTile(
            title: "Account",
            subtitle: "Manage your account details",
            icon: Icons.person,
            gradient: cardGradient,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountDetailsPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: "Notifications",
            subtitle: "Enable or disable notifications",
            icon: Icons.notifications,
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            gradient: cardGradient,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: "Dark Mode",
            subtitle: "Switch between light and dark themes",
            icon: Icons.dark_mode,
            value: isDark,
            onChanged: (value) {
              themeNotifier.toggleTheme();
            },
            gradient: cardGradient,
          ),
          const SizedBox(height: 16),
          _buildGradientTile(
            title: "ChatBot",
            subtitle: "Get instant support",
            icon: Icons.smart_toy,
            gradient: cardGradient,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatBotScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          if (!isAdmin)
            _buildGradientTile(
              title: "Wallet",
              subtitle: "Check your wallet balance and transactions",
              icon: Icons.account_balance_wallet,
              gradient: cardGradient,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletPage()),
                );
              },
            ),
          const SizedBox(height: 16),
          _buildGradientTile(
            title: "Logout",
            subtitle: "Sign out from your account",
            icon: Icons.logout,
            gradient: [Colors.red.shade400, Colors.orange.shade400],
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGradientTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            inactiveThumbColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}
