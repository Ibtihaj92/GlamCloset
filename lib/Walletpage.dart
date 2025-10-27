import 'package:flutter/material.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample static data
    final refundedDeposits = [
      {
        'dressName': 'Baluchi',
        'amount': 20.0,
        'isApproved': true,
      },
      {
        'dressName': 'Alsharqia',
        'amount': 20.0,
        'isApproved': false,
      },
    ];

    final rentedClothes = [
      {'dressName': 'Suri', 'amount': 30.0},
      {'dressName': 'Dhofari', 'amount': 50.0},
    ];

    // Calculate totals safely
    final totalRefunded = refundedDeposits
        .where((d) => (d['isApproved'] as bool) == true)
        .fold<double>(
        0.0, (sum, d) => sum + (d['amount'] as double));
    final totalRental = rentedClothes.fold<double>(
        0.0, (sum, d) => sum + (d['amount'] as double));
    final totalAmount = totalRefunded + totalRental;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Refunded Deposits Section
            const Text(
              'Refunded Deposits (Approved)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Column(
              children: refundedDeposits.map((d) {
                final isApproved = d['isApproved'] as bool;
                return Card(
                  color: isApproved ? Colors.green[50] : Colors.grey[200],
                  child: ListTile(
                    title: Text(d['dressName'] as String),
                    trailing: Text(
                      "${(d['amount'] as double).toStringAsFixed(2)} OMR",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isApproved ? 'Approved' : 'Pending',
                      style: TextStyle(
                          color: isApproved ? Colors.green : Colors.grey),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Rented Clothes Section
            const Text(
              'Rental Earnings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Column(
              children: rentedClothes.map((d) {
                return Card(
                  color: Colors.blue[50],
                  child: ListTile(
                    title: Text(d['dressName'] as String),
                    trailing: Text(
                      "${(d['amount'] as double).toStringAsFixed(2)} OMR",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Total Amount
            Card(
              color: Colors.orange[50],
              child: ListTile(
                title: const Text(
                  'Total Amount',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  "${totalAmount.toStringAsFixed(2)} OMR",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Withdraw Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Example: Withdraw action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Withdraw action tapped')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Withdraw',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
