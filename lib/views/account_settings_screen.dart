import 'package:betternak_mobileapps/views/address_screen.dart';
import 'package:flutter/material.dart';
import 'package:betternak_mobileapps/views/account_screen.dart';

import 'bank_account_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  final String currentUsername;
  final String userId;

  const AccountSettingsScreen({
    super.key,
    required this.currentUsername,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan Akun',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
            onPressed: () {
              // Navigasi ke bantuan
            },
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey[200],
            child: const Text(
              'Akun Saya',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          buildSettingItem(
            title: 'Akun ($currentUsername)',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountScreen(userId: userId),
                ),
              );
            },
          ),
          buildSettingItem(
            title: 'Alamat Saya',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddressScreen(userId: userId),
                ),
              );
            },
          ),
          buildSettingItem(
            title: 'Kartu / Rekening Bank',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BankAccountScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildSettingItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
