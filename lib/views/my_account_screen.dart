// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/config.dart';
import 'cart_screen.dart';
import 'account_settings_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'order_history_screen.dart';

class MyAccountScreen extends StatefulWidget {
  final String userId;
  final String? initialProfilePicture;

  const MyAccountScreen({
    super.key,
    required this.userId,
    this.initialProfilePicture,
  });

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  String? userName;
  String? userRole;
  String? userProfilePicture;
  bool isLoading = false;
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    userProfilePicture = widget.initialProfilePicture;
    _loadUserData();
    fetchOrders();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/get_users.php'),
        body: {'userId': widget.userId},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("DATA: $responseData"); // DEBUG

        if (responseData['success']) {
          setState(() {
            userName = responseData['data']['name'];
            userRole = responseData['data']['role'];

            if (userProfilePicture == null || userProfilePicture!.isEmpty) {
              userProfilePicture = responseData['data']['profile_picture'];
            }
          });
        } else {
          throw Exception('User data not found or failed to load.');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.BASE_URL}/upload_profile_picture.php'),
      );
      request.fields['userId'] = widget.userId;
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          File(pickedFile.path).path,
        ),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final result = json.decode(responseBody);

        if (result['success']) {
          setState(() {
            userProfilePicture = result['filename'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diunggah')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload gagal: ${result['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal upload foto profil')),
        );
      }
    }
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/get_user_orders.php'),
        body: {'user_id': widget.userId}, // Mengirim userId ke API
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            orders = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Gagal memuat data pesanan'),
            ),
          );
        }
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Akun Saya',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AccountSettingsScreen(
                        userId: widget.userId,
                        currentUsername: userName ?? 'Loading...',
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.shoppingBag, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Profil
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Colors.green),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        userProfilePicture != null
                            ? NetworkImage(
                              '${Config.BASE_URL}/${userProfilePicture}',
                            )
                            : const AssetImage('images/user.png')
                                as ImageProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            userName ?? 'Loading...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Chip(
                            label: Text(
                              userRole ?? 'Loading...',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Text(
                            '42 Pengikut',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '48 Mengikuti',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pesanan Saya
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pesanan Saya',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/orderHistory',
                      arguments: widget.userId,
                    );
                  },
                  child: const Text(
                    'Lihat Riwayat Pesanan >',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Menu Status Pesanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _orderStatusItem('Belum Bayar', Icons.payment, 1), // Tab ke-1
              _orderStatusItem('Dikemas', Icons.inventory, 2), // Tab ke-2
              _orderStatusItem('Dikirim', Icons.local_shipping, 3), // Tab ke-3
              _orderStatusItem(
                'Beri Penilaian',
                Icons.star_border,
                4,
              ), // Tab ke-4
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderStatusItem(String title, IconData icon, int statusIndex) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => OrderHistoryScreen(
                  userId: widget.userId,
                  initialTabIndex: statusIndex, // Kirim indeks tab
                ),
          ),
        );
      },
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.black54),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
