import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../config/config.dart';
import 'my_livestock_screen.dart';

class AddLivestockScreen extends StatefulWidget {
  final int sellerId;

  const AddLivestockScreen({super.key, required this.sellerId});

  @override
  State<AddLivestockScreen> createState() => _AddLivestockScreenState();
}

class _AddLivestockScreenState extends State<AddLivestockScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  String? _category;
  String? _type;
  String? _status;
  String? _gender;

  final List<Map<String, dynamic>> _categoryOptions = [
    {'id': 1, 'name': 'Sapi'},
    {'id': 2, 'name': 'Kambing'},
    {'id': 3, 'name': 'Domba'},
    {'id': 4, 'name': 'Unggas'},
    {'id': 5, 'name': 'Lainnya'},
  ];

  final _typeOptions = ['livestock', 'product'];
  final _statusOptions = ['active', 'inactive'];
  final _genderOptions = ['jantan', 'betina'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua field yang wajib')),
      );
      return;
    }

    if (_type == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harap pilih jenis produk')));
      return;
    }

    final weightValue =
        _weightController.text.trim().isEmpty
            ? '0'
            : _weightController.text.trim();
    final ageValue =
        _ageController.text.trim().isEmpty ? '0' : _ageController.text.trim();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final uri = Uri.parse('${Config.BASE_URL}/add_livestock.php');
      var request = http.MultipartRequest('POST', uri);

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
      }

      request.fields.addAll({
        'user_id': widget.sellerId.toString(),
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'stock': _stockController.text.trim(),
        'category_id': _getSelectedCategoryId().toString(),
        'seller_id': widget.sellerId.toString(),
        'weight': weightValue,
        'age': ageValue,
        'type': _type ?? 'livestock',
        'status': _status ?? 'active',
        'gender': _gender ?? '',
      });

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      final jsonResponse = json.decode(responseBody);
      print('Response: $jsonResponse');

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder:
                (context) => MyLivestockScreen(currentUserId: widget.sellerId),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['message'] ?? 'Gagal menyimpan data'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  int _getSelectedCategoryId() {
    final selected = _categoryOptions.firstWhere(
      (cat) => cat['name'] == _category,
      orElse: () => _categoryOptions[0],
    );
    return selected['id'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Ternak'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Foto Produk'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child:
                      _selectedImage == null
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40),
                                SizedBox(height: 8),
                                Text('Tambahkan Foto'),
                              ],
                            ),
                          )
                          : Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('Nama Produk *'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Masukkan nama produk'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Deskripsi'),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Masukkan deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Harga *'),
              TextFormField(
                controller: _priceController,
                decoration: _inputDecoration('Masukkan harga'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Stok *'),
              TextFormField(
                controller: _stockController,
                decoration: _inputDecoration('Masukkan stok'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Kategori *'),
              _buildDropdown(
                value: _category,
                items:
                    _categoryOptions
                        .map((cat) => cat['name'] as String)
                        .toList(),
                hint: 'Pilih kategori',
                onChanged: (value) => setState(() => _category = value),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Jenis Produk *'),
              _buildDropdown(
                value: _type,
                items: _typeOptions,
                hint: 'Pilih jenis',
                onChanged: (value) => setState(() => _type = value),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Berat (kg)'),
              TextFormField(
                controller: _weightController,
                decoration: _inputDecoration('Masukkan berat'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Usia (bulan)'),
              TextFormField(
                controller: _ageController,
                decoration: _inputDecoration('Masukkan usia'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Jenis Kelamin'),
              _buildDropdown(
                value: _gender,
                items: _genderOptions,
                hint: 'Pilih jenis kelamin',
                onChanged: (value) => setState(() => _gender = value),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Status'),
              _buildDropdown(
                value: _status,
                items: _statusOptions,
                hint: 'Pilih status',
                onChanged: (value) => setState(() => _status = value),
                validator: (_) => null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Simpan Produk',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
    required FormFieldValidator<String>? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items
              .map(
                (String val) => DropdownMenuItem(value: val, child: Text(val)),
              )
              .toList(),
      onChanged: onChanged,
      decoration: _inputDecoration(hint),
      validator: validator,
    );
  }
}

class LivestockListCompact extends StatelessWidget {
  final int sellerId;
  final String filterStatus;

  const LivestockListCompact({
    super.key,
    required this.sellerId,
    required this.filterStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Livestock List: $filterStatus for Seller $sellerId'),
    );
  }
}
