import 'package:flutter/material.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  final List<Map<String, dynamic>> orders = const [
    {
      "orderId": "ORD123",
      "dresses": [
        {
          "name": "Sharqayh",
          "image":
          "https://i.pinimg.com/originals/42/ed/48/42ed484e63efb02046bfb7655900bbfe.jpg"
        }
      ],
      "renterEmail": "renter1@example.com",
      "customerEmail": "customer1@example.com",
      "pickupLocation": "Jinakum Office",
      "deliveryTime": "Thursday 7 PM",
      "insuranceAmount": 5,
      "rentalAmount": 20,
      "status": "Pending"
    },
    {
      "orderId": "ORD124",
      "dresses": [
        {
          "name": "Suri",
          "image":
          "https://i.pinimg.com/originals/02/d4/e3/02d4e3f34b0cbb1a13a24db6fa3c25c9.jpg"
        },
        {
          "name": "Sharqayh",
          "image":
          "https://i.pinimg.com/originals/42/ed/48/42ed484e63efb02046bfb7655900bbfe.jpg"
        }
      ],
      "renterEmail": "renter2@example.com",
      "customerEmail": "customer2@example.com",
      "pickupLocation": "Jinakum Office",
      "deliveryTime": "Friday 5 PM",
      "insuranceAmount": 8,
      "rentalAmount": 30,
      "status": "In Progress"
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Returned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.grey.shade100;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[700];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
        title: Text("Admin Orders", style: TextStyle(color: textColor)),
        centerTitle: true,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: cardColor,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                      _getStatusColor(order['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order['status'],
                      style: TextStyle(
                          color: _getStatusColor(order['status']),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Order ID: ${order['orderId']}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor)),
                  Text("Customer: ${order['customerEmail']}",
                      style: TextStyle(color: subtitleColor)),
                  Text("Renter: ${order['renterEmail']}",
                      style: TextStyle(color: subtitleColor)),
                  Text("Pickup Location: ${order['pickupLocation']}",
                      style: TextStyle(color: subtitleColor)),
                  Text("Delivery Time: ${order['deliveryTime']}",
                      style: TextStyle(color: subtitleColor)),
                  Text("Insurance Amount: ${order['insuranceAmount']} OMR",
                      style: TextStyle(color: subtitleColor)),
                  Text("Rental Amount: ${order['rentalAmount']} OMR",
                      style: TextStyle(color: subtitleColor)),
                  const SizedBox(height: 12),
                  const Text("Dresses:",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  for (var dress in order['dresses'])
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            dress['image'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey,
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.white, size: 20),
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(dress['name'],
                              style: TextStyle(color: subtitleColor)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            child: const Text(
                              "Send Delivery Notification",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            child: const Text(
                              "Send Return Notification",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
