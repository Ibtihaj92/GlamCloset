import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ------------------- User Methods -------------------
  Future<void> saveUserData({
    required String userId,
    required String email,
    required String contactNo,
    required String city,
    required String hashedPassword,
    String userType = 'user',
  }) async {
    try {
      final userReference = _database.child('users').child(userId);

      await userReference.set({
        'email': email,
        'contactNo': contactNo,
        'city': city,
        'password': hashedPassword,
        'userType': userType,

      });

      print("✅ User data saved successfully!");
    } catch (e) {
      print("❌ Error saving user data: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userReference = _database.child('users').child(userId);
      final snapshot = await userReference.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        print("⚠️ User data not found.");
        return null;
      }
    } catch (e) {
      print("❌ Error retrieving user data: $e");
      return null;
    }
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final userData = await getUserData(userId);
      if (userData != null) {
        return userData['userType'] == 'admin';
      }
      return false;
    } catch (e) {
      print("❌ Error checking if user is admin: $e");
      return false;
    }
  }

  // ------------------- Save Dress Data -------------------
  Future<void> saveDressData({
    required String dressName,
    required String size,
    required String ageRange,
    required double price,
    required File imageFile,
    required String occasion,
    required int availableCount,
  }) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${dressName.replaceAll(' ', '_')}.jpg';

      final Reference ref = _storage.ref().child('rented_clothes/$fileName');
      final UploadTask uploadTask = ref.putFile(imageFile);

      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      final String newDressId = _database.child('rented_clothes').push().key!;
      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      await _database.child('rented_clothes/$newDressId').set({
        'id': newDressId,
        'name': dressName,
        'size': size,
        'ageRange': ageRange,
        'price': price,
        'imageUrl': downloadUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'ownerId': currentUserId,
        'occasion': occasion,
        'availableCount': availableCount,
        'totalCount': availableCount,
        'available': availableCount > 0,
        'isVisible': true,


      });

      print('✅ Dress data saved successfully!');
    } catch (e) {
      print('❌ Error saving dress data: $e');
      rethrow;
    }
  }

  // ------------------- Update Dress Data -------------------
  Future<void> updateDressData({
    required String dressId,
    String? dressName,
    String? size,
    String? ageRange,
    double? price,
    String? occasion,
    File? newImageFile,
    int ? availableCount
  }) async {
    try {
      final dressRef = _database.child('rented_clothes/$dressId');
      final Map<String, dynamic> updates = {};

      if (dressName != null) updates['name'] = dressName;
      if (size != null) updates['size'] = size;
      if (ageRange != null) updates['ageRange'] = ageRange;
      if (price != null) updates['price'] = price;
      if (occasion != null) updates['occasion'] = occasion;
      if (availableCount != null) updates['availableCount'] = availableCount;

      if (newImageFile != null) {
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${dressName ?? 'dress'}.jpg';
        final Reference ref =
        _storage.ref().child('rented_clothes/$fileName');
        final UploadTask uploadTask = ref.putFile(newImageFile);
        final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        final String newImageUrl = await snapshot.ref.getDownloadURL();
        updates['imageUrl'] = newImageUrl;
      }



      await dressRef.update(updates);
      print('✅ Dress data updated successfully!');
    } catch (e) {
      print('❌ Error updating dress data: $e');
    }
  }

  // ------------------- Get User Cart -------------------
  Future<List<Map<String, dynamic>>> getUserCart(String userId) async {
    final cartRef = _database.child('users/$userId/cart');
    final snapshot = await cartRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      return [];
    }
  }


  // ------------------- Complete Payment -------------------
  Future<void> completePayment({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final DatabaseReference rentedRef =
    FirebaseDatabase.instance.ref('rented_clothes');
    final DatabaseReference userCartRef =
    FirebaseDatabase.instance.ref('users/$userId/cart');

    try {
      for (var item in cartItems) {
        final clothId = item['id'];
        final quantity = (item['quantity'] is int)
            ? item['quantity']
            : int.tryParse(item['quantity'].toString()) ?? 1;

        if (clothId == null) continue;

        final clothSnapshot = await rentedRef.child(clothId).get();
        if (clothSnapshot.exists) {
          final clothData =
          Map<String, dynamic>.from(clothSnapshot.value as Map);

          int availableCount =
              clothData['availableCount'] ?? clothData['totalCount'] ?? 0;

          if (availableCount > 0) {
            final newAvailableCount = availableCount - quantity;

            await rentedRef.child(clothId).update({
              'availableCount': newAvailableCount < 0 ? 0 : newAvailableCount,
              'available': newAvailableCount > 0,
            });

            print(
                '🟢 Updated $clothId: availableCount = $newAvailableCount (rented $quantity)');
          } else {
            print('⚠️ $clothId is already out of stock.');
          }
        } else {
          print('⚠️ Cloth ID $clothId not found in rented_clothes.');
        }
      }

      // ✅ Finally, clear the user's cart after payment
      await userCartRef.remove();
      print('✅ Payment complete, cart cleared, and stock updated!');
    } catch (e) {
      print('❌ Error during payment processing: $e');
    }
  }
}


