import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // untuk format harga
import '../config/config.dart';
import 'add_livestock_screen.dart';
import 'edit_livestock_screen.dart';

class LivestockListCompact extends StatefulWidget {
  final int userId;
  final String filterStatus;

  const LivestockListCompact({
    super.key,
    required this.userId,
    required this.filterStatus,
  });

  @override
  State<LivestockListCompact> createState() => _LivestockListCompactState();
}

class _LivestockListCompactState extends State<LivestockListCompact> {
  List<dynamic> _livestock = [];
  bool _loading = true;
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');

  @override
  void initState() {
    super.initState();
    fetchLivestock();
  }

  Future<void> fetchLivestock() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        '${Config.BASE_URL}/get_livestock.php?user_id=${widget.userId}&status=${widget.filterStatus}',
      );

      final res = await http.get(uri);

      if (res.statusCode == 200) {
        try {
          final body = jsonDecode(res.body);
          // Debug response
          print('API response body: $body');

          if (body['success']) {
            setState(() {
              _livestock = body['data'];
            });
          } else {
            _showError(
              'Gagal mengambil data ternak: ${body['message'] ?? 'Unknown error'}',
            );
          }
        } catch (e) {
          _showError('Format data tidak valid: ${res.body}');
        }
      } else {
        _showError(
          'Gagal mengambil data ternak, HTTP status ${res.statusCode}',
        );
      }
    } catch (e) {
      _showError('Gagal mengambil data ternak: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    print(message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _iconText(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String formatGender(dynamic gender) {
    if (gender == null) return '';
    final g = gender.toString().toLowerCase();
    if (g == 'male' || g == 'jantan') return 'Jantan';
    if (g == 'female' || g == 'betina') return 'Betina';
    return gender.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_livestock.isEmpty) {
      return const Center(child: Text('Belum ada ternak.'));
    }
    return ListView.builder(
      itemCount: _livestock.length,
      itemBuilder: (context, i) {
        final item = _livestock[i];

        // Parsing harga ke double dengan aman
        double priceValue = 0;
        if (item['price'] != null) {
          if (item['price'] is int) {
            priceValue = (item['price'] as int).toDouble();
          } else if (item['price'] is double) {
            priceValue = item['price'] as double;
          } else if (item['price'] is String) {
            priceValue = double.tryParse(item['price']) ?? 0;
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          (item['image'] != null &&
                                  item['image'].toString().isNotEmpty)
                              ? FadeInImage.assetNetwork(
                                placeholder: 'images/default.png',
                                image: item['image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                imageErrorBuilder:
                                    (_, __, ___) => Image.asset(
                                      'images/default.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                              )
                              : Image.asset(
                                'images/default.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((item['description'] ?? '').toString().isNotEmpty)
                            Text(
                              item['description'] != null &&
                                      item['description'].toString().isNotEmpty
                                  ? '${item['name']} | ${item['description']}'
                                  : item['name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          else
                            Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          if (item['is_advertised'] == true)
                            Text(
                              'Diiklankan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(formatCurrency.format(priceValue)),
                          Text(
                            'Stok: ${item['stock']} | Umur: ${item['age']} bln',
                          ),
                          Text(
                            'Jenis Kelamin: ${formatGender(item['gender'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),

                          // Ganti bagian status di sini:
                          Row(
                            children: [
                              Icon(
                                item['status'] == 'active'
                                    ? Icons.check_circle
                                    : item['status'] == 'sold_out'
                                    ? Icons.cancel
                                    : Icons.info,
                                size: 14,
                                color:
                                    item['status'] == 'active'
                                        ? Colors.green
                                        : item['status'] == 'sold_out'
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['status'] ?? '',
                                style: TextStyle(
                                  color:
                                      item['status'] == 'active'
                                          ? Colors.green
                                          : item['status'] == 'sold_out'
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _iconText(Icons.store, 'Stok ${item['stock'] ?? 0}'),
                    _iconText(
                      Icons.shopping_cart,
                      'Terjual ${item['sold'] ?? 0}',
                    ),
                    _iconText(
                      Icons.favorite_border,
                      'Favorit ${item['favorite'] ?? 0}',
                    ),
                    _iconText(
                      Icons.remove_red_eye_outlined,
                      'Dilihat ${item['views'] ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (item['is_advertised']?.toString() != '1' &&
                        item['is_advertised'] != true) ...[
                      OutlinedButton(
                        onPressed: () async {
                          final response = await http.post(
                            Uri.parse(
                              '${Config.BASE_URL}/advertise_livestock.php',
                            ),
                            body: {'id': item['id'].toString()},
                          );
                          final data = jsonDecode(response.body);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(data['message'])),
                          );
                          if (data['success'] == true) fetchLivestock();
                        },
                        child: const Text("Iklankan"),
                      ),
                    ],

                    OutlinedButton(
                      onPressed: () async {
                        final response = await http.post(
                          Uri.parse('${Config.BASE_URL}/archive_livestock.php'),
                          body: {'id': item['id'].toString()},
                        );
                        final data = jsonDecode(response.body);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(data['message'])),
                        );
                        if (data['success'] == true) fetchLivestock();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Arsipkan"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditLivestockScreen(item: item),
                          ),
                        ).then((edited) {
                          if (edited == true) fetchLivestock();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text("Ubah"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MyLivestockScreen extends StatefulWidget {
  final int currentUserId;

  const MyLivestockScreen({super.key, required this.currentUserId});

  @override
  State<MyLivestockScreen> createState() => _MyLivestockScreenState();
}

class _MyLivestockScreenState extends State<MyLivestockScreen> {
  Key _tabKey = UniqueKey();

  Future<void> _navigateToAddLivestock(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddLivestockScreen(sellerId: widget.currentUserId),
      ),
    );
    setState(() {
      _tabKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Ternak Saya',
            style: TextStyle(color: Colors.black),
          ),
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Habis'),
              Tab(text: 'Sedang Diperiksa'),
              Tab(text: 'Perlu Tindakan'),
              Tab(text: 'Arsip'),
            ],
          ),
        ),
        body: TabBarView(
          key: _tabKey,
          children: [
            _buildTabContent(status: 'active'),
            _buildTabContent(status: 'sold_out'),
            _buildTabContent(status: 'under_review'),
            _buildTabContent(status: 'needs_action'),
            _buildTabContent(status: 'archived'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToAddLivestock(context),
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabContent({required String status}) {
    return LivestockListCompact(
      userId: widget.currentUserId,
      filterStatus: status,
    );
  }
}
