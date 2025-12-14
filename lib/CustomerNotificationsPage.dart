import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ReportIssue.dart';

class CustomerNotificationsPage extends StatefulWidget {
  @override
  State<CustomerNotificationsPage> createState() => _CustomerNotificationsPageState();
}

class _CustomerNotificationsPageState extends State<CustomerNotificationsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final db = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Center(
          child: Text(
            "User not logged in",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
      );
    }

    final userId = user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Notifications",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: StreamBuilder<DatabaseEvent>(
        stream: db.child("customer_notifications").child(userId).onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Text(
                "No notifications found",
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            );
          }

          final rawData = snapshot.data!.snapshot.value;
          if (rawData == null || rawData is! Map) {
            return Center(
              child: Text(
                "No notifications found",
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            );
          }

          final notificationsMap = Map<dynamic, dynamic>.from(rawData);
          List<MapEntry<dynamic, dynamic>> notificationsList = notificationsMap.entries.toList();

          notificationsList.sort((a, b) {
            final aTime = DateTime.tryParse(a.value["timestamp"] ?? "") ?? DateTime.now();
            final bTime = DateTime.tryParse(b.value["timestamp"] ?? "") ?? DateTime.now();
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notificationsList.length,
            itemBuilder: (context, index) {
              final item = notificationsList[index];
              final notification = Map<String, dynamic>.from(item.value);
              final notificationId = item.key.toString();

              // Check if this is the delivered confirmation notification
              if (notification['type'] == 'delivered_confirmation') {
                return deliveredConfirmationCard(
                  orderId: notification['orderId'],
                  onYes: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportIssuePage(orderId: notification['orderId']),
                      ),
                    );
                  },
                  onNo: () {
                    FirebaseDatabase.instance
                        .ref("notifications/$userId/$notificationId")
                        .remove();
                  },
                );
              }


              return _buildNotificationCard(
                notification,
                notificationId,
                userId,
                isDark,
              );
            },
          );

        },
      ),
    );
  }

  Widget deliveredConfirmationCard({
    required String orderId,
    required VoidCallback onYes,
    required VoidCallback onNo,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Did you receive the dress?",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Is there any issue with it?",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onNo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("No"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onYes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Yes"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }


  Widget _buildNotificationCard(
      Map notification, String notificationId, String userId, bool isDark) {
    final clothingName = notification['clothing'] ?? 'N/A';
    final renterEmail = notification['renterEmail'] ?? 'N/A';
    final renterPhone = notification['renterPhone'] ?? 'N/A';
    final renterLocation = notification['renterLocation'] ?? 'N/A';
    final status = notification['status'] ?? 'pending';
    final imageBase64 = notification['dressImageBase64'] ?? '';

    return Card(
      color: isDark ? Colors.grey[850] : Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey[800]!, Colors.grey[900]!]
                : [Colors.white, Colors.grey[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageBase64.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(imageBase64),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 12),
            Text(
              "Outfit: $clothingName",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? Colors.pink[200] : Colors.deepPurple,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Please return the dress to the nearest Ginakom Office within 2 days",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: isDark ? Colors.blue[200] : Colors.blueGrey),
                SizedBox(width: 6),
                Text(
                  renterPhone,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.location_on, size: 18, color: isDark ? Colors.red[300] : Colors.redAccent),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    renterLocation,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: status == "delivered"
                  ? null
                  : () async {
                await db
                    .child("customer_notifications")
                    .child(userId)
                    .child(notificationId)
                    .update({'status': 'delivered'});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status updated to delivered!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: Icon(Icons.check_circle_outline),
              label: Text(
                "Mark as Returned",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
