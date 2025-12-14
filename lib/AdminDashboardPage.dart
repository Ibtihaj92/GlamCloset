import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'UsersManagementPage.dart';
import 'ClothingListReviewPage.dart';
import 'RentalsReportPage.dart';
import 'settings_page.dart';
import 'theme_notifier.dart';
import 'AdminOrdersPage.dart';
import 'AdminIssuePage.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: () {
              themeNotifier.toggleTheme();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildCard(
              title: 'Users',
              icon: Icons.people,
              gradient: [Colors.blue.shade400, Colors.blue.shade700],
              darkTextColor: Colors.blue.shade900,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsersManagementPage()),
                );
              },
            ),
            _buildCard(
              title: 'Clothes',
              icon: Icons.shopping_bag,
              gradient: [Colors.purple.shade400, Colors.purple.shade700],
              darkTextColor: Colors.purple.shade900,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ClothingListReviewPage()),
                );
              },
            ),
            _buildCard(
              title: 'Rent Report',
              icon: Icons.assignment,
              gradient: [Colors.brown.shade400, Colors.brown.shade700],
              darkTextColor: Colors.brown.shade900,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RentalsReportPage()),
                );
              },
            ),
            _buildCard(
              title: 'Orders',
              icon: Icons.inventory_2_rounded,
              gradient: [Colors.teal.shade400, Colors.teal.shade700],
              darkTextColor: Colors.teal.shade900,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminOrdersPage()),
                );
              },
            ),
            _buildCard(
              title: 'Settings',
              icon: Icons.settings,
              gradient: [Colors.orange.shade400, Colors.orange.shade700],
              darkTextColor: Colors.orange.shade900,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage()),
                );
              },
            ),

            _buildCard(
              title: 'Issues',
              icon: Icons.report_problem,
              gradient: [Colors.grey, Colors.white24],
              darkTextColor: Colors.black,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminIssuePage()),
                );


              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required Color darkTextColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isDark
              ? LinearGradient(
            colors: [Colors.grey.shade900, Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 50,
                  color: isDark ? Colors.white : darkTextColor,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : darkTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
