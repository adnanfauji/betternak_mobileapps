import 'package:flutter/material.dart';

class OrderStatusCard extends StatelessWidget {
  final String sellerId;

  const OrderStatusCard({super.key, required this.sellerId});

  Widget buildStatusItem(String title, int count) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$count",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Gantikan angka 0 dengan data dari API jika sudah terhubung
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Status Pesanan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Arahkan ke halaman Riwayat Penjualan
                  },
                  child: const Text(
                    "Riwayat Penjualan",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildStatusItem("Perlu Dikirim", 0),
                buildStatusItem("Pembatalan", 0),
                buildStatusItem("Pengembalian", 0),
                buildStatusItem("Penilaian Perlu Dibalas", 0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
