// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'select_address_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_screen.dart';

final NumberFormat currencyFormatter = NumberFormat('#,##0', 'id_ID');

class CheckoutScreen extends StatefulWidget {
  final String userId;
  final List<CartItem> cartItems;
  final Map<String, String>? address;
  final double? totalPrice; // Make sure totalPrice is nullable
  final bool isBuyNow;

  const CheckoutScreen({
    super.key,
    required this.userId,
    required this.cartItems,
    this.address,
    this.totalPrice,
    this.isBuyNow = false,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool isLoading = false;
  Map<String, dynamic>? selectedAddress;
  bool isSellerDelivery = false;

  String? selectedCourier;
  final List<Map<String, dynamic>> courierOptions = [
    {'id': 'seller', 'name': 'Pengiriman oleh Penjual'},
    {'id': 'jne', 'name': 'JNE'},
    {'id': 'jnt', 'name': 'J&T Express'},
    {'id': 'sicepat', 'name': 'SiCepat'},
    {'id': 'pos', 'name': 'POS Indonesia'},
    {'id': 'lalamove', 'name': 'Lalamove'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          '${Config.BASE_URL}/get_default_address.php?user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            selectedAddress = {
              'id': data['address']['id'],
              'nama_penerima': data['address']['nama_penerima'],
              'no_hp': data['address']['no_hp'],
              'detail_alamat': data['address']['detail_alamat'],
              'district': data['address']['district_name'],
              'regency': data['address']['regency_name'],
              'province': data['address']['province_name'],
              'postal_code': data['address']['kode_pos'],
            };
          });
        }
      } else {
        throw Exception('Failed to load default address');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading address: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectAddressScreen(userId: widget.userId),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedAddress = result;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih alamat pengiriman')),
      );
      return;
    }

    if (selectedCourier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kurir pengiriman')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final orderData = {
        'user_id': widget.userId,
        'shipping_address_id': selectedAddress!['id'].toString(),
        'courier': selectedCourier,
        'is_seller_delivery': isSellerDelivery ? '1' : '0',
        'subtotal': (widget.totalPrice ?? 0).toStringAsFixed(2),
        'total_amount': ((widget.totalPrice ?? 0) + 10000).toStringAsFixed(2),
        'items':
            widget.cartItems.map((item) {
              return {
                'product_id': item.productId.toString(),
                'quantity': item.quantity.toString(),
                'price': parseHarga(item.price).toString(),
              };
            }).toList(),
      };

      // Log data yang dikirim ke server
      print('Order Data: ${jsonEncode(orderData)}');

      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/create_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      // Log respons dari server
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = await parseJson(response.body);

        // Log data yang di-decode dari respons
        print('Decoded Response Data: $data');

        if (data['success'] == true) {
          if (data.containsKey('order_id') &&
              data.containsKey('order_number')) {
            // Simpan order number dan ID
            final orderId = data['order_id'].toString(); // Convert to string
            final orderNumber = data['order_number'];

            // Buat notifikasi
            await _createNotification(orderId, orderNumber);

            // Kirim notifikasi WhatsApp
            await _sendWhatsAppNotifications(data, orderNumber);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pesanan berhasil dibuat')),
            );

            // Setelah pesanan berhasil dibuat
            _completeCheckout(data);

            Future.delayed(const Duration(seconds: 2), () {
              Navigator.popUntil(context, (route) => route.isFirst);
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Respons tidak lengkap dari server'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: ${data['message']}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Log error jika terjadi exception
      print('Error placing order: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Setelah pesanan berhasil dibuat
  void _completeCheckout(Map<String, dynamic> orderData) {
    final orderId = orderData['order_id']?.toString() ?? '';
    final orderNumber = orderData['order_number']?.toString() ?? '';
    final totalAmount = orderData['total_amount']?.toString() ?? '0';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentScreen(
              orderId: orderId,
              orderNumber: orderNumber,
              totalAmount: totalAmount,
              userId: widget.userId,
              courier: selectedCourier ?? '',
            ),
      ),
    );
  }

  Future<void> _sendWhatsAppNotifications(
    Map<String, dynamic> orderData,
    String orderNumber,
  ) async {
    try {
      // Notifikasi ke pembeli
      final buyerPhone = selectedAddress!['no_hp']?.toString() ?? '';
      if (buyerPhone.isNotEmpty) {
        final buyerMessage =
            'Halo ${selectedAddress!['nama_penerima']}, '
            'Pesanan Anda dengan nomor #$orderNumber telah berhasil dibuat. '
            'Total pembayaran: Rp${currencyFormatter.format(((widget.totalPrice ?? 0) + 10000).toInt())}. '
            'Terima kasih telah berbelanja di BetterNak!';

        await _sendWhatsAppMessage(buyerPhone, buyerMessage);
      }

      // Notifikasi ke penjual (perlu API untuk mendapatkan nomor penjual)
      // Implementasi ini memerlukan endpoint API baru untuk mendapatkan data penjual
      await _notifySellerViaBackend(orderData['order_id'], orderNumber);
    } catch (e) {
      print('Error sending WhatsApp notifications: $e');
    }
  }

  Future<void> _sendWhatsAppMessage(String phone, String message) async {
    // Format nomor telepon (pastikan format internasional)
    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62')) {
      formattedPhone = '62$phone';
    }

    // Buat URL WhatsApp
    final whatsappUrl = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  // Tambahkan fungsi ini
  Future<void> _notifySellerViaBackend(
    String orderId,
    String orderNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/notify_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId}),
      );

      print('Seller notification API response status: ${response.statusCode}');
      print('Seller notification API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = await parseJson(response.body);
        if (data['success'] == true) {
          print('WhatsApp notifications sent via backend');
        } else {
          print('Failed to send notifications: ${data['message']}');
        }
      }
    } catch (e) {
      print('Error notifying via backend: $e');
    }
  }

  // Tambahkan fungsi ini di class _CheckoutScreenState

  Future<void> _createNotification(String orderId, String orderNumber) async {
    try {
      // Buat objek notifikasi
      final notificationData = {
        'user_id': widget.userId,
        'title': 'Pesanan Baru',
        'message':
            'Pesanan #$orderNumber berhasil dibuat. Mohon tunggu konfirmasi dari penjual.',
        'type': 'order_created',
        'reference_id': orderId,
        'is_read': '0',
      };

      print('Creating notification with data: $notificationData');

      // Kirim notifikasi ke server
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/create_notification.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(notificationData),
      );

      print('Notification API response status: ${response.statusCode}');
      print('Notification API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = await parseJson(response.body);
        if (data['success'] == true) {
          print('Notification created successfully');
        } else {
          print('Failed to create notification: ${data["message"]}');
        }
      } else {
        print(
          'Failed to create notification. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Alamat Pengiriman
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Alamat Pengiriman',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: _selectAddress,
                                child: Text(
                                  selectedAddress == null
                                      ? 'Pilih Alamat'
                                      : 'Ubah',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (selectedAddress != null) ...[
                            Text(
                              '${selectedAddress!['nama_penerima']} | ${selectedAddress!['no_hp']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(selectedAddress!['detail_alamat']),
                            const SizedBox(height: 2),
                            Text(
                              '${selectedAddress!['district']}, ${selectedAddress!['regency']}',
                            ),
                            Text(
                              '${selectedAddress!['province']} ${selectedAddress!['postal_code']}',
                            ),
                          ] else
                            const Text(
                              'Belum ada alamat dipilih',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Daftar Produk
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Produk Dipesan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.cartItems.length,
                            itemBuilder: (context, index) {
                              final item = widget.cartItems[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            '${Config.BASE_URL}/uploads/products/${item.image}',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity} x Rp${currencyFormatter.format(parseHarga(item.price))}',
                                          ),
                                          Text(
                                            'Rp${currencyFormatter.format(item.quantity * parseHarga(item.price))}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Metode Pengiriman
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kurir Pengiriman',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (var courier in courierOptions)
                            RadioListTile<String>(
                              title: Text(courier['name']),
                              value: courier['id'],
                              groupValue: selectedCourier,
                              onChanged: (value) {
                                setState(() {
                                  selectedCourier = value;
                                  // Jika memilih pengiriman oleh penjual
                                  if (value == 'seller') {
                                    isSellerDelivery = true;
                                    // Otomatis pilih COD sebagai metode pembayaran
                                    // selectedPaymentMethod = 'cod';
                                  } else {
                                    isSellerDelivery = false;
                                  }
                                });
                              },
                              activeColor: Colors.green,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Ringkasan Pembayaran
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal Produk'),
                              Text(
                                'Rp${currencyFormatter.format((widget.totalPrice ?? 0).toInt())}',
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Biaya Pengiriman'),
                                Text('Rp10.000'),
                              ],
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pembayaran',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Rp${currencyFormatter.format(((widget.totalPrice ?? 0) + 10000).toInt())}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: isLoading ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                  : const Text('Buat Pesanan', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

int parseHarga(dynamic harga) {
  try {
    if (harga is int) return harga;
    if (harga is double) return harga.toInt();

    String hargaStr = harga.toString();
    // Hapus semua karakter non-numerik kecuali titik
    hargaStr = hargaStr.replaceAll(RegExp(r'[^\d.]'), '');

    // Jika ada titik desimal, ambil hanya bagian integer nya
    if (hargaStr.contains('.')) {
      return double.parse(hargaStr).toInt();
    }

    return int.tryParse(hargaStr) ?? 0;
  } catch (e) {
    print('Error parsing harga: $e');
    return 0;
  }
}

Future<Map<String, dynamic>> parseJson(String responseBody) async {
  // Pendekatan sederhana tanpa compute
  return jsonDecode(responseBody) as Map<String, dynamic>;
}
