import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'payment_screen.dart';

// Model untuk timeline pesanan
class TimelineModel {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final dynamic date;

  TimelineModel({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.date,
  });
}

class TransactionDetailsScreen extends StatefulWidget {
  final String orderId;
  final String userId;
  final bool showActions;

  const TransactionDetailsScreen({
    super.key,
    required this.orderId,
    required this.userId,
    this.showActions = true,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic> orderData = {};
  String errorMessage = '';
  List<Map<String, dynamic>> orderItems = [];

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadTransactionDetails();
  }

  Future<void> _loadTransactionDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '${Config.BASE_URL}/get_transaction_details.php?order_id=${widget.orderId}&user_id=${widget.userId}',
            ),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            orderData = data['order_details'] ?? {};
            orderItems = List<Map<String, dynamic>>.from(
              data['order_items'] ?? [],
            );
          });
        } else {
          setState(() {
            errorMessage =
                data['message'] ?? 'Failed to load transaction details';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTransactionDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
              : _buildTransactionDetails(),
    );
  }

  Widget _buildTransactionDetails() {
    final String orderNumber = orderData['order_number'] ?? 'Unknown';
    final String orderDate = _formatDate(orderData['created_at'] ?? '');
    final String status = orderData['status'] ?? 'pending';
    final double subtotal =
        double.tryParse(orderData['subtotal']?.toString() ?? '0') ?? 0;
    final double shippingCost =
        double.tryParse(orderData['shipping_cost']?.toString() ?? '0') ?? 0;
    final double discount =
        double.tryParse(orderData['discount']?.toString() ?? '0') ?? 0;
    final double totalAmount =
        double.tryParse(orderData['total_amount']?.toString() ?? '0') ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number and date card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #$orderNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      _buildStatusChip(status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tanggal Pesanan: $orderDate',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // Order status timeline
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Pesanan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildOrderTimeline(status),
                ],
              ),
            ),
          ),

          // Product items
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produk yang Dibeli',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ...orderItems.map((item) => _buildOrderItemTile(item)),
                  const Divider(height: 24),
                  _buildPriceSummaryRow('Subtotal', subtotal),
                  const SizedBox(height: 4),
                  _buildPriceSummaryRow('Pengiriman', shippingCost),
                  if (discount > 0) ...[
                    const SizedBox(height: 4),
                    _buildPriceSummaryRow('Diskon', -discount),
                  ],
                  const Divider(height: 24),
                  _buildPriceSummaryRow(
                    'Total',
                    totalAmount,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Shipping details
          if (orderData['shipping_address'] != null)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Pengiriman',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Nama Penerima',
                      orderData['recipient_name'] ??
                          orderData['shipping_address']['name'] ??
                          'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'No. Telepon',
                      orderData['recipient_phone'] ??
                          orderData['shipping_address']['phone'] ??
                          'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Alamat',
                      orderData['shipping_address']['full_address'] ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Kurir',
                      orderData['shipping_method'] ?? 'N/A',
                    ),
                    if (orderData['tracking_number'] != null &&
                        orderData['tracking_number'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow('No. Resi', orderData['tracking_number']),
                    ],
                  ],
                ),
              ),
            ),

          // Payment information
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Metode Pembayaran',
                    _getPaymentMethodName(orderData['payment_method'] ?? 'N/A'),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Status Pembayaran',
                    _getPaymentStatusText(
                      orderData['payment_status'] ?? status,
                    ),
                  ),
                  if (orderData['payment_proof'] != null &&
                      orderData['payment_proof'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Bukti Pembayaran',
                      'Lihat Bukti',
                      isLink: true,
                      onTap: () {
                        _viewPaymentProof(orderData['payment_proof']);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action buttons
          if (widget.showActions) _buildActionButtons(status),
        ],
      ),
    );
  }

  // Buat fungsi untuk mendapatkan nama metode pembayaran lebih manusiawi
  String _getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'bca':
        return 'Transfer Bank BCA';
      case 'bni':
        return 'Transfer Bank BNI';
      case 'bri':
        return 'Transfer Bank BRI';
      case 'mandiri':
        return 'Transfer Bank Mandiri';
      case 'e_wallet':
        return 'E-Wallet';
      case 'gopay':
        return 'GoPay';
      case 'ovo':
        return 'OVO';
      case 'dana':
        return 'DANA';
      case 'virtual_account':
        return 'Virtual Account';
      case 'midtrans':
        return 'Payment Gateway';
      default:
        return method;
    }
  }

  // Buat fungsi untuk mendapatkan teks status pembayaran
  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'paid':
      case 'processing':
      case 'shipped':
      case 'delivered':
      case 'completed':
        return 'Lunas';
      case 'canceled':
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  // Implementasi fungsi untuk melihat bukti pembayaran
  void _viewPaymentProof(String proofUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('Bukti Pembayaran'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Image.network(
                      proofUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, size: 40),
                                const SizedBox(height: 8),
                                Text('Gagal memuat gambar: $error'),
                              ],
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatusChip(String status) {
    status = status.toLowerCase();
    Color chipColor;
    Color textColor = Colors.white;
    String statusText = _getStatusText(status);

    switch (status) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'processing':
      case 'paid':
        chipColor = Colors.blue;
        break;
      case 'shipped':
        chipColor = Colors.purple;
        break;
      case 'completed':
      case 'delivered':
        chipColor = Colors.green;
        break;
      case 'canceled':
      case 'cancelled':
        chipColor = Colors.red;
        textColor = Colors.white;
        break;
      default:
        chipColor = Colors.grey;
        textColor = Colors.black;
    }

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Belum Bayar';
      case 'paid':
        return 'Dibayar';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
      case 'completed':
        return 'Selesai';
      case 'canceled':
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Widget _buildOrderTimeline(String status) {
    status = status.toLowerCase();
    final List<Map<String, dynamic>> steps = [
      {
        'title': 'Pesanan Dibuat',
        'subtitle': 'Menunggu pembayaran',
        'icon': Icons.shopping_bag_outlined,
        'isActive': true,
        'isCompleted': true,
      },
      {
        'title': 'Dibayar',
        'subtitle': 'Pembayaran diterima',
        'icon': Icons.payment,
        'isActive': [
          'paid',
          'processing',
          'shipped',
          'delivered',
          'completed',
        ].contains(status),
        'isCompleted': [
          'paid',
          'processing',
          'shipped',
          'delivered',
          'completed',
        ].contains(status),
      },
      {
        'title': 'Dikemas',
        'subtitle': 'Pesanan sedang dikemas',
        'icon': Icons.inventory,
        'isActive': [
          'processing',
          'shipped',
          'delivered',
          'completed',
        ].contains(status),
        'isCompleted': ['shipped', 'delivered', 'completed'].contains(status),
      },
      {
        'title': 'Dikirim',
        'subtitle': 'Pesanan dalam pengiriman',
        'icon': Icons.local_shipping_outlined,
        'isActive': ['shipped', 'delivered', 'completed'].contains(status),
        'isCompleted': ['delivered', 'completed'].contains(status),
      },
      {
        'title': 'Selesai',
        'subtitle': 'Pesanan telah diterima',
        'icon': Icons.check_circle_outline,
        'isActive': ['delivered', 'completed'].contains(status),
        'isCompleted': ['delivered', 'completed'].contains(status),
      },
    ];

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.2,
            isFirst: index == 0,
            isLast: index == steps.length - 1,
            indicatorStyle: IndicatorStyle(
              width: 30,
              height: 30,
              indicator: _buildTimelineIndicator(
                step['icon'],
                step['isActive'],
                step['isCompleted'],
              ),
              drawGap: true,
            ),
            beforeLineStyle: LineStyle(
              color: step['isActive'] ? Colors.green : Colors.grey.shade300,
              thickness: 2,
            ),
            afterLineStyle: LineStyle(
              color: step['isCompleted'] ? Colors.green : Colors.grey.shade300,
              thickness: 2,
            ),
            endChild: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          step['isActive']
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color: step['isActive'] ? Colors.black : Colors.grey,
                    ),
                  ),
                  if (step['subtitle'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      step['subtitle'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineIndicator(
    IconData icon,
    bool isActive,
    bool isCompleted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCompleted ? Icons.check : icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildOrderItemTile(Map<String, dynamic> item) {
    final String productName = item['product_name'] ?? 'Unknown Product';
    final int quantity = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
    final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
    final double total = price * quantity;
    final String imageUrl = item['image_url'] ?? item['product_image'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                      )
                      : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.inventory_2_outlined),
                      ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: $quantity',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(price),
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryRow(
    String label,
    double amount, {
    TextStyle? textStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textStyle ?? TextStyle(fontSize: 14, color: Colors.grey[800]),
        ),
        Text(currencyFormatter.format(amount), style: textStyle),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    Widget valueWidget = Text(
      value,
      style: TextStyle(
        fontWeight: isLink ? FontWeight.bold : FontWeight.w500,
        color: isLink ? Colors.blue : null,
        decoration: isLink ? TextDecoration.underline : null,
      ),
    );

    if (isLink && onTap != null) {
      valueWidget = GestureDetector(onTap: onTap, child: valueWidget);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(color: Colors.grey[700])),
        ),
        Expanded(child: valueWidget),
      ],
    );
  }

  Widget _buildActionButtons(String status) {
    status = status.toLowerCase();

    if (status == 'pending') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Batalkan'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _payOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Bayar Sekarang'),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'shipped') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton(
          onPressed: _confirmDelivery,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Pesanan Diterima'),
        ),
      );
    } else if (status == 'delivered' || status == 'completed') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _buyAgain,
                icon: const Icon(Icons.refresh),
                label: const Text('Beli Lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _giveReview,
                icon: const Icon(Icons.star_outline),
                label: const Text('Beri Ulasan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default case - no buttons
    return const SizedBox.shrink();
  }

  void _buyAgain() {
    // Implementasi fungsi beli lagi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur "Beli Lagi" akan segera tersedia')),
    );
  }

  void _giveReview() {
    // Implementasi fungsi beri ulasan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur "Beri Ulasan" akan segera tersedia')),
    );
  }

  Future<void> _cancelOrder() async {
    // Tampilkan dialog konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Batalkan Pesanan'),
            content: const Text('Anda yakin ingin membatalkan pesanan ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tidak'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Ya, Batalkan'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/cancel_order.php'),
        body: {'order_id': widget.orderId, 'user_id': widget.userId},
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadTransactionDetails(); // Reload data
      } else {
        throw Exception(data['message'] ?? 'Gagal membatalkan pesanan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _payOrder() async {
    // Navigasi ke halaman pembayaran, pastikan parameter courier dikirim
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentScreen(
              orderId: widget.orderId,
              orderNumber: orderData['order_number'] ?? '',
              totalAmount: orderData['total_amount']?.toString() ?? '0',
              userId: widget.userId,
              courier:
                  orderData['courier'] ??
                  orderData['shipping_method'] ??
                  '', // Perbaikan: kirim courier
            ),
      ),
    );

    if (result == true) {
      await _loadTransactionDetails();
    }
  }

  Future<void> _confirmDelivery() async {
    // Tampilkan dialog konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Penerimaan'),
            content: const Text(
              'Anda yakin telah menerima pesanan ini? Setelah dikonfirmasi, status pesanan tidak dapat diubah.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tidak'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Ya, Pesanan Diterima'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/confirm_delivery.php'),
        body: {'order_id': widget.orderId, 'user_id': widget.userId},
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih! Pesanan telah dikonfirmasi diterima.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadTransactionDetails(); // Reload data
      } else {
        throw Exception(data['message'] ?? 'Gagal mengonfirmasi pesanan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateStr.toString());
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return dateStr.toString();
    }
  }
}
