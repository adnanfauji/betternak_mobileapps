import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final String userId; // Tambahkan parameter userId

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.userId, // Pastikan userId disertakan
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic> orderData = {};
  String errorMessage = '';

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => isLoading = true);

    try {
      // Verifikasi nilai orderId sebelum mengirimkan request
      if (widget.orderId.isEmpty) {
        throw Exception("Order ID tidak valid");
      }

      print(
        'Requesting order details with ID: ${widget.orderId} and user ID: ${widget.userId}',
      );

      // Tambahkan user_id ke parameter request
      final response = await http
          .post(
            Uri.parse('${Config.BASE_URL}/get_order_detail.php'),
            body: {'order_id': widget.orderId, 'user_id': widget.userId},
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout:
                () => throw Exception("Connection timeout. Coba lagi nanti."),
          );

      print('Response status code: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      // Log respons mentah untuk debugging
      if (response.body.isNotEmpty) {
        print('Response length: ${response.body.length} bytes');
        print(
          'Response preview: "${response.body.substring(0, math.min(50, response.body.length))}"',
        );
      } else {
        throw Exception('Server mengembalikan respons kosong');
      }

      // Bersihkan respons dari karakter yang tidak diinginkan
      String cleanedResponse = response.body.trim();

      // Cari tanda awal JSON yang valid
      int jsonStart = cleanedResponse.indexOf('{');
      if (jsonStart > 0) {
        print('Found JSON starting at position $jsonStart');
        cleanedResponse = cleanedResponse.substring(jsonStart);
      } else if (jsonStart < 0) {
        throw Exception(
          'Format data tidak valid: JSON tidak ditemukan dalam respons',
        );
      }

      print('Attempting to decode JSON: ${cleanedResponse.length} chars');

      try {
        final Map<String, dynamic> data = json.decode(cleanedResponse);

        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Gagal memuat detail pesanan');
        }

        if (data['data'] == null || data['data'] is! Map) {
          throw Exception(
            'Data pesanan tidak tersedia atau formatnya tidak valid',
          );
        }

        setState(() {
          orderData = data['data'];
          isLoading = false;
          errorMessage = '';
        });

        print('Order data loaded successfully');
      } catch (jsonError) {
        print('JSON decode error: $jsonError');
        throw Exception(
          'Gagal memproses data dari server. Format respons tidak sesuai.',
        );
      }
    } catch (e) {
      print('Error in _loadOrderDetails: $e');
      setState(() {
        // Buat pesan error lebih user-friendly
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring('Exception: '.length);
        }
        errorMessage = errorMsg;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal Memuat Data Pesanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadOrderDetails,
                        icon: Icon(Icons.refresh),
                        label: Text('Muat Ulang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : _buildOrderDetails(),
    );
  }

  // Implementasi _buildOrderDetails() sama seperti sebelumnya
  Widget _buildOrderDetails() {
    // Kode untuk menampilkan detail pesanan
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informasi Pesanan
          _buildInfoSection('Informasi Pesanan', [
            _buildInfoRow('Nomor Pesanan', orderData['order_number'] ?? '-'),
            _buildInfoRow(
              'Tanggal Pemesanan',
              orderData['order_date'] != null
                  ? _formatDate(orderData['order_date'])
                  : '-',
            ),
            _buildInfoRow(
              'Status',
              _getStatusText(orderData['status'] ?? '-'),
              valueColor: _getStatusColor(orderData['status']),
            ),
          ]),

          // Informasi Pengiriman
          _buildInfoSection('Informasi Pengiriman', [
            _buildInfoRow('Alamat', _getShippingAddress()),
            _buildInfoRow('Kurir', orderData['shipping']?['courier'] ?? '-'),
          ]),

          // Item yang Dibeli
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildOrderItems(),
            ),
          ),

          // Ringkasan Pembayaran
          _buildInfoSection('Ringkasan Pembayaran', [
            _buildInfoRow(
              'Subtotal',
              _formatCurrency(_calculateOrderSubtotal()),
            ),
            _buildInfoRow(
              'Biaya Pengiriman',
              _formatCurrency(orderData['shipping_fee']),
            ),
            const Divider(),
            _buildInfoRow(
              'Total',
              _formatCurrency(
                _calculateOrderSubtotal() +
                    (double.tryParse(
                          orderData['shipping_fee']?.toString() ?? '0',
                        ) ??
                        0),
              ),
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ]),

          // Metode Pembayaran
          _buildInfoSection('Metode Pembayaran', [
            _buildInfoRow('Metode', _formatPaymentMethod()),
            if (orderData['payment_reference'] != null)
              _buildInfoRow(
                'Kode Pembayaran',
                orderData['payment_reference'],
                valueStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<Widget> rows, {
    Widget? customContent,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (customContent != null) customContent else ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style:
                  valueStyle ??
                  TextStyle(fontWeight: FontWeight.w500, color: valueColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    try {
      final items = orderData['items'];

      if (items == null) {
        return Text('Tidak ada informasi item');
      }

      if (items is! List || items.isEmpty) {
        return Text('Tidak ada item dalam pesanan ini');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item yang Dibeli',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final imageUrl = item['image_url'];
              final productName = item['product_name']?.toString() ?? 'Produk';
              final quantity = item['quantity'] ?? 0;
              final price = item['price'];

              // Konversi price ke numeric untuk kalkulasi
              double numericPrice = 0;
              if (price != null) {
                if (price is num) {
                  numericPrice = price.toDouble();
                } else {
                  numericPrice = double.tryParse(price.toString()) ?? 0;
                }
              }

              // Kalkulasi subtotal berdasarkan quantity dan price
              final calculatedSubtotal =
                  numericPrice *
                  (quantity is num
                      ? quantity
                      : int.tryParse(quantity.toString()) ?? 0);

              // Format harga tanpa Rp
              String priceFormatted = _formatPriceWithoutSymbol(price);

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
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child:
                          imageUrl != null && imageUrl.toString().isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: $error');
                                    return Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                ),
                              )
                              : Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$quantity x Rp$priceFormatted',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // Gunakan subtotal yang dikalkulasi, bukan dari API
                            'Rp${_formatPriceWithoutSymbol(calculatedSubtotal)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
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
      );
    } catch (e) {
      print('Error in _buildOrderItems: $e');
      return Text('Gagal menampilkan item pesanan');
    }
  }

  // Fungsi helper
  String _getShippingAddress() {
    final shipping = orderData['shipping'];

    if (shipping == null) return '-';

    if (shipping is Map) {
      final List<String> parts =
          [
                shipping['address'],
                shipping['city'],
                shipping['province'],
                shipping['postal_code'],
              ]
              .where((part) => part != null && part.toString().isNotEmpty)
              .map((e) => e.toString())
              .toList();

      return parts.isEmpty ? '-' : parts.join(', ');
    }

    return shipping.toString();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '-';

    try {
      double amount = 0;
      if (value is String) {
        amount = double.tryParse(value) ?? 0;
      } else if (value is num) {
        amount = value.toDouble();
      }

      // Jika nilai adalah 0, kembalikan dash
      if (amount == 0) return '-';

      return currencyFormatter.format(amount);
    } catch (e) {
      return '-';
    }
  }

  String _formatPaymentMethod() {
    final method = orderData['payment_method'];

    if (method == null) return '-';

    switch (method) {
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'e_wallet':
        return 'E-Wallet';
      case 'virtual_account':
        return 'Virtual Account';
      default:
        return method.toString();
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Belum Bayar';
      case 'paid':
        return 'Sudah Dibayar';
      case 'processing':
        return 'Dikemas';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color? _getStatusColor(String? status) {
    if (status == null) return null;

    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.blue;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return null;
    }
  }

  // Tambahkan fungsi helper baru untuk format harga tanpa simbol mata uang
  String _formatPriceWithoutSymbol(dynamic value) {
    if (value == null) return '0';

    try {
      double amount = 0;
      if (value is String) {
        amount = double.tryParse(value) ?? 0;
      } else if (value is num) {
        amount = value.toDouble();
      }

      // Jika nilai adalah 0, kembalikan 0
      if (amount == 0) return '0';

      // Gunakan NumberFormat yang sama dengan checkout screen
      final formatter = NumberFormat('#,##0', 'id_ID');
      return formatter.format(amount);
    } catch (e) {
      return '0';
    }
  }

  // Tambahkan fungsi ini untuk menghitung total dari semua item
  double _calculateOrderSubtotal() {
    try {
      final items = orderData['items'];
      if (items == null || items is! List || items.isEmpty) {
        return 0;
      }

      double total = 0;
      for (var item in items) {
        // Ambil quantity dan price
        final quantity = item['quantity'] ?? 0;
        final price = item['price'];

        // Konversi ke nilai numerik
        double numericPrice = 0;
        if (price != null) {
          if (price is num) {
            numericPrice = price.toDouble();
          } else {
            numericPrice = double.tryParse(price.toString()) ?? 0;
          }
        }

        // Konversi quantity ke numerik
        int numericQuantity =
            quantity is num
                ? quantity.toInt()
                : int.tryParse(quantity.toString()) ?? 0;

        // Tambahkan subtotal item ke total
        total += numericPrice * numericQuantity;
      }

      return total;
    } catch (e) {
      print('Error calculating subtotal: $e');
      return 0;
    }
  }
}
