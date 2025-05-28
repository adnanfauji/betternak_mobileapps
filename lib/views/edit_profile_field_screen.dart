import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';

class EditProfileFieldScreen extends StatefulWidget {
  final String userId;
  final String field;
  final String currentValue;

  const EditProfileFieldScreen({
    super.key,
    required this.userId,
    required this.field,
    required this.currentValue,
  });

  @override
  State<EditProfileFieldScreen> createState() => _EditProfileFieldScreenState();
}

class _EditProfileFieldScreenState extends State<EditProfileFieldScreen> {
  late TextEditingController _controller;
  bool isLoading = false;

  String get label {
    switch (widget.field) {
      case 'name':
        return 'Name';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Nomor HP';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  Future<void> _saveChange() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/update_profil.php'),
        body: {
          'userId': widget.userId,
          'field': widget.field,
          'value': _controller.text,
        },
      );

      final result = json.decode(response.body);

      if (result['success']) {
        Navigator.pop(context, _controller.text);
      } else {
        _showSnackbar(result['message']);
      }
    } catch (e) {
      _showSnackbar('Terjadi kesalahan: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ubah $label'), backgroundColor: Colors.green),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      keyboardType:
                          widget.field == 'phone'
                              ? TextInputType.phone
                              : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: label,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveChange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
