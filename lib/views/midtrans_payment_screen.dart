import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'dart:async';
import '../config/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MidtransPaymentScreen extends StatefulWidget {
  final String orderId;
  final String amount;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String paymentChannel;
  final String userId;

  const MidtransPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.paymentChannel,
    required this.userId,
  });

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  bool isLoading = true;
  String statusMessage = "Mempersiapkan pembayaran...";
  bool hasError = false;
  MidtransSDK? midtransSDK;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _initMidtransSDK);
  }

  @override
  void dispose() {
    midtransSDK?.removeTransactionFinishedCallback();
    super.dispose();
  }

  Future<void> _initMidtransSDK() async {
    try {
      midtransSDK = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: "SB-Mid-client-46iHJXDagEf2qFQB",
          merchantBaseUrl: "${Config.BASE_URL}/",
          enableLog: true,
          colorTheme: ColorTheme(
            colorPrimary: Colors.green,
            colorPrimaryDark: Colors.green.shade700,
            colorSecondary: Colors.green.shade500,
          ),
        ),
      );

      double parsedAmount;
      try {
        final cleanAmount = widget.amount.replaceAll(RegExp(r'[^\d.]'), '');
        parsedAmount = double.parse(cleanAmount);
      } catch (e) {
        throw Exception('Format jumlah pembayaran tidak valid');
      }

      if (parsedAmount <= 0) {
        throw Exception('Jumlah pembayaran harus lebih dari 0');
      }

      midtransSDK?.setTransactionFinishedCallback((result) {
        bool isSuccess = false;

        try {
          final status = result.status.toLowerCase();
          isSuccess =
              status == 'success' ||
              status == 'settlement' ||
              status == 'pending';

          if (status == 'cancel' || status == 'deny' || status == 'expire') {
            isSuccess = false;
          }

          print('Transaction status: $status');
          print('Result details: ${result.toString()}');
        } catch (e) {
          print('Error checking transaction status: $e');
          isSuccess = false;
        }

        if (mounted) {
          Navigator.pop(context, isSuccess);
        }
      });

      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/get_midtrans_token.php'),
        body: {
          'order_id': widget.orderId,
          'user_id': widget.userId,
          'amount': widget.amount,
          'payment_channel': widget.paymentChannel,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['snap_token'] != null) {
          String transactionToken = data['snap_token'];
          await midtransSDK?.startPaymentUiFlow(token: transactionToken);
        } else {
          throw Exception(
            data['message'] ?? 'Gagal mendapatkan token pembayaran',
          );
        }
      } else {
        throw Exception('Gagal menghubungi server');
      }
    } catch (e) {
      print('Midtrans payment error: $e');
      setState(() {
        hasError = true;
        statusMessage = "Terjadi kesalahan: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isLoading) {
          return await showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Batalkan Pembayaran?'),
                      content: const Text(
                        'Proses pembayaran sedang berlangsung. Anda yakin ingin membatalkan?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Tidak'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Ya, Batalkan'),
                        ),
                      ],
                    ),
              ) ??
              false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Proses Pembayaran',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 24),
                  Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ] else if (hasError) ...[
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    statusMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        hasError = false;
                        statusMessage = "Mencoba ulang pembayaran...";
                      });
                      _initMidtransSDK();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ] else ...[
                  const Text(
                    'Pembayaran telah selesai atau dibatalkan.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
