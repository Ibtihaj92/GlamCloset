import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'TermsAndConditionsScreen.dart';
import 'theme_notifier.dart';
import 'CustomerHomeScreen.dart';
import 'settings_page.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rentedItems;
  final bool skipFirebase; // new flag

  const CartScreen({super.key, this.rentedItems = const [], this.skipFirebase = false});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<Map<String, dynamic>> cartItems;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  // 🔹 Security deposit per dress
  final double securityDepositPerItem = 20.0;

  @override
  void initState() {
    super.initState();
    cartItems = List<Map<String, dynamic>>.from(widget.rentedItems);
    if (!widget.skipFirebase) {
      _loadUserCart();
    }
  }


  void _loadUserCart() {
    // Use the passed rentedItems directly
    cartItems = List<Map<String, dynamic>>.from(widget.rentedItems);
    if (userId == null) return;
    final userCartRef = FirebaseDatabase.instance.ref('users/$userId/cart');
    userCartRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          cartItems = data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
        });
      } else {
        setState(() => cartItems = []);
      }
    });
  }

  double get totalPrice => cartItems.fold(0.0, (sum, item) {
    double price = 0;
    if (item['price'] is String) {
      price = double.tryParse(item['price'].toString().replaceAll('OMR', '').trim()) ?? 0;
    } else if (item['price'] is num) {
      price = (item['price'] as num).toDouble();
    }
    return sum + price;
  });

  double get totalDeposit => cartItems.length * securityDepositPerItem;

  double get grandTotal => totalPrice + totalDeposit;

  int get totalItems => cartItems.length;

  int _currentIndex = 0;

  void _removeItem(int index) {
    final removedItem = cartItems[index];
    final userCartRef = FirebaseDatabase.instance.ref('users/$userId/cart');
    userCartRef.child(removedItem['id']).remove();

    _listKey.currentState!.removeItem(
      index,
          (context, animation) => _buildCartItem(removedItem, index, animation),
      duration: const Duration(milliseconds: 500),
    );
    cartItems.removeAt(index);
    setState(() {});
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Builder(builder: (context) {
          final isDark = Provider.of<ThemeNotifier>(context).isDarkMode;

          final lightGradients = [
            [Colors.pink.shade300, Colors.purple.shade300],
            [Colors.orange.shade300, Colors.yellow.shade400],
            [Colors.teal.shade300, Colors.green.shade400],
          ];
          final darkGradients = [
            [Colors.deepPurple.shade700, Colors.purple.shade900],
            [Colors.orange.shade900, Colors.red.shade900],
            [Colors.teal.shade700, Colors.green.shade900],
          ];
          final gradient = isDark
              ? darkGradients[index % darkGradients.length]
              : lightGradients[index % lightGradients.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black54 : Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: item['image'] != null && item['image'].toString().startsWith('data:image')
                    ? Image.memory(
                  Uri.parse(item['image']).data!.contentAsBytes(),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
                    : Image.asset(
                  item['image'] ?? 'images/default.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                item['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                'Age: ${item['age'] ?? ''}  |  ${item['price']} OMR',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                onPressed: () => _removeItem(index),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value,
      {bool bold = false, double size = 15, Color? color, IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null)
              Icon(icon, size: 18, color: Colors.white70),
            if (icon != null) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: size,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  void _onNavBarTapped(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SettingsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final backgroundColor = isDark ? Colors.black : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Cart Shopping',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: cartItems.length,
                itemBuilder: (context, index, animation) {
                  return _buildCartItem(cartItems[index], index, animation);
                },
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Modern Totals & Payment Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24, width: 0.6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTotalRow('Items', '$totalItems', icon: Icons.shopping_bag_outlined),
                      const SizedBox(height: 8),
                      _buildTotalRow(' Total', '${totalPrice.toStringAsFixed(2)} OMR', icon: Icons.attach_money_rounded),
                      const SizedBox(height: 8),
                      _buildTotalRow(' Deposit Security', '${totalDeposit.toStringAsFixed(2)} OMR', icon: Icons.lock_outline),
                      const Divider(color: Colors.white70, thickness: 0.6, height: 20),
                      _buildTotalRow(
                        'Grand Total',
                        '${grandTotal.toStringAsFixed(2)} OMR',
                        bold: true,
                        size: 18,
                        color: Colors.red[900],
                        icon: Icons.star_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (cartItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please add a dress to your cart before payment!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TermsAndConditionsScreen()),
                    );
                  },
                  icon: const Icon(Icons.payment_rounded, color: Colors.white),
                  label: const Text(
                    'Proceed to Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor: Colors.pinkAccent.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'All prices include refundable deposits. Payment is secured.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTapped,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: backgroundColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
