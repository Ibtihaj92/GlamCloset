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
  final int quantity;

  RentedCloth({
    required this.id,
    required this.name,
    required this.imageBase64,
    required this.ageRange,
    required this.price,
    required this.userId,
    required this.quantity,
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
              quantity: int.tryParse(value['quantity']?.toString() ?? '0') ?? 0,
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
                        ? const Icon(Icons.image, size: 40, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    cloth.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Age: ${cloth.ageRange}\nQuantity: ${cloth.quantity}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 28),
                        onPressed: () => _navigateToUpdateScreen(cloth),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white, size: 28),
                        onPressed: () => _deleteCloth(cloth.id),
                      ),
                    ],
                  ),
                ),
              ),
              // Price badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red[700] : Colors.red[700],
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${cloth.price} OMR',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
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
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AccountDetailsPage()));
          } else if (index == 2) {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => SettingsPage()));
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
  final TextEditingController quantityController = TextEditingController();
  File? _pickedImage;
  bool _imageError = false;
  final _auth = FirebaseAuth.instance;
  String? selectedOccasion;
  final List<String> occasions = ['Wedding', 'Eid', 'Party', 'All'];


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
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
      'quantity': int.parse(quantityController.text),
    'available': int.parse(quantityController.text) > 0,
      'occasion': selectedOccasion,
    };

    await FirebaseDatabase.instance
        .ref('rented_clothes/${newCloth['id']}')
        .set(newCloth);

    Navigator.pop(context);
  }


  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      validator: (value) => validateField(label, value ?? ''),

      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor),
        filled: true,
        fillColor: inputColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  /// ------------------- Shared Validator -------------------
  String? validateField(String label, String value) {
    if (value.trim().isEmpty) return '$label cannot be empty';

    if (label == "Name of the cloth") {
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
        return 'Name must contain only letters';
      }
    }
    if (label == "Size (Age Range)") {
      // Accept single number
      if (RegExp(r'^\d+$').hasMatch(value)) {
        final numValue = int.parse(value);
        if (numValue <= 0) return 'Size must be greater than 0';
      }
      // Accept range like 3-9
      else if (RegExp(r'^\d+-\d+$').hasMatch(value)) {
        final parts = value.split('-');
        final start = int.parse(parts[0]);
        final end = int.parse(parts[1]);
        if (start <= 0 || end <= 0) return 'Size numbers must be greater than 0';
        if (start >= end) return 'Start of range must be less than end';
      }
      else {
        return 'Size must be a number or range like 3-9';
      }
    }

    if (label == "Price"|| label == "Quantity") {
      final numValue = double.tryParse(value);
      if (numValue == null) return '$label must be a number';
      if (numValue <= 0) return '$label must be greater than 0';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 28, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                Center(
                    child: Text('Add New Cloth',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor))),
                const SizedBox(height: 32),
                _buildTextField("Name of the cloth", nameController),
                const SizedBox(height: 16),
                _buildTextField("Size (Age Range)", sizeController),
                const SizedBox(height: 16),
                _buildTextField("Price", priceController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField("Quantity", quantityController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedOccasion,
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  decoration: InputDecoration(
                    labelText: "Occasion",
                    filled: true,
                    fillColor: inputColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: occasions.map((occasion) {
                    return DropdownMenuItem(
                      value: occasion,
                      child: Text(occasion, style: TextStyle(color: textColor)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedOccasion = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? 'Please select an occasion' : null,
                ),


                const SizedBox(height: 16),
                Text("Pick Image", style: TextStyle(color: textColor)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                        color: inputColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey)),
                    child: _pickedImage != null
                        ? Image.file(_pickedImage!, fit: BoxFit.cover)
                        : const Center(
                        child: Icon(Icons.add_a_photo,
                            size: 50, color: Colors.grey)),
                  ),
                ),
                if (_imageError) const SizedBox(height: 8),
                if (_imageError)
                  const Text("Please pick an image",
                      style: TextStyle(color: Colors.red, fontSize: 14)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveCloth,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text("Add Cloth",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------- Update Clothes Screen -------------------
class UpdateClothScreen extends StatefulWidget {
  final RentedCloth cloth;
  const UpdateClothScreen({super.key, required this.cloth});

  @override
  State<UpdateClothScreen> createState() => _UpdateClothScreenState();
}

class _UpdateClothScreenState extends State<UpdateClothScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController sizeController;
  late TextEditingController priceController;
  late TextEditingController quantityController;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.cloth.name);
    sizeController = TextEditingController(text: widget.cloth.ageRange);
    priceController = TextEditingController(text: widget.cloth.price.toString());
    quantityController = TextEditingController(text: widget.cloth.quantity.toString());
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    String base64Image = widget.cloth.imageBase64;
    if (_pickedImage != null) {
      final bytes = await _pickedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final updatedCloth = {
      'id': widget.cloth.id,
      'name': nameController.text.trim(),
      'ageRange': sizeController.text.trim(),
      'price': double.parse(priceController.text),
      'imageBase64': base64Image,
      'userId': widget.cloth.userId,
      'quantity': int.parse(quantityController.text),
    };

    await FirebaseDatabase.instance
        .ref('rented_clothes/${widget.cloth.id}')
        .update(updatedCloth);
    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      validator: (value) {
        if (value == null || value.trim().isEmpty)
          return '$label cannot be empty';
        if (label == "Name of the cloth") {
          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
            return 'Name must contain only letters';
          }
        }
        if (label == "Size (Age Range)") {
          // Accept single number
          if (RegExp(r'^\d+$').hasMatch(value)) {
            final numValue = int.parse(value);
            if (numValue <= 0) return 'Size must be greater than 0';
          }
          // Accept range like 3-9
          else if (RegExp(r'^\d+-\d+$').hasMatch(value)) {
            final parts = value.split('-');
            final start = int.parse(parts[0]);
            final end = int.parse(parts[1]);
            if (start <= 0 || end <= 0) return 'Size numbers must be greater than 0';
            if (start >= end) return 'Start of range must be less than end';
          }
          else {
            return 'Size must be a number or range like 3-9';
          }
        }


        if ( label == "Price" || label == "Quantity") {
          final numValue = double.tryParse(value);
          if (numValue == null) return '$label must be a number';
          if (numValue <= 0) return '$label must be greater than 0';
        }


        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor),
        filled: true,
        fillColor: inputColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final inputColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 28, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                Center(
                    child: Text('Update Cloth',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor))),
                const SizedBox(height: 32),
                _buildTextField("Name of the cloth", nameController),
                const SizedBox(height: 16),
                _buildTextField("Size (Age Range)", sizeController),
                const SizedBox(height: 16),
                _buildTextField("Price", priceController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField("Quantity", quantityController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                Text("Pick Image", style: TextStyle(color: textColor)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                        color: inputColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey)),
                    child: _pickedImage != null
                        ? Image.file(_pickedImage!, fit: BoxFit.cover)
                        : Image.memory(base64Decode(widget.cloth.imageBase64),
                        fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text("Save Changes",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}