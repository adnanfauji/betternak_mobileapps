import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthController authController = AuthController();
  bool isLoading = false;

  // Tambahkan variabel untuk role
  String selectedRole = 'buyer'; // Default role

  // Fungsi untuk registrasi
  void register() async {
    // Trim input to avoid accidental spaces
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar("Semua kolom wajib diisi!", Colors.red);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Password tidak cocok!", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await authController.register(
        name,
        email,
        password,
        selectedRole,
        phone,
      );

      if (!mounted) return;

      final isSuccess =
          response['status'] == 'success' || response['success'] == true;
      final message = response['message'] ?? 'Registrasi selesai';

      _showSnackBar(message, isSuccess ? Colors.green : Colors.red);

      if (isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Fungsi untuk menampilkan SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset('images/LogoBetter-nak.png', height: 80),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Registrasi untuk Better-Nak",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Isikan data-data di bawah ini dengan benar.",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 30),
                _buildTextField(nameController, "Nama"),
                const SizedBox(height: 10),
                _buildTextField(emailController, "Email"),
                const SizedBox(height: 10),
                _buildTextField(phoneController, "Telepon"),
                const SizedBox(height: 10),
                _buildTextField(
                  passwordController,
                  "Password",
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  confirmPasswordController,
                  "Ulangi password",
                  isPassword: true,
                ),
                const SizedBox(height: 10),

                // Dropdown untuk memilih role
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                    DropdownMenuItem(value: 'seller', child: Text('Seller')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Pilih Role",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Daftar",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sudah punya akun? Login",
                      style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk TextField
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}
