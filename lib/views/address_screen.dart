import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import 'add_address_screen.dart';
import 'edit_address_screen.dart';

class AddressScreen extends StatefulWidget {
  final String userId;
  const AddressScreen({super.key, required this.userId});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<dynamic> addressList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    setState(() => _isLoading = true);
    final url = Uri.parse(
      '${Config.BASE_URL}/get_addresses.php?user_id=${widget.userId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            addressList = data['addresses'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal memuat alamat')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat alamat (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    final url = Uri.parse('${Config.BASE_URL}/set_default_address.php');
    try {
      final response = await http.post(
        url,
        body: {'user_id': widget.userId, 'address_id': addressId},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          await fetchAddresses(); // Refresh daftar alamat
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(data['message'])));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Gagal mengubah default'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Tambahkan fungsi untuk menghapus alamat
  Future<void> deleteAddress(String addressId) async {
    // Tampilkan dialog konfirmasi
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Konfirmasi Hapus'),
                content: const Text(
                  'Apakah Anda yakin ingin menghapus alamat ini?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('${Config.BASE_URL}/delete_address.php');
    try {
      final response = await http.post(
        url,
        body: {'user_id': widget.userId, 'address_id': addressId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Alamat berhasil dihapus'),
            ),
          );
          fetchAddresses(); // Refresh daftar alamat
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Gagal menghapus alamat'),
            ),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alamat Saya',
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
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : addressList.isEmpty
              ? const Center(child: Text('Belum ada alamat.'))
              : ListView.builder(
                itemCount: addressList.length,
                itemBuilder: (context, index) {
                  final addr = addressList[index];
                  return _addressItem(
                    addressId: addr['id']?.toString() ?? '',
                    name: addr['nama_penerima'] ?? 'Tanpa Nama',
                    phone: addr['no_hp'] ?? '-',
                    address: addr['detail_alamat'] ?? '-',
                    tags:
                        (addr['label'] ?? '')
                            .toString()
                            .split(',')
                            .where((t) => t.trim().isNotEmpty)
                            .toList(),
                    isDefault: addr['is_default'] == 1,
                  );
                },
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddAddressScreen(userId: widget.userId),
              ),
            ).then((value) {
              if (value == true) fetchAddresses();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Tambah Alamat Baru'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  Widget _addressItem({
    required String addressId,
    required String name,
    required String phone,
    required String address,
    required List<String> tags,
    required bool isDefault,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nama penerima dan nomor telepon
                Expanded(
                  child: Text(
                    '$name   $phone',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // Icon hapus
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => deleteAddress(addressId),
                  tooltip: 'Hapus alamat',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Detail alamat
            Text(address),
            const SizedBox(height: 8),

            // Label (tags) jika ada
            if (tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: tags.map((t) => _buildTag(t)).toList(),
              ),
            const SizedBox(height: 8),

            // Tombol "Ubah" dan label sejajar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EditAddressScreen(
                              userId: widget.userId,
                              addressId: addressId,
                            ),
                      ),
                    ).then((value) {
                      if (value == true) fetchAddresses();
                    });
                  },
                  child: const Text(
                    'Ubah',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
                if (tags.isNotEmpty)
                  Text(
                    tags.join(', '), // Gabungkan semua tag menjadi satu string
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.orange, fontSize: 12),
      ),
    );
  }
}
