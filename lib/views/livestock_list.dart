// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_livestock_screen.dart';
import 'edit_livestock_screen.dart';
import '../config/config.dart';

class LivestockListCompact extends StatefulWidget {
  final int userId; // Add userId as a required parameter

  const LivestockListCompact({super.key, required this.userId});

  @override
  State<LivestockListCompact> createState() => _LivestockListCompactState();
}

class _LivestockListCompactState extends State<LivestockListCompact> {
  List<dynamic> livestockData = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchLivestock();
  }

  Future<void> fetchLivestock() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '${Config.BASE_URL}/get_livestock.php?user_id=${widget.userId}',
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] && body['data'] is List) {
          setState(() {
            livestockData = body['data'];
          });
        } else {
          throw Exception(body['message'] ?? 'Failed to fetch data');
        }
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $errorMessage')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _advertiseLivestock(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/advertise_livestock.php'),
        body: {'id': id.toString()},
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));

      if (data['success'] == true) {
        await fetchLivestock();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to advertise: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Ternak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchLivestock,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddLivestock(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchLivestock,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (livestockData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Belum ada data ternak'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToAddLivestock,
              child: const Text('Tambah Ternak Baru'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchLivestock,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: livestockData.length,
        itemBuilder: (context, index) {
          final item = livestockData[index];
          return _buildLivestockCard(item);
        },
      ),
    );
  }

  Widget _buildLivestockCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLivestockImage(item),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp${NumberFormat('#,###').format(item['price'] ?? 0)}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLivestockStats(item),
            const SizedBox(height: 12),
            _buildActionButtons(item),
          ],
        ),
      ),
    );
  }

  Widget _buildLivestockImage(Map<String, dynamic> item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        '${item['image']}',
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 70,
            height: 70,
            color: Colors.grey[200],
            child: const Icon(Icons.image, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 70,
            height: 70,
            child: Center(
              child: CircularProgressIndicator(
                value:
                    progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLivestockStats(Map<String, dynamic> item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _iconText(Icons.store, 'Stok ${item['quantity'] ?? 0}'),
        _iconText(Icons.shopping_cart, 'Terjual ${item['sold'] ?? 0}'),
        _iconText(Icons.favorite_border, 'Favorit ${item['favorites'] ?? 0}'),
        _iconText(
          Icons.remove_red_eye_outlined,
          'Dilihat ${item['views'] ?? 0}',
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> item) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: () => _advertiseLivestock(item['id']),
          child: const Text("Iklankan"),
        ),
        OutlinedButton(
          onPressed: () => _archiveLivestock(item['id']),
          child: const Text("Arsipkan"),
        ),
        ElevatedButton(
          onPressed: () => _navigateToEditLivestock(item),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text("Ubah"),
        ),
      ],
    );
  }

  Future<void> _navigateToAddLivestock() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddLivestockScreen(
              sellerId: widget.userId,
            ), // Ganti userId dengan sellerId
      ),
    );
    if (result == true && mounted) {
      await fetchLivestock();
    }
  }

  Future<void> _navigateToEditLivestock(Map<String, dynamic> item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditLivestockScreen(item: item)),
    );
    if (result == true) {
      await fetchLivestock();
    }
  }

  Future<void> _archiveLivestock(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.BASE_URL}/archive_livestock.php'),
        body: {'id': id.toString()},
      );

      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));

      if (data['success'] == true) {
        await fetchLivestock();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to archive: $e')));
    }
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

NumberFormat(String s) {}
