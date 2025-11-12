import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'ResetPassword.dart';
import 'user_login.dart';
import 'theme_notifier.dart';

class AccountDetailsPage extends StatefulWidget {
  final bool testIsLoading;

  const AccountDetailsPage({super.key, this.testIsLoading = false});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  bool isLoading = true;
  File? _imageFile;
  final picker = ImagePicker();
  String? profileImageUrl;

  String? selectedGovernorate;
  String? selectedWilayat;

  final Map<String, List<String>> governorateMap = {
    'Muscat': ['Muscat', 'Mutrah', 'Al Amarat', 'Bawshar', 'Seeb', 'Qurayyat'],
    'Ad Dakhiliyah': ['Nizwa','Bahla','Manah','Al Hamra','Adam','Izki','Samail','Bidbid','Al Jabal Al Akhdar'],
    'North Al Batinah': ['Sohar','Shinas','Liwa','Saham','Al Khaburah','Al Suwaiq'],
    'South Al Batinah': ['Rustaq','Al Awabi','Nakhal','Wadi Al Ma’awil','Barka','Al Musannah'],
    'Al Wusta': ['Haima','Mahout','Duqm','Al Jazer'],
    'North Ash Sharqiyah': ['Ibra','Mudhaibi','Bidiya','Al Qabil','Wadi Bani Khalid','Dema Wa Tayeen','Sinaw'],
    'South Ash Sharqiyah': ['Sur','Al Kamil Wal Wafi','Jaalan Bani Bu Hassan','Jaalan Bani Bu Ali','Masirah'],
    'Ad Dhahirah': ['Ibri','Yanqul','Dhank'],
    'Musandam': ['Khasab','Diba','Bukha','Madha'],
    'Dhofar': ['Salalah','Taqah','Mirbat','Rakhyut','Thumrait','Dhalkut','Al Mazyona','Muqshin','Shaleem and Al Halaniyat Islands','Sadah'],
    'Al Buraimi': ['Al Buraimi','Mahdah','As Sunainah'],
  };

  @override
  void initState() {
    super.initState();
    if (!widget.testIsLoading) {
      fetchUserData();
    } else {
      isLoading = false;
    }
  }

  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userRef = FirebaseDatabase.instance.ref().child('users/$uid');
        final snapshot = await userRef.get();

        if (snapshot.exists) {
          final data = snapshot.value as Map;
          emailController.text = data['email'] ?? '';
          selectedGovernorate = data['governorate'];
          selectedWilayat = data['wilayat'];
          phoneController.text = data['contactNo'] ?? '';
          genderController.text = data['gender'] ?? '';
          profileImageUrl = data['profileImage'];
        }
      }
    } catch (e) {
      print('⚠️ Error fetching user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
      await userRef.update({'profileImage': base64Image});

      setState(() {
        profileImageUrl = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile image updated successfully')),
      );
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to upload image: $e')),
      );
    }
  }

  Future<void> removeProfilePicture() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final userRef = FirebaseDatabase.instance.ref('users/$uid');
      await userRef.update({'profileImage': null});

      setState(() {
        _imageFile = null;
        profileImageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Profile picture removed successfully')),
      );
    } catch (e) {
      print('❌ Error removing profile picture: $e');
    }
  }

  void showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.pinkAccent),
                title: const Text("Choose from gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.pinkAccent),
                title: const Text("Take a photo"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadImage(ImageSource.camera);
                },
              ),
              if (profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text("Remove current photo", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    removeProfilePicture();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isValidPhone(String phone) {
    final regex = RegExp(r'^[97]\d{7}$');
    return regex.hasMatch(phone);
  }

  Future<void> updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    if (genderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your gender")),
      );
      return;
    }

    if (selectedGovernorate == null || selectedWilayat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your governorate and wilayat")),
      );
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userRef = FirebaseDatabase.instance.ref().child('users/$uid');
      await userRef.update({
        'governorate': selectedGovernorate,
        'wilayat': selectedWilayat,
        'contactNo': phoneController.text.trim(),
        'gender': genderController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Information updated successfully')),
      );
    } catch (e) {
      print('❌ Error updating user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final bgColor = isDark ? Colors.black : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Account Details', style: TextStyle(color: textColor)),
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Avatar
            GestureDetector(
              onTap: () => showProfileOptions(context),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                    ? MemoryImage(base64Decode(profileImageUrl!))
                    : null,
                child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Change profile photo", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),

            // Form Fields
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Email
                  TextFormField(
                    controller: emailController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: "Email",
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Governorate
                  DropdownButtonFormField<String>(
                    value: selectedGovernorate,
                    hint: const Text("Select Governorate"),
                    decoration: InputDecoration(
                      labelText: "Governorate",
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedGovernorate = value;
                        selectedWilayat = null;
                      });
                    },
                    items: governorateMap.keys.map((gov) {
                      return DropdownMenuItem(value: gov, child: Text(gov));
                    }).toList(),
                    validator: (value) => value == null ? "Please select a governorate" : null,
                  ),
                  const SizedBox(height: 20),

                  // Wilayat
                  DropdownButtonFormField<String>(
                    value: selectedWilayat,
                    hint: const Text("Select Wilayat"),
                    decoration: InputDecoration(
                      labelText: "Wilayat",
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setState(() => selectedWilayat = value),
                    items: selectedGovernorate == null
                        ? []
                        : governorateMap[selectedGovernorate]!.map((wilayat) {
                      return DropdownMenuItem(value: wilayat, child: Text(wilayat));
                    }).toList(),
                    validator: (value) => value == null ? "Please select a wilayat" : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      hintText: "Enter 8-digit phone starting with 9 or 7",
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Please enter your phone number";
                      if (!_isValidPhone(value)) return "Phone must start with 9 or 7 and be 8 digits";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Gender
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Select Gender", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Male"),
                              value: "Male",
                              groupValue: genderController.text,
                              onChanged: (value) => setState(() => genderController.text = value!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Female"),
                              value: "Female",
                              groupValue: genderController.text,
                              onChanged: (value) => setState(() => genderController.text = value!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updateUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Save Changes", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Reset Password
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordPage())),
              child: Text(
                'Reset Password',
                style: TextStyle(color: isDark ? Colors.blue[200] : Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 40),

            // Logout
            TextButton.icon(
              onPressed: () {
                if (!widget.testIsLoading) {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
