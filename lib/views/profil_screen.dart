// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../config/config.dart';
import 'edit_profile_field_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String profilePicture = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/get_users.php'),
        body: {'userId': widget.userId},
      );

      final result = json.decode(response.body);

      if (result['success']) {
        final userData = result['data'];
        setState(() {
          nameController.text = userData['name'];
          emailController.text = userData['email'];
          phoneController.text = userData['phone'];
          profilePicture = userData['profile_picture'] ?? '';
          isLoading = false;
        });
      } else {
        _showErrorSnackbar(result['message']);
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showErrorSnackbar('Gagal memuat data profil.');
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${Config.BASE_URL}/upload_profile_picture.php'),
        );

        request.fields['userId'] = widget.userId;
        request.files.add(
          await http.MultipartFile.fromPath('profile_picture', pickedFile.path),
        );

        var streamedResponse = await request.send();
        final responseBody = await streamedResponse.stream.bytesToString();
        final result = json.decode(responseBody);

        if (result['success'] == true) {
          setState(() {
            profilePicture = result['filename'];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diubah')),
          );
        } else {
          _showErrorSnackbar(result['message'] ?? 'Gagal mengunggah');
        }
      } catch (e) {
        _showErrorSnackbar('Terjadi kesalahan: $e');
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/update_profile.php'),
        body: {
          'userId': widget.userId,
          'name': nameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
        },
      );

      final result = json.decode(response.body);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    } catch (e) {
      _showErrorSnackbar('Terjadi kesalahan: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.green)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () {
            Navigator.pop(context, nameController.text);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.shoppingBag, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                profilePicture.isNotEmpty
                                    ? NetworkImage(
                                      '${Config.BASE_URL}/$profilePicture',
                                    )
                                    : const AssetImage('images/user.png')
                                        as ImageProvider,
                          ),
                          TextButton(
                            onPressed: _pickAndUploadImage,
                            child: const Text(
                              'Ubah Foto',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildEditableTile('Nama', nameController.text, 'name'),
                    _buildEditableTile('Email', emailController.text, 'email'),
                    _buildEditableTile(
                      'Nomor HP',
                      phoneController.text,
                      'phone',
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Keluar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildEditableTile(String label, String value, String field) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit, color: Colors.green),
      onTap: () async {
        final updatedValue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => EditProfileFieldScreen(
                  userId: widget.userId,
                  field: field,
                  currentValue: value,
                ),
          ),
        );

        if (updatedValue != null) {
          setState(() {
            if (field == 'name') {
              nameController.text = updatedValue;
            } else if (field == 'email') {
              emailController.text = updatedValue;
            } else if (field == 'phone') {
              phoneController.text = updatedValue;
            }
          });

          // Muat ulang data dari server untuk memastikan sinkronisasi
          await _loadUserData();
        }
      },
    );
  }
}
