import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';

class EditAddressScreen extends StatefulWidget {
  final String userId;
  final String addressId;

  const EditAddressScreen({
    super.key,
    required this.userId,
    required this.addressId,
  });

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressDetailController =
      TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Location selection variables
  int? _selectedProvinceId;
  int? _selectedRegencyId;
  int? _selectedDistrictId;

  List<dynamic> _provinces = [];
  List<dynamic> _regencies = [];
  List<dynamic> _districts = [];

  bool _isLoading = false;

  // Checkbox variables
  bool _isMainAddress = false;
  bool _isOtherAddress = false;
  bool _isReturnAddress = false;

  @override
  void initState() {
    super.initState();
    fetchProvinces();
    fetchAddressDetails();
  }

  Future<void> fetchProvinces() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('${Config.BASE_URL}/get_provinces.php');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _provinces = data['provinces'];
          });
        }
      }
    } catch (e) {
      print("Error fetching provinces: $e");
    }
  }

  Future<void> fetchRegencies(int provinceId) async {
    final url = Uri.parse(
      '${Config.BASE_URL}/get_regencies.php?province_id=$provinceId',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _regencies = data['regencies'];
          });
        }
      }
    } catch (e) {
      print("Error fetching regencies: $e");
    }
  }

  Future<void> fetchDistricts(int regencyId) async {
    final url = Uri.parse(
      '${Config.BASE_URL}/get_districts.php?regency_id=$regencyId',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _districts = data['districts'];
          });
        }
      }
    } catch (e) {
      print("Error fetching districts: $e");
    }
  }

  Future<void> fetchAddressDetails() async {
    final url = Uri.parse(
      '${Config.BASE_URL}/get_address_detail.php?address_id=${widget.addressId}',
    );
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final address = data['address'];
          _nameController.text = address['nama_penerima'] ?? '';
          _phoneController.text = address['no_hp'] ?? '';
          _addressDetailController.text = address['detail_alamat'] ?? '';
          _tagsController.text = address['label'] ?? '';
          _postalCodeController.text = address['kode_pos'] ?? '';

          _selectedProvinceId = int.tryParse(address['province_id'].toString());
          _selectedRegencyId = int.tryParse(address['regency_id'].toString());
          _selectedDistrictId = int.tryParse(address['district_id'].toString());

          // Set checkbox values based on label
          String label = address['label']?.toString() ?? '';
          _isMainAddress = label.toLowerCase().contains('utama');
          _isOtherAddress = label.toLowerCase().contains('lainnya');
          _isReturnAddress = label.toLowerCase().contains('pengembalian');

          // Fetch regencies and districts based on selected province and regency
          if (_selectedProvinceId != null) {
            await fetchRegencies(_selectedProvinceId!);
          }
          if (_selectedRegencyId != null) {
            await fetchDistricts(_selectedRegencyId!);
          }
        }
      }
    } catch (e) {
      print("Error fetching address details: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateAddress() async {
    // Validasi input
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressDetailController.text.isEmpty ||
        _selectedProvinceId == null ||
        _selectedRegencyId == null ||
        _selectedDistrictId == null ||
        _postalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua field wajib diisi!')));
      return;
    }

    // Menggabungkan label dari checkbox
    List<String> labels = [];
    if (_isMainAddress) labels.add('Utama');
    if (_isOtherAddress) labels.add('Lainnya');
    if (_isReturnAddress) labels.add('Pengembalian');

    // Tambahkan label custom jika ada dan tidak sama dengan label yang sudah ada
    if (_tagsController.text.isNotEmpty) {
      final customLabel = _tagsController.text.trim();
      if (!labels.any(
        (label) => label.toLowerCase() == customLabel.toLowerCase(),
      )) {
        labels.add(customLabel);
      }
    }

    final String combinedLabels = labels.join(',');

    // Gunakan save_address.php sebagai fallback jika update_address.php belum diimplementasikan
    final url = Uri.parse('${Config.BASE_URL}/save_address.php');
    setState(() {
      _isLoading = true;
    });

    final body = {
      'user_id': widget.userId,
      'address_id': widget.addressId, // Mengirim address_id untuk update
      'nama_penerima': _nameController.text,
      'no_hp': _phoneController.text,
      'detail_alamat': _addressDetailController.text,
      'label': combinedLabels,
      'kode_pos': _postalCodeController.text,
      'province_id': _selectedProvinceId.toString(),
      'regency_id': _selectedRegencyId.toString(),
      'district_id': _selectedDistrictId.toString(),
    };

    try {
      print('Sending request to: $url');
      print('Request body: $body');

      final response = await http.post(url, body: body);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          Navigator.pop(context, true); // Return true to refresh address list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Gagal memperbarui alamat'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error updating address: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ubah Alamat',
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
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Penerima
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Penerima',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nomor HP
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor HP',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    // Detail Alamat
                    TextField(
                      controller: _addressDetailController,
                      decoration: const InputDecoration(
                        labelText: 'Detail Alamat',
                        border: OutlineInputBorder(),
                        helperText: 'Jalan, Nomor Rumah, RT/RW, dll.',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // Province Selector
                    const Text('Provinsi'),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: _selectedProvinceId,
                      isExpanded: true,
                      hint: const Text('Pilih Provinsi'),
                      items:
                          _provinces.map((province) {
                            return DropdownMenuItem<int>(
                              value: int.tryParse(province['id'].toString()),
                              child: Text(province['name']),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProvinceId = value;
                          _selectedRegencyId = null;
                          _selectedDistrictId = null;
                          _regencies = [];
                          _districts = [];
                        });
                        if (value != null) fetchRegencies(value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Regency Selector
                    const Text('Kabupaten/Kota'),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: _selectedRegencyId,
                      isExpanded: true,
                      hint: const Text('Pilih Kabupaten/Kota'),
                      items:
                          _regencies.map((regency) {
                            return DropdownMenuItem<int>(
                              value: int.tryParse(regency['id'].toString()),
                              child: Text(regency['name']),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRegencyId = value;
                          _selectedDistrictId = null;
                          _districts = [];
                        });
                        if (value != null) fetchDistricts(value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // District Selector
                    const Text('Kecamatan'),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: _selectedDistrictId,
                      isExpanded: true,
                      hint: const Text('Pilih Kecamatan'),
                      items:
                          _districts.map((district) {
                            return DropdownMenuItem<int>(
                              value: int.tryParse(district['id'].toString()),
                              child: Text(district['name']),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrictId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Kode Pos
                    TextField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Kode Pos',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Label custom (opsional)
                    TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Label Kustom (Opsional)',
                        border: OutlineInputBorder(),
                        helperText: 'Contoh: Rumah, Kantor, dll.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Checkbox untuk label
                    const Text(
                      'Tambahkan Label:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Checkbox Label Utama
                    CheckboxListTile(
                      title: const Text('Alamat Utama'),
                      value: _isMainAddress,
                      onChanged: (bool? value) {
                        setState(() {
                          _isMainAddress = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Checkbox Label Lainnya
                    CheckboxListTile(
                      title: const Text('Alamat Lainnya'),
                      value: _isOtherAddress,
                      onChanged: (bool? value) {
                        setState(() {
                          _isOtherAddress = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Checkbox Label Pengembalian
                    CheckboxListTile(
                      title: const Text('Alamat Pengembalian'),
                      value: _isReturnAddress,
                      onChanged: (bool? value) {
                        setState(() {
                          _isReturnAddress = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),

                    // Tombol Update
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Perbarui Alamat',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
