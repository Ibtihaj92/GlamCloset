import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_page.dart';
import 'AccountDetails.dart';

/// ------------------- Model -------------------
class RentedCloth {
  final String id;
  final String name;
  final String imageBase64;
  final String ageRange;
  final double price;
  final String userId;

  RentedCloth({
    required this.id,
    required this.name,
    required this.imageBase64,
    required this.ageRange,
    required this.price,
    required this.userId,
  });
}

/// ------------------- Rented Clothes Screen -------------------
class RentedClothesScreen extends StatefulWidget {
  const RentedClothesScreen({super.key});

  @override
  State<RentedClothesScreen> createState() => _RentedClothesScreenState();
}

class _RentedClothesScreenState extends State<RentedClothesScreen> {
  List<RentedCloth> _rentedClothes = [];
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadClothesFromFirebase();
  }

  void _loadClothesFromFirebase() {
    final user = _auth.currentUser;
    if (user == null) return;

    DatabaseReference ref = FirebaseDatabase.instance.ref('rented_clothes');
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        final List<RentedCloth> loadedClothes = [];
        data.forEach((key, value) {
          if (value is Map && value['userId'] == user.uid) {
            loadedClothes.add(RentedCloth(
              id: value['id'] ?? key,
              name: value['name'] ?? '',
              ageRange: value['ageRange'] ?? '',
              price: double.tryParse(value['price'].toString()) ?? 0,
              imageBase64: value['imageBase64'] ?? '',
              userId: value['userId'] ?? '',
            ));
          }
        });
        setState(() {
          _rentedClothes = loadedClothes;
        });
      } else {
        setState(() => _rentedClothes = []);
      }
    });
  }

  void _deleteCloth(String id) async {
    await FirebaseDatabase.instance.ref('rented_clothes/$id').remove();
  }

  void _navigateToAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddClothesDetailsScreen()),
    ).then((_) => _loadClothesFromFirebase());
  }

  void _navigateToUpdateScreen(RentedCloth cloth) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UpdateClothScreen(cloth: cloth)),
    ).then((_) => _loadClothesFromFirebase());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'My Rented Clothes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _rentedClothes.isEmpty
          ? Center(
              child: Text(
                'No clothes yet. Click + to add.',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _rentedClothes.length,
              itemBuilder: (context, index) {
                final cloth = _rentedClothes[index];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.indigo[700]!, Colors.grey]
                              : [Colors.deepPurpleAccent, Colors.pinkAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black54 : Colors.black26,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: cloth.imageBase64.isNotEmpty
                              ? MemoryImage(base64Decode(cloth.imageBase64))
                              : null,
                          child: cloth.imageBase64.isEmpty
                              ? const Icon(Icons.image,
                                  size: 40, color: Colors.grey)
                              : null,
                        ),
                        title: Text(
                          cloth.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white),
                        ),
                        subtitle: Text(
                          'Age: ${cloth.ageRange}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.white, size: 28),
                              onPressed: () => _navigateToUpdateScreen(cloth),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.white, size: 28),
                              onPressed: () => _deleteCloth(cloth.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          '${cloth.price} OMR',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: isDark ? Colors.white70 : Colors.grey,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AccountDetailsPage()));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SettingsPage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

/// ------------------- Shared Validator -------------------
String? validateField(String label, String value) {
  if (value.trim().isEmpty) return '$label cannot be empty';

  if (label == "Name of the cloth") {
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name must contain only letters';
    }
  }

  if (label == "Size (Age Range)" || label == "Price") {
    final numValue = double.tryParse(value);
    if (numValue == null) return '$label must be a number';
    if (numValue <= 0) return '$label must be greater than 0';
  }

  return null;
}

/// ------------------- Add Clothes Screen -------------------
class AddClothesDetailsScreen extends StatefulWidget {
  const AddClothesDetailsScreen({super.key});

  @override
  State<AddClothesDetailsScreen> createState() =>
      _AddClothesDetailsScreenState();
}

class _AddClothesDetailsScreenState extends State<AddClothesDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  File? _pickedImage;
  bool _imageError = false;
  final _auth = FirebaseAuth.instance;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final ext = picked.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Only JPG, JPEG, or PNG images are allowed")));
        return;
      }

      setState(() {
        _pickedImage = File(picked.path);
        _imageError = false;
      });
    }
  }

  void _saveCloth() async {
    if (!_formKey.currentState!.validate() || _pickedImage == null) {
      setState(() => _imageError = _pickedImage == null);
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final bytes = await _pickedImage!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final newCloth = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': nameController.text.trim(),
      'ageRange': sizeController.text.trim(),
      'price': double.parse(priceController.text),
      'imageBase64': base64Image,
      'userId': user.uid,
    };

    await FirebaseDatabase.instance
        .ref('rented_clothes/${newCloth['id']}')
        .set(newCloth);
    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) => validateField(label, value ?? ''),
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Cloth")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField("Name of the cloth", nameController),
                const SizedBox(height: 16),
                _buildTextField("Size (Age Range)", sizeController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField("Price", priceController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _imageError ? Colors.red : Colors.grey),
                    ),
                    child: _pickedImage != null
                        ? Image.file(_pickedImage!, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(Icons.add_a_photo,
                                size: 50, color: Colors.grey),
                          ),
                  ),
                ),
                if (_imageError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("Please pick an image",
                        style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveCloth,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size(double.infinity, 50)),
                  child: const Text("Add Cloth",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
