import 'package:flutter/material.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pesan',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMessageItem(
            'Peternakan Pak Ahmad',
            'Apakah stok sapi limousin masih tersedia?',
            'images/peternakanpakahmad.jpg',
            '12:30 PM',
          ),
          const Divider(),
          _buildMessageItem(
            'Peternakan Ibu Sari',
            'Pesanan Anda sedang dalam pengiriman.',
            'images/peternakanibusari.jpg',
            '09:45 AM',
          ),
          const Divider(),
          _buildMessageItem(
            'Peternakan Jaya',
            'Kambing etawa tersedia dalam jumlah banyak.',
            'images/peternakanjaya.jpg',
            'Kemarin',
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan item pesan
  Widget _buildMessageItem(
    String sender,
    String message,
    String imagePath,
    String time,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(radius: 30, backgroundImage: AssetImage(imagePath)),
      title: Text(
        sender,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        message,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(color: Colors.black54),
      ),
      trailing: Text(time, style: const TextStyle(color: Colors.black45)),
      onTap: () {
        // Aksi saat pesan diklik (navigasi ke chat detail bisa ditambahkan di sini)
      },
    );
  }
}
