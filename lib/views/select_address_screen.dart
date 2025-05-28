import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'add_address_screen.dart';

class SelectAddressScreen extends StatefulWidget {
  final String userId;
  const SelectAddressScreen({super.key, required this.userId});

  @override
  State<SelectAddressScreen> createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  List<dynamic> addresses = [];
  bool isLoading = true;
  int? selectedAddressIndex;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          '${Config.BASE_URL}/get_addresses.php?user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          setState(() {
            addresses = data['addresses'];

            // Pilih alamat default jika ada
            for (int i = 0; i < addresses.length; i++) {
              if (addresses[i]['is_default'] == 1) {
                selectedAddressIndex = i;
                break;
              }
            }

            // Jika tidak ada alamat default, pilih yang pertama
            if (selectedAddressIndex == null && addresses.isNotEmpty) {
              selectedAddressIndex = 0;
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal memuat alamat')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
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
          'Pilih Alamat',
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
              : addresses.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum ada alamat tersimpan"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    AddAddressScreen(userId: widget.userId),
                          ),
                        ).then((value) {
                          if (value == true) fetchAddresses();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Tambah Alamat'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  final bool isSelected = selectedAddressIndex == index;

                  // Parse address components
                  final String recipientName =
                      address['nama_penerima'] ?? 'Tanpa Nama';
                  final String phone = address['no_hp'] ?? '-';
                  final String detailAddress = address['detail_alamat'] ?? '-';
                  final String district = address['district_name'] ?? '';
                  final String regency = address['regency_name'] ?? '';
                  final String province = address['province_name'] ?? '';
                  final String postalCode = address['kode_pos'] ?? '';
                  final bool isDefault = address['is_default'] == 1;
                  final List<String> labels =
                      (address['label'] ?? '')
                          .toString()
                          .split(',')
                          .where((t) => t.trim().isNotEmpty)
                          .toList();

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAddressIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isSelected ? Colors.green : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Radio(
                                value: index,
                                groupValue: selectedAddressIndex,
                                onChanged: (value) {
                                  setState(() {
                                    selectedAddressIndex = value as int;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$recipientName   $phone',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (isDefault)
                                          const Chip(
                                            label: Text(
                                              'Default',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            backgroundColor: Colors.green,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      detailAddress,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$district, $regency',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      '$province $postalCode',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (labels.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              children:
                                  labels
                                      .map(
                                        (label) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar:
          addresses.isEmpty
              ? null
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AddAddressScreen(
                                        userId: widget.userId,
                                      ),
                                ),
                              ).then((value) {
                                if (value == true) fetchAddresses();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Tambah Alamat Baru',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          selectedAddressIndex != null
                              ? () {
                                // Ambil alamat yang dipilih
                                final selectedAddress =
                                    addresses[selectedAddressIndex!];

                                // Data yang akan dikembalikan ke halaman sebelumnya
                                final result = {
                                  'id': selectedAddress['id'],
                                  'nama_penerima':
                                      selectedAddress['nama_penerima'],
                                  'no_hp': selectedAddress['no_hp'],
                                  'detail_alamat':
                                      selectedAddress['detail_alamat'],
                                  'district': selectedAddress['district_name'],
                                  'regency': selectedAddress['regency_name'],
                                  'province': selectedAddress['province_name'],
                                  'postal_code': selectedAddress['kode_pos'],
                                };

                                // Kembali ke halaman sebelumnya dengan data alamat terpilih
                                Navigator.pop(context, result);
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Gunakan Alamat Ini',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
