import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  final user = FirebaseAuth.instance.currentUser;
  final DatabaseService dbService = DatabaseService();

  Map<String, dynamic> orders = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
    if (user == null) return;

    final snapshot = await dbService.db.child('orders/${user!.uid}').get();

    if (snapshot.exists && snapshot.value != null) {
      final allOrders = Map<String, dynamic>.from(snapshot.value as Map);

      // ⛔ Hide canceled orders from customer UI
      final filtered = <String, dynamic>{};
      allOrders.forEach((key, value) {
        final order = Map<String, dynamic>.from(value);
        if (order['orderType'] != "Canceled") {
          filtered[key] = order;
        }
      });

      setState(() {
        orders = filtered;
      });
    }
  }


  bool _canCancel(String orderId) {
    if (!orders.containsKey(orderId)) return false;

    final order = Map<String, dynamic>.from(orders[orderId]);

    if (order['status'] == "Canceled") return false;

    final timestampStr = order['orderDate'] as String? ?? '';
    if (timestampStr.isEmpty) return false;

    final orderTime = DateTime.tryParse(timestampStr);
    if (orderTime == null) return false;

    final difference = DateTime.now().difference(orderTime).inHours;
    return difference < 2 && order['status'] == 'Pending';
  }

  void _cancelOrder(String orderId) async {
    try {
      await dbService.db
          .child('orders/${user!.uid}/$orderId/orderType')
          .set('Canceled');

      await dbService.db
          .child('orders/${user!.uid}/$orderId/status')
          .set('Canceled');

      // ❌ Remove from customer UI only (not DB)
      setState(() {
        orders.remove(orderId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Rental canceled successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to cancel rental.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals'),
        backgroundColor: Colors.deepPurple,
      ),
      body: orders.isEmpty
          ? const Center(child: Text('No rentals found.'))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final orderId = orders.keys.elementAt(index);
          final order = Map<String, dynamic>.from(orders[orderId]);
          final items =
          Map<String, dynamic>.from(order['items'] ?? {});
          final status = order['status'] ?? 'Pending';
          final canCancel = _canCancel(orderId);

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: $orderId',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('Status: $status'),
                  const SizedBox(height: 5),
                  Text('Rental Time: ${order['orderDate']}'),
                  const SizedBox(height: 10),

                  // ITEMS LIST
                  Column(
                    children: items.entries.map((entry) {
                      final item =
                      Map<String, dynamic>.from(entry.value);

                      Uint8List? imageBytes;
                      if (item['imageBase64'] != null) {
                        try {
                          imageBytes =
                              base64Decode(item['imageBase64']);
                        } catch (_) {
                          imageBytes = null;
                        }
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: imageBytes != null
                            ? Image.memory(
                          imageBytes,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.checkroom, size: 50),
                        title: Text(item['name'] ?? 'N/A'),
                        subtitle: Text(
                            'Quantity: ${item['quantity']}, Price: ${item['price']}'),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // CANCEL BUTTON OR STATUS
                  if (canCancel)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _cancelOrder(orderId),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Cancel Rental'),
                      ),
                    )
                  else
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Cannot cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
