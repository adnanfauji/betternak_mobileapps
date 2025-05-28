import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          FinanceCard(title: 'Total Penjualan', value: 'Rp 12.000.000'),
          FinanceCard(title: 'Saldo Tersedia', value: 'Rp 3.500.000'),
          FinanceCard(title: 'Penarikan Tertunda', value: 'Rp 1.200.000'),
        ],
      ),
    );
  }
}

class FinanceCard extends StatelessWidget {
  final String title;
  final String value;

  const FinanceCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
