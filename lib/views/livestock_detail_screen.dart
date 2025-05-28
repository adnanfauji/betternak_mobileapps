// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../config/config.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import '../models/cart_item.dart';

class LivestockDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String userId;

  const LivestockDetailScreen({
    super.key,
    required this.data,
    required this.userId,
  });

  @override
  State<LivestockDetailScreen> createState() => _LivestockDetailScreenState();
}

class _LivestockDetailScreenState extends State<LivestockDetailScreen> {
  bool _isFavorite = false;

  void openWhatsApp(String phoneNumber, String message) async {
    final url =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    if (await url_launcher.canLaunchUrl(Uri.parse(url))) {
      await url_launcher.launchUrl(
        Uri.parse(url),
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } else {
      throw 'Tidak dapat membuka WhatsApp.';
    }
  }

  Future<void> addToCart(
    BuildContext context,
    String userId,
    String productId,
  ) async {
    final url = Uri.parse('${Config.BASE_URL}/add_to_cart.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'product_id': productId,
          'stock': 1,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Ditambahkan ke keranjang'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTTP Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final url = Uri.parse('${Config.BASE_URL}/check_favorite.php');
    try {
      final response = await http.post(
        url,
        body: {
          'user_id': widget.userId,
          'product_id': widget.data['id'].toString(),
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _isFavorite = body['favorite'] ?? false;
        });
      }
    } catch (e) {
      // optional: bisa log error di debug console
      print('Error checking favorite: $e');
    }
  }

  Future<void> toggleFavorite(String userId, String productId) async {
    final url = Uri.parse('${Config.BASE_URL}/toggle_favorite.php');

    try {
      final response = await http.post(
        url,
        body: {'user_id': userId, 'product_id': productId},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        setState(() {
          _isFavorite = body['favorite'] ?? false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(body['message'])));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HTTP Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final userId = widget.userId;
    final productId = data['id'].toString();

    // Format harga seperti di dashboard
    final priceValue =
        data['price'] is int
            ? (data['price'] as int).toDouble()
            : data['price'] is double
            ? data['price'] as double
            : data['price'] is String
            ? double.tryParse(data['price']) ?? 0
            : 0;
    final priceFormatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(priceValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Ternak'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.shoppingBag, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartScreen(userId: userId)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Gambar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                // Cek apakah URL sudah lengkap atau hanya nama file saja
                data['image'] != null &&
                        data['image'].toString().startsWith('http')
                    ? data['image'].toString()
                    : '${Config.BASE_URL}/uploads/products/${data['image'] ?? ''}',
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Image.asset(
                      'images/default.png',
                      height: 240,
                      fit: BoxFit.cover,
                    ),
              ),
            ),

            const SizedBox(height: 16),
            // Judul, Harga, dan Tombol Favorit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Terjual
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Terjual ${data['sold'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tombol Favorite
                          IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                              size: 28,
                            ),
                            onPressed: () => toggleFavorite(userId, productId),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if ((data['description'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      child: Text(
                        data['description'],
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  Text(
                    priceFormatted,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Lokasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      data['location'] ?? '-',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
            // Bar tombol bawah
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Chat
                  SizedBox(
                    width: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        final phone = data['phone'];
                        if (phone != null && phone.toString().isNotEmpty) {
                          openWhatsApp(
                            phone.toString(),
                            'Halo, saya tertarik dengan ternak ${data['name']} di BetterNak!',
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nomor WhatsApp tidak tersedia.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Icon(
                        Icons.chat,
                        size: 28,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  Container(width: 4, color: Colors.grey.shade300),

                  // Tambah ke Keranjang
                  SizedBox(
                    width: 60,
                    child: ElevatedButton(
                      onPressed: () => addToCart(context, userId, productId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart,
                        size: 28,
                        color: Colors.orange,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Beli Sekarang
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Buat CartItem untuk pembelian langsung
                        final String imageUrl = data['image'] ?? '';
                        final String imageFile =
                            imageUrl.startsWith('http')
                                ? imageUrl.split('/').last
                                : imageUrl;

                        final cartItem = CartItem(
                          id: data['id'].toString(),
                          name: data['name'] ?? '',
                          image: imageFile, // Gunakan hanya nama file
                          productId: data['id'].toString(),
                          quantity: 1,
                          price: priceValue.toString(),
                        );

                        // Hitung total harga untuk pembelian langsung
                        final calculatedTotalPrice =
                            priceValue * 1.0; // price * quantity

                        // Navigasi ke CheckoutScreen dengan satu item
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CheckoutScreen(
                                  userId: userId,
                                  cartItems: [cartItem],
                                  totalPrice:
                                      calculatedTotalPrice, // Pass calculated total price
                                  isBuyNow:
                                      true, // Flag untuk menandai ini pembelian langsung
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Beli Sekarang',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
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
}
