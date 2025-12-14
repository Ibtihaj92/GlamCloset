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
  final double securityDepositPerItem = 5.0;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    cartItems = List<Map<String, dynamic>>.from(widget.rentedItems);
    if (!widget.skipFirebase) {
      _loadUserCart();
    }
  }

  void _loadUserCart() {
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
    int quantity = item['quantity'] ?? 1;
    return sum + (price * quantity);
  });

  double get totalDeposit => cartItems.length * securityDepositPerItem;

  double get grandTotal => totalPrice + totalDeposit;

  int get totalItems => cartItems.fold<int>(
    0,
        (sum, item) => sum + ((item['quantity'] ?? 1) as int),
  );

  Future<void> restoreItemToStock(Map<String, dynamic> item) async {
    try {
      final DatabaseReference rentedRef =
      FirebaseDatabase.instance.ref('rented_clothes/${item['id']}');

      final snapshot = await rentedRef.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int currentAvailable = data['availableCount'] ?? 0;
        int total = data['quantity'] ?? data['totalCount'] ?? 0;
        int quantity = item['quantity'] ?? 1;

        int newAvailable = currentAvailable + quantity;
        if (newAvailable > total) newAvailable = total;

        await rentedRef.update({
          'availableCount': newAvailable,
          'available': newAvailable > 0,
        });

        print('✅ Restored ${item['id']} → now $newAvailable available');
      }
    } catch (e) {
      print('❌ Error restoring stock: $e');
    }
  }

  void _removeItem(int index) async {
    final removedItem = cartItems[index];
    final userCartRef = FirebaseDatabase.instance.ref('users/$userId/cart');

    await restoreItemToStock(removedItem);
    await userCartRef.child(removedItem['id']).remove();

    setState(() {
      cartItems.removeAt(index);
    });

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty — items restored to stock!')),
      );
    }
  }

  void _updateItemQuantity(Map<String, dynamic> item) {
    if (userId == null) return;
    final userCartRef = FirebaseDatabase.instance.ref('users/$userId/cart');

    userCartRef.child(item['id']).update({
      'quantity': item['quantity'],
    });
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Builder(builder: (context) {
          final isDark = Provider.of<ThemeNotifier>(context).isDarkMode;

          final gradient = isDark
              ? [Colors.deepPurple.shade800, Colors.purple.shade900]
              : [Colors.pink.shade300, Colors.purple.shade300];

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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Size: ${item['size'] ?? ''}  |  ${item['price']} OMR',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white30, width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        int currentQty = item['quantity'] ?? 1;
                        if (currentQty > 1) {
                          setState(() {
                            item['quantity'] = currentQty - 1;
                          });
                          _updateItemQuantity(item);
                        } else {
                          _removeItem(index);
                        }
                      },
                      child: const Icon(Icons.remove, color: Colors.white70, size: 13),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item['quantity'] ?? 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        if (userId == null) return;

                        int currentQty = item['quantity'] ?? 1;
                        final dressRef = FirebaseDatabase.instance.ref('rented_clothes/${item['id']}');
                        final snapshot = await dressRef.get();

                        int availableCount = 0;
                        if (snapshot.exists) {
                          final data = Map<String, dynamic>.from(snapshot.value as Map);
                          availableCount = int.tryParse(
                              data['availableCount']?.toString() ??
                                  data['quantity']?.toString() ??
                                  '0'
                          ) ?? 0;
                        }

                        if (currentQty + 1 <= availableCount) {
                          setState(() {
                            item['quantity'] = currentQty + 1;
                          });
                          _updateItemQuantity(item);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cannot add more. Only $availableCount available.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Icon(Icons.add, color: Colors.white70, size: 13),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 14,
                      width: 0.8,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    GestureDetector(
                      onTap: () => _removeItem(index),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 14),
                    ),
                  ],
                ),
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
            if (icon != null) Icon(icon, size: 18, color: Colors.white70),
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
              child: cartItems.isEmpty
                  ? const Center(child: Text('🛒 Your cart is empty.'))
                  : ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  return _buildCartItem(cartItems[index], index, kAlwaysCompleteAnimation);
                },
              ),
            ),
            const SizedBox(height: 10),
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
                      MaterialPageRoute(
                        builder: (_) => TermsAndConditionsScreen(amount: grandTotal),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment_rounded, color: Colors.white),
                  label: Text(
                    'Pay ${grandTotal.toStringAsFixed(2)} OMR',
                    style: const TextStyle(
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
