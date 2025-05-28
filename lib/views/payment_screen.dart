import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'package:intl/intl.dart';
import 'midtrans_payment_screen.dart'; // Tambahkan import ini

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final String totalAmount;
  final String userId;
  final String courier;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    required this.userId,
    required this.courier,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isLoading = false;
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  // Inisialisasi dengan nilai default yang aman
  String cleanedTotalAmount = '0.00';

  @override
  void initState() {
    super.initState();
    _processTotalAmount();

    // Jika courier adalah 'seller', set otomatis metode pembayaran ke COD
    if (widget.courier == 'seller') {
      selectedPaymentMethod = 'cod';
    }
  }

  void _processTotalAmount() {
    try {
      // Membersihkan total amount
      cleanedTotalAmount = _cleanAmount(widget.totalAmount);
    } catch (e) {
      cleanedTotalAmount = '0.00';
    }
  }

  // Pilihan metode pembayaran
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'bank_transfer',
      'name': 'Transfer Bank',
      'icon': Icons.account_balance,
      'banks': [
        {'id': 'bca', 'name': 'BCA'},
        {'id': 'bni', 'name': 'BNI'},
        {'id': 'bri', 'name': 'BRI'},
        {'id': 'mandiri', 'name': 'Mandiri'},
      ],
    },
    {
      'id': 'e_wallet',
      'name': 'E-Wallet',
      'icon': Icons.account_balance_wallet,
      'wallets': [
        {'id': 'gopay', 'name': 'GoPay'},
        {'id': 'ovo', 'name': 'OVO'},
        {'id': 'dana', 'name': 'DANA'},
      ],
    },
    {
      'id': 'virtual_account',
      'name': 'Virtual Account',
      'icon': Icons.credit_card,
    },
  ];

  String? selectedPaymentMethod;
  String? selectedBank;
  String? selectedWallet;

  @override
  Widget build(BuildContext context) {
    final isSellerDelivery = widget.courier == 'seller';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
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
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informasi pesanan
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_bag,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Informasi Pesanan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Nomor Pesanan:'),
                                Text(
                                  '#${widget.orderNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Pembayaran:'),
                                Text(
                                  _formatCurrency(widget.totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Pilihan metode pembayaran
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (isSellerDelivery)
                              // Jika pengiriman oleh penjual, hanya tampilkan COD
                              ListTile(
                                leading: const Icon(
                                  Icons.monetization_on,
                                  color: Colors.green,
                                ),
                                title: const Text('Bayar di Tempat (COD)'),
                                subtitle: const Text(
                                  'Metode pembayaran otomatis untuk pengiriman oleh penjual',
                                ),
                                trailing: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                              )
                            else
                              // Daftar metode pembayaran normal
                              ...paymentMethods.map(
                                (method) => RadioListTile<String>(
                                  title: Row(
                                    children: [
                                      Icon(method['icon'], color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(method['name']),
                                    ],
                                  ),
                                  value: method['id'],
                                  groupValue: selectedPaymentMethod,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPaymentMethod = value;
                                      selectedBank = null;
                                      selectedWallet = null;
                                    });
                                  },
                                  activeColor: Colors.green,
                                ),
                              ),

                            // Subopsi untuk metode pembayaran yang dipilih
                            if (!isSellerDelivery &&
                                selectedPaymentMethod == 'bank_transfer') ...[
                              const Padding(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  top: 8,
                                  bottom: 8,
                                ),
                                child: Text(
                                  'Pilih Bank:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  children:
                                      paymentMethods
                                          .firstWhere(
                                            (m) => m['id'] == 'bank_transfer',
                                          )['banks']
                                          .map<Widget>(
                                            (bank) => RadioListTile<String>(
                                              title: Text(bank['name']),
                                              value: bank['id'],
                                              groupValue: selectedBank,
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedBank = value;
                                                });
                                              },
                                              activeColor: Colors.green,
                                              dense: true,
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ],

                            if (!isSellerDelivery &&
                                selectedPaymentMethod == 'e_wallet') ...[
                              const Padding(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  top: 8,
                                  bottom: 8,
                                ),
                                child: Text(
                                  'Pilih E-Wallet:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  children:
                                      paymentMethods
                                          .firstWhere(
                                            (m) => m['id'] == 'e_wallet',
                                          )['wallets']
                                          .map<Widget>(
                                            (wallet) => RadioListTile<String>(
                                              title: Text(wallet['name']),
                                              value: wallet['id'],
                                              groupValue: selectedWallet,
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedWallet = value;
                                                });
                                              },
                                              activeColor: Colors.green,
                                              dense: true,
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed:
              isLoading ||
                      (isSellerDelivery
                          ? false // COD, tombol tetap aktif
                          : selectedPaymentMethod == null)
                  ? null
                  : () => _processPayment(),
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
                  : const Text(
                    'Lanjutkan Pembayaran',
                    style: TextStyle(fontSize: 16),
                  ),
        ),
      ),
    );
  }

  // Method untuk membersihkan jumlah pembayaran dari karakter non-numerik
  String _cleanAmount(String? amount) {
    try {
      // Cek apakah amount null atau kosong
      if (amount == null || amount.isEmpty) {
        return '0.00';
      }

      // Hapus semua karakter non-numerik kecuali titik desimal
      String cleaned = amount.replaceAll(RegExp(r'[^\d.]'), '');

      // Cek jika string kosong setelah filtering
      if (cleaned.isEmpty) {
        return '0.00';
      }

      // Coba parse sebagai double untuk validasi
      double parsed = double.parse(cleaned);

      // Format dengan 2 desimal untuk API Midtrans
      return parsed.toStringAsFixed(2);
    } catch (e) {
      // Default ke 0 jika terjadi error
      return '0.00';
    }
  }

  String _formatCurrency(String amount) {
    try {
      // Bersihkan amount dari karakter non-numerik
      String cleaned = amount.replaceAll(RegExp(r'[^\d.]'), '');

      // Parse sebagai double
      final doubleValue = double.parse(cleaned);

      // Format sebagai currency
      return currencyFormatter.format(doubleValue);
    } catch (e) {
      return 'Rp0';
    }
  }

  Future<void> _processPayment() async {
    setState(() => isLoading = true);

    try {
      // Validasi input sebelum request
      if (selectedPaymentMethod == 'bank_transfer' && selectedBank == null) {
        throw Exception('Silakan pilih bank terlebih dahulu');
      }
      if (selectedPaymentMethod == 'e_wallet' && selectedWallet == null) {
        throw Exception('Silakan pilih e-wallet terlebih dahulu');
      }

      String paymentMethod = 'midtrans';
      String paymentChannel = '';
      if (selectedPaymentMethod == 'bank_transfer' && selectedBank != null) {
        paymentChannel = selectedBank!;
      } else if (selectedPaymentMethod == 'e_wallet' &&
          selectedWallet != null) {
        paymentChannel = selectedWallet!;
      } else if (selectedPaymentMethod == 'virtual_account') {
        paymentChannel = 'va';
      }

      final Map<String, String> payload = {
        'order_id': widget.orderId,
        'user_id': widget.userId,
        'payment_method': paymentMethod,
        'payment_channel': paymentChannel,
        'amount': cleanedTotalAmount,
      };

      final response = await http
          .post(
            Uri.parse('${Config.BASE_URL}/get_midtrans_token.php'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: payload,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout:
                () => throw Exception('Koneksi timeout. Silakan coba lagi.'),
          );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      String cleanedResponse = response.body.trim();
      if (cleanedResponse.startsWith('\uFEFF')) {
        cleanedResponse = cleanedResponse.substring(1);
      }
      if (cleanedResponse.isNotEmpty &&
          !cleanedResponse.startsWith('{') &&
          !cleanedResponse.startsWith('[')) {
        int jsonStart = cleanedResponse.indexOf('{');
        if (jsonStart >= 0) {
          cleanedResponse = cleanedResponse.substring(jsonStart);
        } else {
          jsonStart = cleanedResponse.indexOf('[');
          if (jsonStart >= 0) {
            cleanedResponse = cleanedResponse.substring(jsonStart);
          }
        }
      }

      Map<String, dynamic> data;
      try {
        data = json.decode(cleanedResponse);
      } catch (e) {
        throw Exception(
          'Gagal memproses respons dari server. Silakan coba lagi.',
        );
      }

      // Validasi respons API
      if (data['success'] == true && data['snap_token'] != null) {
        // Ambil data customer dari response jika ada, atau gunakan default
        final customerName = data['customer_name'] ?? 'Pelanggan';
        final customerEmail = data['customer_email'] ?? 'email@domain.com';
        final customerPhone = data['customer_phone'];

        // Debugging: Cetak informasi sebelum navigasi
        print('Payment channel: $paymentChannel');
        print('Customer name: $customerName');
        print('Snap token: ${data['snap_token']}');

        // Navigasi ke halaman MidtransPaymentScreen
        final paymentResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MidtransPaymentScreen(
                  orderId: widget.orderId,
                  amount: cleanedTotalAmount,
                  customerName: customerName,
                  customerEmail: customerEmail,
                  customerPhone: customerPhone,
                  paymentChannel: paymentChannel, // <-- ini penting
                  userId: widget.userId, // Add this line
                ),
          ),
        );

        // Proses hasil pembayaran
        if (paymentResult == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil diproses'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran tidak berhasil atau dibatalkan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception(
          data['message'] ?? 'Gagal mendapatkan token pembayaran',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
