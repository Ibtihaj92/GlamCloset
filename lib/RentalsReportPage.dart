import 'package:flutter/material.dart';

class RentalsReportPage extends StatelessWidget {
  final List<Map<String, String>> rentalHistory = [
    {
      "id": "R11",
      "item": "Traditional Omani dress",
      "date": "Jan 5-9, 2025",
      "price": "150 OMR",
      "status": "Completed"
    },
    {
      "id": "R12",
      "item": "Traditional Omani dress",
      "date": "Feb 11-12, 2025",
      "price": "100 OMR",
      "status": "Completed"
    },
    {
      "id": "R13",
      "item": "Traditional Omani dress",
      "date": "Apr 1-3, 2025",
      "price": "100 OMR",
      "status": "Canceled"
    },
  ];

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'completed') return Colors.green;
    if (status.toLowerCase() == 'canceled') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    int totalRentals = rentalHistory.length;
    int totalPrice = rentalHistory.fold(0, (sum, item) {
      return sum + int.parse(item['price']!.split(' ')[0]);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.grey.shade100;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final appBarColor = isDark ? Colors.grey.shade900 : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        backgroundColor: appBarColor,
        elevation: 1,
        title: const Text(
          "Rentals Report",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard("Total Rentals", "$totalRentals", cardColor),
                _buildSummaryCard("Total Price", "$totalPrice OMR", cardColor),
                _buildSummaryCard("Item", "Traditional Omani dress", cardColor),
              ],
            ),
            const SizedBox(height: 24),

            // Rental History
            const Text(
              "Rental History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: rentalHistory.length,
                itemBuilder: (context, index) {
                  final rental = rentalHistory[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: cardColor,
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        rental['item']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text("Rental ID: ${rental['id']}"),
                          Text("Dates: ${rental['date']}"),
                          Text("Price: ${rental['price']}"),
                        ],
                      ),
                      trailing: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(rental['status']!).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          rental['status']!,
                          style: TextStyle(
                            color: _getStatusColor(rental['status']!),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Export Buttons
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("Excel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color cardColor) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: cardColor,
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
