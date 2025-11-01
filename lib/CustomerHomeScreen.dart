import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'CartScreen.dart';
import 'settings_page.dart';
import 'theme_notifier.dart';
import 'AccountDetails.dart';


class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 1;

  List<Map<String, dynamic>> allDresses = [];
  Set<String> favoriteDressIds = {};
  Set<String> cartDressIds = {};
  final userId = FirebaseAuth.instance.currentUser?.uid;

  late TabController _tabController;

  final List<String> tabs = ['All', 'Eid', 'Wedding', 'Party'];

  Map<String, int> selectedQuantities = {}; // 🔹 الكميات المختارة لكل قطعة

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadClothesFromFirebase();
    _loadUserCart();
    _loadUserWishlist();
  }

  void _loadClothesFromFirebase() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    DatabaseReference ref = FirebaseDatabase.instance.ref('rented_clothes');
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final filteredData = data.entries.where((e) {
          final cloth = Map<String, dynamic>.from(e.value);
          return cloth['available'] == true && cloth['ownerId'] != currentUserId;
        }).map((e) {
          final cloth = Map<String, dynamic>.from(e.value);
          return {
            'id': cloth['id'] ?? '',
            'title': cloth['name'] ?? 'Unknown',
            'age': cloth['ageRange'] ?? 'N/A',
            'price': cloth['price']?.toString() ?? '0',
            'imageBase64': cloth['imageBase64'] ?? '',
            'rentedCount': cloth['rentedCount'] ?? 0,
            'category': cloth['occasion'] ?? 'All', // 🔹 use occasion
            'quantity': cloth['quantity'] ?? 1, // 🔹 عدد القطع المتاحة
          };
        }).toList();

        setState(() {
          allDresses = filteredData;
          // Initialize selectedQuantities
          for (var item in filteredData) {
            selectedQuantities[item['id']] = 1;
          }
        });
      } else {
        setState(() => allDresses = []);
      }
    });
  }

  void _loadUserCart() {
    if (userId == null) return;
    final cartRef = FirebaseDatabase.instance.ref('users/$userId/cart');
    cartRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          cartDressIds = data.keys.map((e) => e.toString()).toSet();
        });
      } else {
        setState(() => cartDressIds = {});
      }
    });
  }

  void _loadUserWishlist() {
    if (userId == null) return;
    final wishlistRef = FirebaseDatabase.instance.ref('users/$userId/wishlist');
    wishlistRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          favoriteDressIds = data.keys.map((e) => e.toString()).toSet();
        });
      } else {
        setState(() => favoriteDressIds = {});
      }
    });
  }

  void _onNavBarTapped(int index) {
    setState(() => _currentIndex = index);

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartScreen(
            rentedItems: allDresses
                .where((dress) => cartDressIds.contains(dress['id']))
                .map((item) {
              return {
                'id': item['id'],
                'title': item['title'],
                'age': item['age'],
                'price': item['price'],
                'image': item['imageBase64'] != null && item['imageBase64'].isNotEmpty
                    ? 'data:image/png;base64,${item['imageBase64']}'
                    : null,
              };
            }).toList(),
          ),
        ),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsPage(previousPage: CustomerHomeScreen()),
        ),
      );

    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingsPage()),
      );
    }
  }

  void _openWishlistScreen() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;

    List<Map<String, dynamic>> favoriteDresses =
    allDresses.where((dress) => favoriteDressIds.contains(dress['id'])).toList();

    final cardGradient = isDark
        ? [Colors.deepPurple.shade700, Colors.blueGrey.shade600]
        : [Colors.pink.shade300, Colors.purple.shade400];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setStateWishlist) => Scaffold(
            backgroundColor: isDark ? Colors.black : Colors.grey[50],
            appBar: AppBar(
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              title: const Text('Wishlist'),
            ),
            body: favoriteDresses.isEmpty
                ? Center(
              child: Text(
                'No favorites yet 😔',
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54),
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: favoriteDresses.length,
              itemBuilder: (context, index) {
                final item = favoriteDresses[index];
                return _buildDressCard(item, cardGradient, isDark,
                    onFavoriteToggle: () {
                      setStateWishlist(() {
                        favoriteDresses.removeAt(index);
                      });
                      _toggleWishlist(item);
                    });
              },
            ),
          ),
        ),
      ),
    );
  }

  void _toggleWishlist(Map<String, dynamic> item) {
    if (userId == null) return;
    final wishlistRef =
    FirebaseDatabase.instance.ref('users/$userId/wishlist/${item['id']}');

    if (favoriteDressIds.contains(item['id'])) {
      wishlistRef.remove();
      setState(() {
        favoriteDressIds.remove(item['id']);
      });
    } else {
      wishlistRef.set({
        'id': item['id'],
        'title': item['title'],
        'age': item['age'],
        'price': item['price'],
        'image': item['imageBase64'] != null && item['imageBase64'].isNotEmpty
            ? 'data:image/png;base64,${item['imageBase64']}'
            : null,
      });
      setState(() {
        favoriteDressIds.add(item['id']);
      });
    }
  }

  void _toggleCart(Map<String, dynamic> item) {
    if (userId == null) return;
    final cartRef = FirebaseDatabase.instance.ref('users/$userId/cart/${item['id']}');

    if (cartDressIds.contains(item['id'])) return;
    cartRef.set({
      'id': item['id'],
      'title': item['title'],
      'age': item['age'],
      'price': item['price'],
      'quantity': selectedQuantities[item['id']] ?? 1, // 🔹 إضافة الكمية
      'image': item['imageBase64'] != null && item['imageBase64'].isNotEmpty
          ? 'data:image/png;base64,${item['imageBase64']}'
          : null,
    });
  }

  void _showFullImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.memory(
              base64Decode(base64Image),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDressCard(Map<String, dynamic> item, List<Color> cardGradient, bool isDark,
      {VoidCallback? onFavoriteToggle}) {
    final isFavorite = favoriteDressIds.contains(item['id']);
    final id = item['id'];
    final maxQty = item['quantity'] ?? 1;
    final currentQty = selectedQuantities[id] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: cardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black54 : Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: GestureDetector(
                onTap: () => _showFullImage(item['imageBase64']),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: item['imageBase64'] != null &&
                      item['imageBase64'].isNotEmpty
                      ? MemoryImage(base64Decode(item['imageBase64']))
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: item['imageBase64'] == null || item['imageBase64'].isEmpty
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
                ),
              ),
              title: Text(
                item['title'],
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14),
              ),
              subtitle: Text(
                'Age: ${item['age']} | Qty: $currentQty', // 🔹 إضافة الكمية هنا
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Increment / Decrement buttons
                  Row(
                    children: [
                      GestureDetector(
                        onTap: currentQty > 1
                            ? () {
                          setState(() {
                            selectedQuantities[id] = currentQty - 1;
                          });
                        }
                            : null,
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: currentQty > 1 ? Colors.white : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentQty',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: currentQty < maxQty
                            ? () {
                          setState(() {
                            selectedQuantities[id] = currentQty + 1;
                          });
                        }
                            : null,
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: currentQty < maxQty ? Colors.white : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onFavoriteToggle ?? () {
                      _toggleWishlist(item);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 20),
                    onPressed: () {
                      Share.share(
                        '👗 Check out this Omani outfit on GlamCloset!\n'
                            '✨ ${item['title']} - ${item['price']} OMR\n\n'
                            'Rent it now on GlamCloset App! 💫',
                        subject: 'GlamCloset Outfit',
                      );
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _toggleCart(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${item['title']} added to cart')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: cardGradient[0],
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Rent'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -13,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(12),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${item['price']} OMR',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // يمكنك تطبيق نفس العدّاد على _buildTrendingDressCard إذا أردت

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final bgColor = isDark ? Colors.black : Colors.grey[50];
    final cardGradient = isDark
        ? [Colors.deepPurple.shade700, Colors.blueGrey.shade600]
        : [Colors.pink.shade300, Colors.purple.shade400];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text('GlamCloset', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pink),
            onPressed: _openWishlistScreen,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search + Profile
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AccountDetailsPage()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search dresses...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon:
                      Icon(Icons.mic, color: isDark ? Colors.white : Colors.black),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // TabBar view with filtered dresses
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: tabs.map((category) {
                  final dressesToShow = category == 'All'
                      ? allDresses
                      : allDresses.where((d) => d['category'] == category).toList();

                  if (dressesToShow.isEmpty) {
                    return Center(
                      child: Text(
                        'No dresses for $category ',
                        style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      ...dressesToShow.map(
                            (item) => _buildDressCard(item, cardGradient, isDark),
                      ),
                    ],
                  );

                }).toList(),
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTapped,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        selectedItemColor: Colors.pink,
        unselectedItemColor: isDark ? Colors.white70 : Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
