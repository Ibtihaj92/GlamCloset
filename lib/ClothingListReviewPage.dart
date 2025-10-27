import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

class ClothingListReviewPage extends StatefulWidget {
  const ClothingListReviewPage({super.key});

  @override
  State<ClothingListReviewPage> createState() => _ClothingListReviewPageState();
}

class _ClothingListReviewPageState extends State<ClothingListReviewPage> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('rented_clothes');
  List<Map<String, dynamic>> clothes = [];

  @override
  void initState() {
    super.initState();
    _loadClothesFromFirebase();
  }

  void _loadClothesFromFirebase() {
    _ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final fetched = data.entries.map((e) {
          final cloth = Map<String, dynamic>.from(e.value);
          return {
            'id': e.key,
            'name': cloth['name'] ?? 'Unknown',
            'age': cloth['ageRange'] ?? 'N/A',
            'price': cloth['price'] ?? 0,
            'available': cloth['available'] ?? true,
            'imageBase64': cloth['imageBase64'] ?? '',
          };
        }).toList();

        setState(() {
          clothes = fetched;
        });
      } else {
        setState(() => clothes = []);
      }
    });
  }

  // Toggle availability in Firebase
  void _toggleAvailability(int index, bool value) {
    final id = clothes[index]['id'];
    _ref.child(id).update({'available': value});
  }

  // Delete from Firebase
  void _deleteItem(int index) {
    final id = clothes[index]['id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text("Are you sure you want to remove this clothing item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _ref.child(id).remove();
              Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    final backgroundColor = isDark ? Colors.black : Colors.grey[100];
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: BackButton(color: textColor),
        backgroundColor: cardColor,
        elevation: 2,
        title: Text(
          "Clothing List Review",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: () => themeNotifier.toggleTheme(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: clothes.isEmpty
            ? Center(
          child: Text(
            "No clothes available",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        )
            : ListView.builder(
          itemCount: clothes.length,
          itemBuilder: (context, index) {
            final item = clothes[index];
            final isAvailable = item['available'] as bool;
            final imageData = item['imageBase64'];

            return Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageData != null && imageData.isNotEmpty
                          ? Image.memory(
                        base64Decode(imageData),
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        height: 70,
                        width: 70,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${item['price']} OMR",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.green[300]
                                  : Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (item['age'] != null)
                            Text(
                              "Age: ${item['age']}",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAvailable ? "Available" : "Unavailable",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(index),
                            ),
                            Switch(
                              value: isAvailable,
                              onChanged: (value) =>
                                  _toggleAvailability(index, value),
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              inactiveTrackColor: Colors.red[200],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
