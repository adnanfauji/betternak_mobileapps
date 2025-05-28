import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';

class BankAccountScreen extends StatefulWidget {
  final String userId;

  const BankAccountScreen({super.key, required this.userId});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  List<Map<String, dynamic>> bankAccounts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBankAccounts();
  }

  Future<void> fetchBankAccounts() async {
    setState(() => isLoading = true);

    try {
      print(
        'Fetching bank accounts for user_id: ${widget.userId}',
      ); // Debug log

      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/get_bank_accounts.php'),
        body: {'user_id': widget.userId},
      );

      print('API Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            bankAccounts = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          _showSnackBar(data['message'] ?? 'Gagal memuat data rekening');
        }
      } else {
        throw Exception('Failed to load bank accounts');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteBankAccount(int accountId) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/delete_bank_account.php'),
        body: {'account_id': accountId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            bankAccounts.removeWhere((account) => account['id'] == accountId);
          });
          _showSnackBar('Rekening berhasil dihapus');
        } else {
          _showSnackBar(data['message'] ?? 'Gagal menghapus rekening');
        }
      } else {
        throw Exception('Failed to delete bank account');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> showAddBankAccountDialog() async {
    final TextEditingController bankNameController = TextEditingController();
    final TextEditingController accountNumberController =
        TextEditingController();
    final TextEditingController accountHolderController =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Rekening Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankNameController,
                decoration: const InputDecoration(labelText: 'Nama Bank'),
              ),
              TextField(
                controller: accountNumberController,
                decoration: const InputDecoration(labelText: 'Nomor Rekening'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: accountHolderController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pemilik Rekening',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final bankName = bankNameController.text.trim();
                final accountNumber = accountNumberController.text.trim();
                final accountHolder = accountHolderController.text.trim();

                if (bankName.isNotEmpty &&
                    accountNumber.isNotEmpty &&
                    accountHolder.isNotEmpty) {
                  Navigator.pop(context);
                  await addBankAccount(bankName, accountNumber, accountHolder);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> addBankAccount(
    String bankName,
    String accountNumber,
    String accountHolder,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/add_bank_account.php'),
        body: {
          'user_id': widget.userId,
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_holder': accountHolder,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            bankAccounts.add({
              'id': data['account_id'], // ID rekening baru dari API
              'bank_name': bankName,
              'account_number': accountNumber,
              'account_holder': accountHolder,
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rekening berhasil ditambahkan')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Gagal menambahkan rekening'),
            ),
          );
        }
      } else {
        throw Exception('Failed to add bank account');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kartu / Rekening Bank',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : bankAccounts.isEmpty
                    ? const Center(
                      child: Text(
                        'Belum ada rekening tersimpan',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView(
                      padding: const EdgeInsets.all(16),
                      children:
                          bankAccounts
                              .map(
                                (account) => _buildBankAccountItem(
                                  accountId: account['id'],
                                  bankName: account['bank_name'],
                                  accountNumber: account['account_number'],
                                  accountHolder: account['account_holder'],
                                ),
                              )
                              .toList(),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: showAddBankAccountDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Rekening Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountItem({
    required int accountId,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.account_balance, color: Colors.green),
        title: Text(
          bankName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'No. Rekening: $accountNumber\nAtas Nama: $accountHolder',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => deleteBankAccount(accountId),
        ),
      ),
    );
  }
}
