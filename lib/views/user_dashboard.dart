// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'cart_screen.dart';
import 'message_screen.dart';
import 'notification_screen.dart';
import 'my_account_screen.dart';
import 'livestock_detail_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String name;
  final String userId;

  const HomeScreen({super.key, required this.name, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> _ads = [];
  List<String> _categories = [];
  bool _adsLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchAdvertised();
  }

  Future<void> fetchCategories() async {
    try {
      final uri = Uri.parse('${Config.BASE_URL}/get_advertised_livestock.php');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success']) {
          final data = body['data'] as List;
          final types =
              data
                  .map<String>((item) => item['type'] as String)
                  .toSet()
                  .toList();
          setState(() => _categories = types);
        }
      }
    } catch (e) {
      print('Error fetch categories: $e');
    }
  }

  Future<void> fetchAdvertised({String? category}) async {
    setState(() => _adsLoading = true);
    try {
      String url = '${Config.BASE_URL}/get_advertised_livestock.php';
      if (category != null) {
        url += '?type=${Uri.encodeComponent(category)}';
      }

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success']) {
          setState(() {
            _ads = body['data'];
            _selectedCategory = category;
          });
        }
      }
    } catch (e) {
      print('Error fetch ads: $e');
    } finally {
      setState(() => _adsLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessageScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationScreen(userId: widget.userId),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyAccountScreen(userId: widget.userId),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Better-Nak',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.shoppingBag, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.messageCircle),
            label: 'Pesan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Akun',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Cari ternak...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Kategori
            const Text(
              'Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return OutlinedButton(
                    onPressed: () => fetchAdvertised(category: category),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.green : Colors.white,
                      side: BorderSide(
                        color: isSelected ? Colors.green : Colors.amber,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.green,
                      ),
                    ),
                  );
                }),
                if (_selectedCategory != null)
                  OutlinedButton(
                    onPressed: () => fetchAdvertised(category: null),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reset Filter',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Ternak Terkini
            const Text(
              'Ternak Terkini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _adsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _ads.isEmpty
                      ? const Center(
                        child: Text('Belum ada ternak yang diiklankan!'),
                      )
                      : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75, // atur proporsi kartu
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: _ads.length,
                        itemBuilder: (context, i) {
                          final ad = _ads[i];
                          final priceValue =
                              ad['price'] is int
                                  ? (ad['price'] as int).toDouble()
                                  : ad['price'] is double
                                  ? ad['price'] as double
                                  : ad['price'] is String
                                  ? double.tryParse(ad['price']) ?? 0
                                  : 0;
                          final priceFormatted = NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp',
                            decimalDigits: 0,
                          ).format(priceValue);

                          // Cek status ternak (pastikan field status dikirim dari API)
                          final status =
                              ad['status']?.toString().toLowerCase() ?? '';
                          final isSold =
                              status == 'ordered' || status == 'sold';

                          return GestureDetector(
                            onTap:
                                isSold
                                    ? null // Tidak bisa di-tap jika sudah dipesan/terjual
                                    : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => LivestockDetailScreen(
                                                data: ad,
                                                userId:
                                                    widget.userId.toString(),
                                              ),
                                        ),
                                      );
                                    },
                            child: Stack(
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            ad['image'] ?? '',
                                            height: 80,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => Image.asset(
                                                  'images/default.png',
                                                  height: 80,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          ad['name'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          priceFormatted,
                                          style: const TextStyle(
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Terjual ${ad['sold'] ?? 0}',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isSold)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          status == 'ordered'
                                              ? 'Sudah Dipesan'
                                              : 'Terjual',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
