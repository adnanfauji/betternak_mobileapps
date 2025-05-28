// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/config.dart';

class EditLivestockScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const EditLivestockScreen({super.key, required this.item});

  @override
  State<EditLivestockScreen> createState() => _EditLivestockScreenState();
}

class _EditLivestockScreenState extends State<EditLivestockScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  late TextEditingController _nameCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _weightCtrl;
  late String _gender;
  late TextEditingController _priceCtrl;
  late TextEditingController _ageCtrl;
  final _picker = ImagePicker();

  final _genders = ['Jantan', 'Betina'];

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  String capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1).toLowerCase() : s;

  @override
  void initState() {
    super.initState();
    final i = widget.item;

    _nameCtrl = TextEditingController(text: i['name'] ?? '');
    _stockCtrl = TextEditingController(text: (i['stock'] ?? '').toString());
    _weightCtrl = TextEditingController(text: (i['weight'] ?? '').toString());
    _gender =
        _genders.contains(capitalize(i['gender'] ?? ''))
            ? capitalize(i['gender'] ?? '')
            : _genders.first;
    _priceCtrl = TextEditingController(text: (i['price'] ?? '').toString());
    _ageCtrl = TextEditingController(text: (i['age'] ?? '').toString());

    _fetchCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _stockCtrl.dispose();
    _weightCtrl.dispose();
    _priceCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final p = await showDialog<ImageSource>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Ambil foto dari'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, ImageSource.camera),
                child: const Text('Kamera'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, ImageSource.gallery),
                child: const Text('Galeri'),
              ),
            ],
          ),
    );
    if (p != null) {
      final f = await _picker.pickImage(source: p);
      if (f != null) setState(() => _selectedImage = File(f.path));
    }
  }

  Future<void> _saveEdits(dynamic userId) async {
    if (!_formKey.currentState!.validate()) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    var req = http.MultipartRequest(
      'POST',
      Uri.parse('${Config.BASE_URL}/update_livestock.php'),
    );
    req.fields['id'] = widget.item['id'].toString();
    req.fields['name'] = _nameCtrl.text;
    req.fields['stock'] = _stockCtrl.text;
    req.fields['weight'] = _weightCtrl.text;
    req.fields['gender'] = _gender;
    req.fields['price'] = _priceCtrl.text;
    req.fields['age'] = _ageCtrl.text;
    req.fields['category_id'] = _selectedCategoryId ?? '';
    req.fields['user_id'] = userId.toString();

    final selectedCat = _categories.firstWhere(
      (cat) => cat['id'].toString() == _selectedCategoryId,
      orElse: () => {},
    );
    if (_selectedCategoryId != null) {
      req.fields['category_id'] = _selectedCategoryId!;
    }

    final validTypes = [
      'Sapi',
      'Domba',
      'Kambing',
    ]; // sesuaikan dengan enum di DB
    String typeValue = selectedCat['name'] ?? widget.item['type'] ?? 'Sapi';
    if (!validTypes.contains(typeValue)) typeValue = 'Sapi';
    req.fields['type'] = typeValue;
    if (_selectedImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath('image', _selectedImage!.path),
      );
    }
    var res = await req.send();
    var body = await http.Response.fromStream(res);
    Navigator.pop(context); // tutup loading
    final data = jsonDecode(body.body);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(data['message'])));
    if (data['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _fetchCategories() async {
    final res = await http.get(
      Uri.parse('${Config.BASE_URL}/get_categories.php'),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(body['data']);
          // Cek apakah category_id dari item ada di list kategori
          final currentCatId = widget.item['category_id']?.toString();
          if (_categories.any((cat) => cat['id'].toString() == currentCatId)) {
            _selectedCategoryId = currentCatId;
          } else if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first['id'].toString();
          } else {
            _selectedCategoryId = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Ternak'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Foto', style: Theme.of(c).textTheme.titleMedium),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: _pickImage,
                child:
                    _selectedImage != null
                        ? Image.file(
                          _selectedImage!,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                        : (widget.item['image'] != null &&
                                widget.item['image'].toString().isNotEmpty
                            ? Image.network(
                              widget.item['image'].toString().startsWith('http')
                                  ? widget.item['image']
                                  : '${Config.BASE_URL}/uploads/products/${widget.item['image']}',
                              height: 100,
                              fit: BoxFit.cover,
                            )
                            : const Text('Ganti Foto (opsional)')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items:
                    _categories
                        .map(
                          (cat) => DropdownMenuItem<String>(
                            value: cat['id'].toString(),
                            child: Text(cat['name'].toString()),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator:
                    (v) =>
                        v == null || v.isEmpty ? 'Wajib pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Hewan'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Berat (kg)'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Usia (Bulan)'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                items:
                    _genders
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  var userId = widget.item['user_id'] ?? '';
                  await _saveEdits(userId);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
