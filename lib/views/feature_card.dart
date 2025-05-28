import 'package:betternak_mobileapps/views/my_livestock_screen.dart';
import 'package:flutter/material.dart';
import 'package:betternak_mobileapps/views/finance_screen.dart';
import 'package:betternak_mobileapps/views/store_performance_screen.dart';

class FeatureCard extends StatelessWidget {
  final String sellerId;

  const FeatureCard({super.key, required this.sellerId});

  Widget buildFeatureItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildFeatureItem(
              icon: Icons.inventory_2,
              title: "Tambah Ternak",
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MyLivestockScreen(
                          currentUserId: int.parse(sellerId),
                        ),
                  ),
                );
              },
            ),
            buildFeatureItem(
              icon: Icons.account_balance_wallet,
              title: "Keuangan",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FinanceScreen(),
                  ),
                );
              },
            ),
            buildFeatureItem(
              icon: Icons.bar_chart,
              title: "Performa Toko",
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StorePerformanceScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
