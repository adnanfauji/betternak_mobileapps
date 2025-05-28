import 'package:flutter/material.dart';

class StorePerformanceScreen extends StatelessWidget {
  const StorePerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performa Toko'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PerformanceTile(label: 'Total Produk Terjual', value: '230'),
          PerformanceTile(label: 'Rating Rata-rata', value: '4.8'),
          PerformanceTile(label: 'Jumlah Ulasan', value: '57'),
        ],
      ),
    );
  }
}

class PerformanceTile extends StatelessWidget {
  final String label;
  final String value;

  const PerformanceTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
