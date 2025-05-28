import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';

class AuthController {
  final String baseUrl = Config.BASE_URL;

  /// Mengecek koneksi ke server melalui health_check.php
  Future<bool> checkServerConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health_check.php'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Server Connected: ${response.body}');
        return true;
      } else {
        print('❌ Server Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Connection Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Accept': 'application/json'}, // Request JSON response
        body: {"email": email, "password": password},
      );

      print("📝 Login Response: ${response.body}"); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {
          "status": "error",
          "message": "Gagal menghubungi server. Kode: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Terjadi kesalahan: $e"};
    }
  }

  /// Registrasi pengguna baru
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
    String phone,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: {'Content-Type': 'application/json'}, // Correct header
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": role,
          "phone": phone,
        }),
      );

      print("📝 Register Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        return {
          "status": "error",
          "message": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      print('❌ Registration Error: $e');
      return {
        "status": "error",
        "message": "Terjadi kesalahan koneksi saat registrasi",
      };
    }
  }
}
