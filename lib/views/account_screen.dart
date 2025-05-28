import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:betternak_mobileapps/views/profil_screen.dart';
import '../config/config.dart';
import 'change_password_screen.dart';

class AccountScreen extends StatefulWidget {
  final String userId;

  const AccountScreen({super.key, required this.userId});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool isFingerprintEnabled = true;
  String username = '';
  String email = '';
  String phone = '';
  String profilePicture = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.BASE_URL}/get_users.php?userId=${widget.userId}'),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success']) {
          final data = body['data'];
          setState(() {
            username = data['name'] ?? '';
            email = data['email'] ?? '';
            phone = data['phone'] ?? '';
            profilePicture = data['profile_picture'] ?? '';
          });
        } else {
          print('API Error: ${body['message']}');
        }
      } else {
        print('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Akun',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey[200],
            child: const Text(
              'Akun',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          buildSettingItem(
            title: 'Profil Saya',
            value: '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: widget.userId),
                ),
              );
            },
          ),
          buildSettingItem(
            title: 'Ganti Password',
            value: '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChangePasswordScreen(userId: widget.userId),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi Sidik Jari',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Better_nak tidak menyimpan data Sidik Jari, \nkarena data hanya tersimpan \ndi dalam perangkatmu.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Switch(
                  value: isFingerprintEnabled,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      isFingerprintEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSettingItem({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                if (value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
