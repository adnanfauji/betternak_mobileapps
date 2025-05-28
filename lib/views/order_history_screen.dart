// ignore_for_file: library_prefixes

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'package:intl/intl.dart';
import 'order_detail_screen.dart';
import 'dart:math' as Math;
import 'payment_screen.dart'; // Sesuaikan dengan path yang benar

class OrderHistoryScreen extends StatefulWidget {
  final String userId;
  final int initialTabIndex;

  const OrderHistoryScreen({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5, // Jumlah tab
      vsync: this,
      initialIndex: widget.initialTabIndex, // Setel tab awal
    );
    fetchOrders();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);

    try {
      // Tambahkan log untuk debugging
      print('Fetching orders for user: ${widget.userId}');

      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/get_user_orders.php'),
        body: {'user_id': widget.userId},
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Tambahkan preview respons untuk debugging
        print(
          'Response preview: ${response.body.substring(0, Math.min(100, response.body.length))}',
        );

        final data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            orders = List<Map<String, dynamic>>.from(data['data']);
          });
          print('Orders fetched: ${orders.length}');
        } else {
          print('Error message from API: ${data['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Gagal memuat data pesanan'),
            ),
          );
        }
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading orders: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filterOrdersByStatus(String status) {
    if (status == 'all') {
      return orders;
    }
    return orders.where((order) => order['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Pesanan',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Belum Bayar'),
            Tab(text: 'Dikemas'),
            Tab(text: 'Dikirim'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('all'),
          _buildOrderList('pending'),
          _buildOrderList('processing'),
          _buildOrderList('shipped'),
          _buildOrderList('delivered'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredOrders = _filterOrdersByStatus(status);

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/empty-cart-icon.png', height: 120, width: 120),
            const SizedBox(height: 16),
            const Text(
              'Belum ada pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pesanan Anda akan muncul di sini',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];

          // Format tanggal - gunakan created_at karena order_date tidak tersedia
          String formattedDate = 'N/A';
          if (order['created_at'] != null) {
            try {
              final dateTime = DateTime.parse(order['created_at']);
              formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
            } catch (e) {
              formattedDate = order['created_at'].toString();
            }
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                // Cek validitas ID pesanan
                if (order['order_id'] == null) {
                  print('Invalid order ID: ${order['order_id']}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ID pesanan tidak valid'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Log untuk debugging
                print(
                  'Navigating to order details with ID: ${order['order_id']}',
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => OrderDetailScreen(
                          orderId:
                              order['order_id']?.toString() ??
                              '', // Gunakan order_id, bukan id
                          userId: widget.userId,
                        ),
                  ),
                ).then((_) => fetchOrders()); // Refresh setelah kembali
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Order ID and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order['order_number'] ?? '-'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        _buildStatusChip(order['status'] ?? 'unknown'),
                      ],
                    ),
                    const Divider(),

                    // Order date
                    Text(
                      'Tanggal: $formattedDate',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // Total amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Pembayaran:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          currencyFormatter.format(
                            double.tryParse(
                                  order['total_amount']?.toString() ?? '0',
                                ) ??
                                0,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Action buttons based on status
                    _buildActionButtons(order),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case 'pending':
        chipColor = Colors.orange;
        statusText = 'Belum Bayar';
        break;
      case 'paid':
        chipColor = Colors.blue;
        statusText = 'Sudah Dibayar';
        break;
      case 'processing':
        chipColor = Colors.amber;
        statusText = 'Dikemas';
        break;
      case 'shipped':
        chipColor = Colors.indigo;
        statusText = 'Dikirim';
        break;
      case 'delivered':
        chipColor = Colors.green;
        statusText = 'Selesai';
        break;
      case 'cancelled':
        chipColor = Colors.red;
        statusText = 'Dibatalkan';
        break;
      default:
        chipColor = Colors.grey;
        statusText = status;
    }

    return Chip(
      label: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // Widget untuk membangun tombol aksi berdasarkan status pesanan
  Widget _buildActionButtons(Map<String, dynamic> order) {
    final status = order['status']?.toLowerCase();

    if (status == 'pending') {
      // Status pending menampilkan tombol batalkan dan bayar
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => _cancelOrder(order),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Batalkan'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _payOrder(order), // Tambahkan fungsi _payOrder
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bayar Sekarang'),
          ),
        ],
      );
    } else if (status == 'paid' || status == 'processing') {
      // Status paid atau processing hanya menampilkan tombol batalkan
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => _cancelOrder(order),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Batalkan Pesanan'),
          ),
        ],
      );
    } else if (status == 'shipped') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              // Mark as received logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terima Pesanan'),
          ),
        ],
      );
    } else if (status == 'delivered') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              // Review logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Beri Penilaian'),
          ),
        ],
      );
    }

    // Default, tidak ada tombol
    return const SizedBox.shrink();
  }

  // Metode untuk membatalkan pesanan
  Future<void> _cancelOrder(Map<String, dynamic> orderData) async {
    // Dapatkan informasi penting dari pesanan
    final orderNumber = orderData['order_number'] ?? 'Unknown';
    final status = orderData['status']?.toLowerCase() ?? 'unknown';
    final statusText = _getStatusText(status);

    // Tampilkan dialog konfirmasi dengan informasi lengkap
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Pembatalan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anda akan membatalkan pesanan #$orderNumber.'),
                const SizedBox(height: 8),
                Text('Status saat ini: $statusText'),
                const SizedBox(height: 12),
                const Text(
                  'Pesanan yang sudah dibatalkan tidak dapat dikembalikan. Lanjutkan?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Kembali',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Batalkan'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      // Tampilkan loading indicator
      setState(() => isLoading = true);

      try {
        print('Cancelling order ID: ${orderData['order_id']}');

        final response = await http
            .post(
              Uri.parse('${Config.BASE_URL}/cancel_order.php'),
              body: {
                'order_id': orderData['order_id'].toString(),
                'user_id': widget.userId,
              },
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
              },
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout:
                  () => throw Exception('Koneksi timeout, coba lagi nanti'),
            );

        print('Cancel order response: ${response.statusCode}');
        print('Cancel order body: ${response.body}');

        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pesanan #$orderNumber berhasil dibatalkan'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Muat ulang daftar pesanan
          await fetchOrders();
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal membatalkan pesanan',
          );
        }
      } catch (e) {
        // Tampilkan pesan error jika gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // Matikan loading state
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  // 4. Fungsi utilitas untuk mendapatkan teks status yang dibaca manusia
  String _getStatusText(String status) {
    switch (status) {
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

  // 3. Ganti implementasi _payOrder dengan kode ini
  Future<void> _payOrder(Map<String, dynamic> order) async {
    // Dapatkan informasi penting dari pesanan
    final orderNumber = order['order_number'] ?? 'Unknown';
    final orderId = order['order_id']?.toString() ?? '';
    final totalAmount = order['total_amount']?.toString() ?? '0';

    // Log untuk debugging
    print(
      'Redirecting to payment for order: $orderNumber, amount: $totalAmount',
    );

    // Navigasi ke PaymentScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentScreen(
              orderId: orderId,
              orderNumber: orderNumber,
              totalAmount: totalAmount,
              userId: widget.userId,
              courier:
                  order['courier'] ??
                  '', // Pastikan field 'courier' ada di order
            ),
      ),
    );

    // Jika pembayaran berhasil (result == true), refresh daftar pesanan
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pembayaran untuk pesanan #$orderNumber berhasil diproses',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      await fetchOrders();
    }
  }
}
