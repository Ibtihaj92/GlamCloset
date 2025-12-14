import 'dart:convert';
import 'package:flutter/material.dart';
import 'database.dart';
import 'RenterNotificationsPage.dart';
import 'theme_notifier.dart';
import 'package:provider/provider.dart';

class AdminOrdersPage extends StatefulWidget {
  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeNotifier>(context).isDarkMode;
    final backgroundColor = isDark ? Colors.grey[900]! : Colors.grey[50]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Orders Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xf0ffffff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<Map<dynamic, dynamic>>(
        stream: _dbService.ordersStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          final ordersMap = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: ordersMap.entries.map((userEntry) {
              final userId = userEntry.key;
              final userOrdersMap = Map<dynamic, dynamic>.from(userEntry.value);

              return FutureBuilder<List<Widget>>(
                future: _buildUserOrdersList(userOrdersMap, isDark),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(children: userSnapshot.data!);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // Fetch renter info for each item and build order cards
  Future<List<Widget>> _buildUserOrdersList(Map userOrdersMap, bool isDark) async {
    List<Widget> ordersList = [];

    for (var orderEntry in userOrdersMap.entries) {
      final orderId = orderEntry.key;
      final orderData = Map<String, dynamic>.from(orderEntry.value);

      final items = Map<dynamic, dynamic>.from(orderData['items'] ?? {});

      // Populate renter info for each dress
      for (var itemEntry in items.entries) {
        final clothId = itemEntry.key;
        final clothMap = Map<String, dynamic>.from(itemEntry.value);

        final ownerId = clothMap['ownerId'] ?? '';
        if (ownerId.isNotEmpty) {
          final renterData = await _dbService.getUserData(ownerId);
          if (renterData != null) {
            clothMap['renterEmail'] = renterData['email'] ?? '';
            clothMap['renterPhone'] = renterData['contactNo'] ?? '';
            clothMap['renterGovernorate'] = renterData['governorate'] ?? '';
            clothMap['renterWilayat'] = renterData['wilayat'] ?? '';
          }
        }

        orderData['items'][clothId] = clothMap;
      }

      ordersList.add(_buildOrderCard(orderData, isDark));
    }

    return ordersList;
  }

  // -------------------- ORDER CARD --------------------
  Widget _buildOrderCard(Map order, bool isDark) {
    final items = Map<String, dynamic>.from(order['items'] ?? {});
    final rentalAmount = order['rentalAmount'] ?? 0.0;
    final insuranceAmount = order['insuranceAmount'] ?? 0.0;
    final totalPrice = rentalAmount + insuranceAmount;
    final status = order['status'] ?? 'Unknown';
    final totalItems = items.length;
    final totalQuantity = items.values.fold<int>(
        0, (sum, item) => sum + ((item['quantity'] ?? 0) as int));

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey.shade800, Colors.grey.shade700]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${order['orderId']}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'Pending'
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Pending'
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 12),
            Text(
              "Total Price: ${totalPrice.toStringAsFixed(2)} OMR",
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue),
            ),
            Text(
              "Items: $totalItems | Quantity: $totalQuantity",
              style: TextStyle(color: Colors.grey.shade700),
            ),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),

            // Customer Info
            const Text(
              "Customer Info",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text("📧 ${order['customerEmail']}"),
            Text("📞 ${order['customerPhone']}"),
            Text("📍 ${order['governorate']} / ${order['wilayat']}"),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Dresses List
            ...items.entries.map((entry) {
              final cloth = Map<String, dynamic>.from(entry.value);
              return _buildDressCard(cloth, order, isDark);
            }).toList(),
          ],
        ),
      ),
    );
  }

  // -------------------- DRESS CARD --------------------
  Widget _buildDressCard(Map cloth, Map order, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: cloth["imageBase64"] != null && cloth["imageBase64"].isNotEmpty
                    ? Image.memory(
                  base64Decode(cloth["imageBase64"]),
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: 80,
                  width: 80,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cloth["name"] ?? "Unknown Dress",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text("💰 ${cloth['price']} OMR"),
                    Text("📦 Qty: ${cloth['quantity']}"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),

          const Text(
            "Renter Info",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text("📧 ${cloth['renterEmail'] ?? 'N/A'}"),
          Text("📞 ${cloth['renterPhone'] ?? 'N/A'}"),
          if (cloth['renterGovernorate'] != null)
            Text(
                "📍 ${cloth['renterGovernorate'] ?? ''} / ${cloth['renterWilayat'] ?? ''}"),

          const SizedBox(height: 12),

          // -------------------- SEND DELIVERY NOTIFICATION BUTTON --------------------
          ElevatedButton.icon(
            onPressed: () async {
              final ownerId = cloth['ownerId'] ?? '';
              if (ownerId.isEmpty) return;

              await _dbService.sendDeliveryNotification(
                ownerId: ownerId,
                clothing: cloth['name'] ?? '',
                customerPhone: order['customerPhone'] ?? '',
                governorate: order['governorate'] ?? '',
                wilayat: order['wilayat'] ?? '',
                dressImageBase64: cloth['imageBase64'] ?? '',
              );

              final renterId = ownerId;
              final clothId = cloth['id'] ?? cloth['clothId'] ?? '';
              if (clothId.isNotEmpty) {
                await _dbService.db
                    .child("user_rented_clothes")
                    .child(renterId)
                    .child(clothId)
                    .set({
                  "clothId": clothId,
                  "name": cloth["name"] ?? "",
                  "price": cloth["price"] ?? 0,
                  "imageBase64": cloth["imageBase64"] ?? "",
                  "quantity": cloth["quantity"] ?? 1,
                  "status": "rented",
                  "rentDate": DateTime.now().toIso8601String(),
                  "customerPhone": order['customerPhone'] ?? "",
                  "customerGovernorate": order['governorate'] ?? "",
                  "customerWilayat": order['wilayat'] ?? "",
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delivery notification sent!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.notifications_active),
            label: const Text("Send Delivery Notification"),
          ),

          // -------------------- RETURN DRESS BUTTON --------------------
          ElevatedButton.icon(
            onPressed: () async {
              final ownerId = cloth['ownerId'] ?? '';
              if (ownerId.isEmpty) return;

              await _dbService.sendReturnNotification(
                customerId: ownerId,
                clothing: cloth['name'] ?? '',
                renterEmail: cloth['renterEmail'] ?? '',
                renterPhone: cloth['renterPhone'] ?? '',
                renterGovernorate: cloth['renterGovernorate'] ?? '',
                renterWilayat: cloth['renterWilayat'] ?? '',
                dressImageBase64: cloth['imageBase64'] ?? '',
              );

              final clothId = cloth['id'] ?? cloth['clothId'] ?? '';
              if (clothId.isNotEmpty) {
                await _dbService.db
                    .child("user_rented_clothes")
                    .child(ownerId)
                    .child(clothId)
                    .update({
                  "status": "returned",
                  "returnDate": DateTime.now().toIso8601String(),
                });
              }

              final customerId = (order['userId'] ?? '').toString();
              if (customerId.isNotEmpty) {
                await _dbService.sendReturnNotification(
                  customerId: customerId,
                  clothing: cloth['name'] ?? '',
                  renterEmail: cloth['renterEmail'] ?? '',
                  renterPhone: cloth['renterPhone'] ?? '',
                  renterGovernorate: cloth['renterGovernorate'] ?? '',
                  renterWilayat: cloth['renterWilayat'] ?? '',
                  dressImageBase64: cloth['imageBase64'] ?? '',
                );
              } else {
                print(
                    "⚠️ order['userId'] is empty — return notification not sent to customer.");
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Return notification sent!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.keyboard_return),
            label: const Text("Return Dress"),
          ),
        ],
      ),
    );
  }
}
