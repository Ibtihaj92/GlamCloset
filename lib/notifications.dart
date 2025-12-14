import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'database.dart';

class NotificationService {
  final db = FirebaseDatabase.instance.ref();

  /// Send notification to a user (in-app and via email if enabled)
  Future<void> sendNotification({
    required String userId,
    required String email,
    required Map<String, dynamic> data,
    required bool inAppEnabled,
    required bool emailEnabled,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    data['timestamp'] = timestamp;
    data['status'] ??= 'pending';

    // --- 1. In-App Notification ---
    if (inAppEnabled) {
      // determine path based on type (customer or renter)
      String node = data['userType'] == 'renter'
          ? 'renter_notifications'
          : 'customer_notifications';

      await db.child(node).child(userId).push().set(data);
    }

    // --- 2. Email Notification ---
    if (emailEnabled) {
      if (data['status'] == 'returned') {
        await _sendReturnEmailNotification(email: email, data: data);
      } else {
        await _sendEmailNotification(email: email, data: data);
      }
    }

  }

  Future<void> _sendEmailNotification({
    required String email,
    required Map<String, dynamic> data,
  }) async {
    // EmailJS HTTP API
    final serviceId = 'service_y82d14r';
    final templateId = 'template_eozgyqi';
    final publicKey = 'ybXdQIW0yCMOnc88u';

    final body = {
      "service_id": serviceId,
      "template_id": templateId,
      "user_id": publicKey,
      "template_params": {
        "to_email": email,
        "clothing": data['clothing'] ?? '',
        "phone": data['customerPhone'] ?? data['renterPhone'] ?? '',
        "location": data['location'] ?? data['renterLocation'] ?? '',
        "status": data['status'],
      }
    };

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('✅ Email sent to $email');
    } else {
      print('❌ Email failed: ${response.body}');
    }
  }
}
Future<void> _sendReturnEmailNotification({
  required String email, // renterEmail
  required Map<String, dynamic> data,
}) async {

  // EmailJS HTTP API
  final serviceId = 'service_y82d14rr';
  final templateId = 'template_e747uur';
  final publicKey = 'ybXdQIW0yCMOnc88u';

  final body = {
    "service_id": serviceId,
    "template_id": templateId,
    "user_id": publicKey,
    "template_params": {
      "to_email": email,
      "clothing_name": data['clothing'] ?? '',
      "customer_phone": data['renterPhone'] ?? '',
      "governorate": data['renterGovernorate'] ?? '',
      "wilayat": data['renterWilayat'] ?? '',
      "dressImageBase64": data['dressImageBase64'] ?? '',
      "status": "returned",
    }
  };


  final response = await http.post(
    Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    print('✅ Return Email sent to $email');
  } else {
    print('❌ Return Email failed: ${response.body}');
  }
}


