import 'package:flutter/material.dart';
import 'CustomerHomeScreen.dart';
import 'RentedClothesScreen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? Colors.grey[900]! : Colors.grey[50]!;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Top gradient background
            Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.deepPurple.shade700, Colors.pink.shade700]
                      : [Colors.pink.shade400, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "GlamCloset",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 180),
                child: Column(
                  children: [
                    Image.asset(
                      'images/logo.png',
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image,
                            size: 150, color: isDark ? Colors.white30 : Colors.grey);
                      },
                    ),
                    const SizedBox(height: 40),

                    // Customer card
                    _buildActionCard(
                      title: "Customer",
                      subtitle: "Rent traditional Omani clothes easily",
                      color: isDark ? Colors.deepPurple.shade600 : Colors.pink.shade400,
                      icon: Icons.person,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CustomerHomeScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Renter card
                    _buildActionCard(
                      title: "Renter",
                      subtitle: "Share your special pieces with others",
                      color: isDark ? Colors.teal.shade600 : Colors.teal.shade400,
                      icon: Icons.shopping_bag,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                              const RentedClothesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
