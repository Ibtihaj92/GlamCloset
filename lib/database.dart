import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notifications.dart';

class DatabaseService {
  DatabaseReference get db => _database;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ------------------- USER CART -------------------
  Future<List<Map<String, dynamic>>> getUserCart(String userId) async {
    final cartRef = _database.child('users/$userId/cart');
    final snapshot = await cartRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values.map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      return [];
    }
  }

  // ------------------- ORDERS STREAM -------------------
  Stream<Map<dynamic, dynamic>> ordersStream() {
    return _database
        .child('orders')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        return Map<dynamic, dynamic>.from(data);
      } else {
        return {};
      }
    });
  }

  // ------------------- USER METHODS -------------------
  Future<void> saveUserData({
    required String userId,
    required String email,
    required String contactNo,
    required String governorate,
    required String wilayat,
    required String hashedPassword,
    required String gender,
    String userType = 'user',
  }) async {
    try {
      final userReference = _database.child('users').child(userId);
      await userReference.set({
        'email': email,
        'contactNo': contactNo,
        'governorate': governorate,
        'wilayat': wilayat,
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
      final snapshot = await _database.child('users').child(userId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print("❌ Error fetching user data: $e");
      return null;
    }
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final userData = await getUserData(userId);
      return userData != null && userData['userType'] == 'admin';
    } catch (e) {
      print("❌ Error checking if user is admin: $e");
      return false;
    }
  }

  // ------------------- UPLOAD & SAVE PROFILE IMAGE -------------------
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage.ref().child('profile_images/$fileName');
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      await _database.child('users/$userId/profileImage').set(downloadUrl);
      print("✅ Profile image uploaded and URL saved to Realtime Database!");
      return downloadUrl;
    } catch (e) {
      print("❌ Error uploading profile image: $e");
      return null;
    }
  }

  // ------------------- SAVE DRESS DATA -------------------
  Future<void> saveDressData({
    required String dressName,
    required String size,
    required double price,
    required File imageFile,
    required String occasion,
    required int availableCount,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception(
          "User must be logged in to post a dress.");
      final ownerId = currentUser.uid;
      final ownerData = await getUserData(ownerId);

      final String fileName =
          '${DateTime
          .now()
          .millisecondsSinceEpoch}_${dressName.replaceAll(' ', '_')}.jpg';
      final Reference ref = _storage.ref().child('rented_clothes/$fileName');
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      final String newDressId = _database
          .child('rented_clothes')
          .push()
          .key!;

      await _database.child('rented_clothes/$newDressId').set({
        'id': newDressId,
        'name': dressName,
        'size': size,
        'price': price,
        'imageUrl': downloadUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'ownerId': ownerId,
        'ownerEmail': ownerData?['email'] ?? '',
        'ownerPhone': ownerData?['contactNo'] ?? '',
        'ownerGovernorate': ownerData?['governorate'] ?? '',
        'ownerWilayat': ownerData?['wilayat'] ?? '',
        'occasion': occasion,
        'availableCount': availableCount,
        'totalCount': availableCount,
        'available': availableCount > 0,
        'isVisible': true,
      });

      print('✅ Dress data saved successfully with owner info!');
    } catch (e) {
      print('❌ Error saving dress data: $e');
      rethrow;
    }
  }

  // ------------------- COMPLETE PAYMENT -------------------
  Future<void> completePayment({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final DatabaseReference rentedRef = _database.child('rented_clothes');
    final DatabaseReference userCartRef = _database.child('users/$userId/cart');
    final DatabaseReference userOrdersRef = _database.child('orders/$userId');

    try {
      final orderId = "order_${DateTime
          .now()
          .millisecondsSinceEpoch}";
      final String orderDate = DateTime.now().toIso8601String();

      final customerSnapshot = await _database.child('users/$userId').get();
      final customerData = customerSnapshot.exists
          ? Map<String, dynamic>.from(customerSnapshot.value as Map)
          : {};

      final customerEmail = customerData['email'] ?? '';
      final customerPhone = customerData['contactNo'] ?? '';
      final governorate = customerData['governorate'] ?? '';
      final wilayat = customerData['wilayat'] ?? '';

      double totalRental = 0;
      double totalInsurance = 0;

      final Map<String, dynamic> orderData = {
        'userId': userId,
        'orderId': orderId,
        'orderDate': orderDate,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'governorate': governorate,
        'wilayat': wilayat,
        'deliveryTime': 'TBD',
        'insuranceAmount': 0,
        'rentalAmount': 0,
        'status': 'Pending',
        'items': {},
      };

      for (var item in cartItems) {
        final clothId = item['id'];
        final quantity = int.tryParse(item['quantity'].toString()) ?? 1;
        if (clothId == null) continue;

        final clothSnapshot = await rentedRef.child(clothId).get();
        if (!clothSnapshot.exists) continue;

        final clothData = Map<String, dynamic>.from(clothSnapshot.value as Map);

        final ownerId = clothData['userId'] ?? '';
        final ownerData = await getUserData(ownerId);

        final price = clothData['price'] ?? 0;
        totalRental += price * quantity;
        final insurance = 5;
        totalInsurance += insurance;

        final availableCount = clothData['availableCount'] ?? 0;
        await rentedRef.child(clothId).update({
          'availableCount': (availableCount - quantity).clamp(0, 9999),
          'available': (availableCount - quantity) > 0,
        });

        orderData['items'][clothId] = {
          'name': clothData['name'] ?? '',
          'price': price,
          'quantity': quantity,
          'imageBase64': clothData['imageBase64'] ?? '',
          'ownerId': ownerId,
          'ownerEmail': ownerData?['email'] ?? '',
          'ownerPhone': ownerData?['contactNo'] ?? '',
          'ownerGovernorate': ownerData?['governorate'] ?? '',
          'ownerWilayat': ownerData?['wilayat'] ?? '',
        };
      }

      orderData['rentalAmount'] = totalRental;
      orderData['insuranceAmount'] = totalInsurance;

      await userOrdersRef.child(orderId).set(orderData);
      await userCartRef.remove();

      print('✅ Payment complete → Order saved & cart cleared!');
    } catch (e) {
      print('❌ Error during payment processing: $e');
    }
  }

  // ------------------- SEND DELIVERY NOTIFICATION -------------------
  Future<void> sendDeliveryNotification({
    required String ownerId,
    required String clothing,
    required String customerPhone,
    required String governorate,
    required String wilayat,
    String? dressImageBase64,
  }) async {
    try {
      final notificationId = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      final timestamp = DateTime.now().toIso8601String();

      final notificationData = {
        'clothing': clothing,
        'customerPhone': customerPhone,
        'location': "$governorate / $wilayat",
        'status': 'pending',
        'timestamp': timestamp,
      };

      if (dressImageBase64 != null && dressImageBase64.isNotEmpty) {
        notificationData['dressImageBase64'] = dressImageBase64;
      }

      await _database.child('notifications').child(ownerId).child(
          notificationId).set(notificationData);

      print('✅ Delivery notification sent for $clothing to $ownerId');
    } catch (e) {
      print("❌ Error sending delivery notification: $e");
    }
  }
  Future<void> sendReturnNotification({
    required String customerId,
    required String clothing,
    required String renterEmail,
    required String renterPhone,
    required String renterGovernorate,
    required String renterWilayat,
    String? dressImageBase64,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = DateTime.now().toIso8601String();

      final notificationData = {
        'clothing': clothing,
        'renterEmail': renterEmail,
        'renterPhone': renterPhone,
        'renterLocation': "$renterGovernorate / $renterWilayat",
        'status': 'returned',
        'timestamp': timestamp,
      };

      if (dressImageBase64 != null && dressImageBase64.isNotEmpty) {
        notificationData['dressImageBase64'] = dressImageBase64;
      }

      await _database
          .child('customer_notifications')
          .child(customerId)
          .child(notificationId)
          .set(notificationData);

      print('✅ Return notification sent for $clothing to $customerId');
    } catch (e) {
      print("❌ Error sending return notification: $e");
    }
  }

  // Get all notifications for a specific customer
  Future<Map<dynamic, dynamic>> getCustomerNotifications(String customerId) async {
    try {
      final snapshot = await _database.child("customer_notifications").child(customerId).get();
      if (snapshot.exists && snapshot.value != null) {
        return Map<dynamic, dynamic>.from(snapshot.value as Map);
      } else {
        return {};
      }
    } catch (e) {
      print("❌ Error fetching customer notifications: $e");
      return {};
    }
  }

  // Mark a notification as reviewed
  Future<void> markNotificationReviewed(String customerId, String notificationId) async {
    try {
      await _database.child("customer_notifications").child(customerId).child(notificationId).update({
        'status': 'reviewed',
      });
    } catch (e) {
      print("❌ Error updating notification status: $e");
    }
  }



}



// ---------------- STATIC DUMMY CARD ----------------
class DummyPayment {
  static const String cardNumber = "4444333322221111";
  static const String holderName = "Test";
  static const int expiryMonth = 12;
  static const int expiryYear = 2026;
  static const String cvv = "123";

  // Dynamic balance stored inside the app
  static double balance = 200.00;

  // ---------------- VERIFY & CHARGE ----------------
  static Map<String, dynamic> verifyAndCharge({
    required String inputCardNumber,
    required String inputHolderName,
    required int inputExpiryMonth,
    required int inputExpiryYear,
    required String inputCvv,
    required double amount,
  }) {
    // Step 1 — Check card number
    if (inputCardNumber != cardNumber) {
      return {"success": false, "message": "❌ Invalid Card Number"};
    }

    // Step 2 — Verify Card Details
    if (inputHolderName != holderName ||
        inputExpiryMonth != expiryMonth ||
        inputExpiryYear != expiryYear ||
        inputCvv != cvv) {
      return {"success": false, "message": "❌ Wrong card details"};
    }

    // Step 3 — Check Balance
    if (balance < amount) {
      return {"success": false, "message": "❌ Insufficient balance"};
    }

    // Step 4 — Deduct and approve
    balance -= amount;

    return {
      "success": true,
      "message": "✅ Payment successful",
      "newBalance": balance,
    };
  }
}
//-----------------Save Notification Preferences-------------
Future<void> saveNotificationPreferences({
  required bool inApp,
  required bool email,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  await FirebaseDatabase.instance
      .ref('users/$userId/notificationPreferences')
      .set({
    'inApp': inApp,
    'email': email,
  });

  print('✅ Notification preferences saved!');

}

//-------------------








