import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

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
  // ---------------- Variables ----------------
  int _currentIndex = 1;
  List<Map<String, dynamic>> allDresses = [];
  List<Map<String, dynamic>> filteredDresses = [];
  Set<String> favoriteDressIds = {};
  Set<String> cartDressIds = {};
  final userId = FirebaseAuth.instance.currentUser?.uid;

  late TabController _tabController;
  late TextEditingController _searchController;

  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _showSpeakNowPopup = false;
  String _searchQuery = '';

  // Animations for mic
  late AnimationController _glowController;
  late AnimationController _iconPulseController;
  late Animation<double> _glowAnimation;
  late Animation<double> _iconPulseAnimation;

  // ---------------- Init / Dispose ----------------
  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 1, vsync: this);
    _searchController = TextEditingController();

    _speech = stt.SpeechToText();
    _speech.initialize(debugLogging: true);

    // Animation setup
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.2).animate(_glowController);
    _iconPulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(_iconPulseController);

    // Firebase data
    _loadClothesFromFirebase();
    _loadUserCart();
    _loadUserWishlist();

    // Permissions
    _checkMicPermission();
  }

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    _glowController.dispose();
    _iconPulseController.dispose();
    super.dispose();
  }

  // ---------------- Permissions ----------------
  Future<void> _checkMicPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required for voice search')),
      );
    }
  }

  // ---------------- Occasion Detection ----------------
  List<String> getSeasonalOccasions() {
    final today = DateTime.now();
    final List<String> suggestions = [];

    // National Day
    if (today.month == 12 && today.day ==5 && today.day <= 20) {
      suggestions.add('National Day');
    }

    // Eid Al-Fitr
    final eidAlFitrStart = DateTime(2025, 4, 23);
    final eidAlFitrEnd = DateTime(2025, 4, 25);
    if (!today.isBefore(eidAlFitrStart) && !today.isAfter(eidAlFitrEnd)) {
      suggestions.add('Eid Al-Fitr');
    }

    // Eid Al-Adha
    final eidAlAdhaStart = DateTime(2025, 6, 28);
    final eidAlAdhaEnd = DateTime(2025, 6, 30);
    if (!today.isBefore(eidAlAdhaStart) && !today.isAfter(eidAlAdhaEnd)) {
      suggestions.add('Eid Al-Adha');
    }

    return suggestions;
  }

  // ---------------- Speech Handling ----------------
  Future<void> _startListening() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val.toLowerCase().contains('notlistening') && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
      );

      if (!available && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition unavailable on this device')),
        );
        return;
      }

      if (mounted) {
        setState(() {
          _isListening = true;
          _showSpeakNowPopup = true;
        });
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSpeakNowPopup = false);
      });

      await _speech.listen(
        onResult: (val) {
          if (mounted) {
            final spoken = val.recognizedWords;
            setState(() {
              _searchQuery = spoken.toLowerCase();
              _searchController.text = spoken;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length),
              );
              _applyFilter();
            });
          }
        },
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
      );
    } catch (e) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (mounted) setState(() {
      _isListening = false;
      _showSpeakNowPopup = false;
    });
  }

  void _toggleListening() => _isListening ? _stopListening() : _startListening();

  // ---------------- Search Filter ----------------
  void _applyFilter() {
    final q = _searchQuery.trim().toLowerCase();
    setState(() {
      filteredDresses = allDresses.where((d) {
        final title = (d['title']?.toString() ?? '').toLowerCase();
        final size = (d['size']?.toString() ?? '').toLowerCase();
        final age = (d['age']?.toString() ?? '').toLowerCase();
        final price = (d['price']?.toString() ?? '').toLowerCase();

        return q.isEmpty || title.contains(q) || size.contains(q) || age.contains(q) || price.contains(q);
      }).toList();
    });
  }

  // ---------------- Firebase Data ----------------
  void _loadClothesFromFirebase() {
    final ref = FirebaseDatabase.instance.ref('rented_clothes');

    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        if (mounted) setState(() {
          allDresses = [];
          filteredDresses = [];
        });
        return;
      }

      final List<Map<String, dynamic>> loaded = [];
      data.forEach((key, value) {
        final cloth = Map<String, dynamic>.from(value);
        if (cloth['userId'] == userId) return;
        if (cloth['visible'] == false) return;

        final available = int.tryParse(cloth['availableCount']?.toString() ?? '') ??
            int.tryParse(cloth['quantity']?.toString() ?? '') ?? 0;

        loaded.add({
          'id': cloth['id'] ?? key.toString(),
          'title': cloth['name'] ?? 'Unknown',
          'age': cloth['ageRange'] ?? 'N/A',
          'size': cloth['size'] ?? 'N/A',
          'price': (cloth['price']?.toString() ?? '0'),
          'imageBase64': cloth['imageBase64'] ?? '',
          'rentedCount': cloth['rentedCount'] ?? 0,
          'availableCount': available,
          'occasion': cloth['occasion'] ?? 'All',
        });
      });

      if (mounted) setState(() {
        allDresses = loaded;
        _applyFilter();
      });
    });
  }

  void _loadUserCart() {
    if (userId == null) return;
    final cartRef = FirebaseDatabase.instance.ref('users/$userId/cart');
    cartRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (mounted) setState(() => cartDressIds = data?.keys.map((e) => e.toString()).toSet() ?? {});
    });
  }

  void _loadUserWishlist() {
    if (userId == null) return;
    final wishlistRef = FirebaseDatabase.instance.ref('users/$userId/wishlist');
    wishlistRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (mounted) setState(() => favoriteDressIds = data?.keys.map((e) => e.toString()).toSet() ?? {});
    });
  }

  // ---------------- Wishlist / Cart ----------------
  void _toggleWishlist(Map<String, dynamic> item) {
    if (userId == null) return;
    final wishlistRef = FirebaseDatabase.instance.ref('users/$userId/wishlist/${item['id']}');
    if (favoriteDressIds.contains(item['id'])) {
      wishlistRef.remove();
      if (mounted) setState(() => favoriteDressIds.remove(item['id']));
    } else {
      wishlistRef.set({
        'id': item['id'],
        'title': item['title'],
        'age': item['age'],
        'size': item['size'],
        'price': item['price'],
        'image': item['imageBase64']?.isNotEmpty == true ? 'data:image/png;base64,${item['imageBase64']}' : null,
      });
      if (mounted) setState(() => favoriteDressIds.add(item['id']));
    }
  }

  Future<void> _toggleCart(Map<String, dynamic> item) async {
    if (userId == null) return;

    final cartRef = FirebaseDatabase.instance.ref('users/$userId/cart/${item['id']}');
    final dressRef = FirebaseDatabase.instance.ref('rented_clothes/${item['id']}');

    try {
      final cartSnapshot = await cartRef.get();
      int currentCountInCart = cartSnapshot.exists
          ? int.tryParse((cartSnapshot.value as Map)['quantity']?.toString() ?? '1') ?? 1
          : 0;

      final dressSnapshot = await dressRef.get();
      int availableCount = dressSnapshot.exists
          ? int.tryParse(((dressSnapshot.value as Map)['availableCount']?.toString() ?? (dressSnapshot.value as Map)['quantity']?.toString() ?? '0')) ?? 0
          : 0;

      if (currentCountInCart + 1 > availableCount) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot add more. Only $availableCount available for ${item['title']}.'), backgroundColor: Colors.red),
        );
        return;
      }

      int newCount = currentCountInCart + 1;
      await cartRef.set({
        'id': item['id'],
        'title': item['title'],
        'age': item['age'],
        'size': item['size'],
        'price': item['price'],
        'quantity': newCount,
        'image': item['imageBase64']?.isNotEmpty == true ? 'data:image/png;base64,${item['imageBase64']}' : null,
      });

      if (mounted) setState(() => cartDressIds.add(item['id']));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['title']} added to cart (x$newCount).'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding to cart.'), backgroundColor: Colors.red),
      );
    }
  }

  // ---------------- Image Viewer ----------------
  void _showFullImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.memory(base64Decode(base64Image), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  // ---------------- Dress Card ----------------
  Widget _buildDressCard(Map<String, dynamic> item, List<Color> cardGradient, bool isDark,
      {VoidCallback? onFavoriteToggle}) {
    final isFavorite = favoriteDressIds.contains(item['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: cardGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: GestureDetector(
                onTap: () => _showFullImage(item['imageBase64']),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: item['imageBase64']?.isNotEmpty == true ? MemoryImage(base64Decode(item['imageBase64'])) : null,
                  backgroundColor: Colors.grey[300],
                  child: (item['imageBase64'] == null || item['imageBase64']!.isEmpty) ? const Icon(Icons.image, color: Colors.grey) : null,
                ),
              ),
              title: Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 14)),
              subtitle: Text('Size: ${item['size']} | Available: ${item['availableCount']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 20),
                    onPressed: onFavoriteToggle ?? () => _toggleWishlist(item),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 20),
                    onPressed: () async {
                      try {
                        final imageBytes = base64Decode(item['imageBase64']);
                        final tempDir = await getTemporaryDirectory();
                        final file = await File('${tempDir.path}/${item['id']}.png').create();
                        await file.writeAsBytes(imageBytes);
                        await Share.shareXFiles([XFile(file.path)], text: '👗 Check out this Omani outfit on GlamCloset!\n✨ ${item['title']} - ${item['price']} OMR\n\nRent it now on GlamCloset App! 💫');
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error sharing this dress.')),
                        );
                      }
                    },
                  ),
                  ElevatedButton(
                    onPressed: (item['availableCount'] ?? 0) == 0 ? null : () => _toggleCart(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (item['availableCount'] ?? 0) == 0 ? Colors.grey : Colors.white,
                      foregroundColor: (item['availableCount'] ?? 0) == 0 ? Colors.white : cardGradient[0],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text((item['availableCount'] ?? 0) == 0 ? 'Sold Out' : 'Rent'),
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
                borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomLeft: Radius.circular(12)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Text('${item['price']} OMR', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Navigation ----------------
  void _onNavBarTapped(int index) {
    setState(() => _currentIndex = index);

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartScreen(
            rentedItems: allDresses
                .where((dress) => cartDressIds.contains(dress['id']))
                .map((item) => {
              'id': item['id'],
              'title': item['title'],
              'age': item['age'],
              'price': item['price'],
              'image': item['imageBase64']?.isNotEmpty == true ? 'data:image/png;base64,${item['imageBase64']}' : null,
            })
                .toList(),
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsPage(previousPage: CustomerHomeScreen()),
        ),
      );
    }
  }

  void _openWishlistScreen() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final isDark = themeNotifier.isDarkMode;

    List<Map<String, dynamic>> favoriteDresses = allDresses.where((dress) => favoriteDressIds.contains(dress['id'])).toList();

    final cardGradient = isDark ? [Colors.deepPurple.shade700, Colors.blueGrey.shade600] : [Colors.pink.shade300, Colors.purple.shade400];

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
                ? Center(child: Text('No favorites yet 😔', style: TextStyle(color: isDark ? Colors.white : Colors.black)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteDresses.length,
              itemBuilder: (context, index) {
                final item = favoriteDresses[index];
                return _buildDressCard(item, cardGradient, isDark, onFavoriteToggle: () {
                  _toggleWishlist(item);
                  setStateWishlist(() {});
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Build UI ----------------
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    final seasonalOccasions = getSeasonalOccasions();
    final suggestedDresses = filteredDresses.where((d) => seasonalOccasions.contains(d['occasion'])).toList();
    final otherDresses = filteredDresses.where((d) => !seasonalOccasions.contains(d['occasion'])).toList();
    final cardGradient = isDark ? [Colors.deepPurple.shade700, Colors.blueGrey.shade600] : [Colors.pink.shade300, Colors.purple.shade400];
    final occasionHeaderText = seasonalOccasions.isEmpty ? '' : '${seasonalOccasions.join(', ')} Collection';

    // Voice input button
    Widget _buildVoiceInput() {
      return GestureDetector(
        onTap: _toggleListening,
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowController, _iconPulseController]),
          builder: (context, child) {
            final bool active = _isListening;
            return Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: active
                    ? [BoxShadow(color: Colors.blue.withOpacity(0.45), blurRadius: 18 * _glowAnimation.value, spreadRadius: 3 * _glowAnimation.value)]
                    : [],
              ),
              child: Transform.scale(
                scale: active ? _iconPulseAnimation.value : 1.0,
                child: Icon(active ? Icons.mic : Icons.mic_none, size: 26, color: active ? Colors.blue : (isDark ? Colors.white : Colors.grey[700])),
              ),
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.grey[50],
          appBar: AppBar(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            title: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search clothes...',
                hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white : Colors.grey[600]),
                suffixIcon: _buildVoiceInput(),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _applyFilter();
              },
            ),
            actions: [IconButton(icon: const Icon(Icons.favorite), onPressed: _openWishlistScreen)],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8),
                child: Text(occasionHeaderText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              ),
              ...suggestedDresses.map((item) => _buildDressCard(item, cardGradient, isDark)),
              const SizedBox(height: 16),
              const Text('All Clothes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...otherDresses.map((item) => _buildDressCard(item, cardGradient, isDark)),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            currentIndex: _currentIndex,
            onTap: _onNavBarTapped,
            selectedItemColor: Colors.pink,
            unselectedItemColor: isDark ? Colors.white54 : Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),

        // Speak Now popup overlay
        if (_showSpeakNowPopup)
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showSpeakNowPopup ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(12)),
                  child: const Text('🎤 Speak now…', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
