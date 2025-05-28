import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/config.dart';
import 'checkout_screen.dart';
import '../models/cart_item.dart';

class CartScreen extends StatefulWidget {
  final String userId;
  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  List<bool> _selected = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    setState(() => _loading = true);

    try {
      // Buat URL dengan userId yang benar - pastikan ini sesuai dengan database
      // Jika di database userId = 1, pastikan yang dikirim juga "1" bukan ID lain
      final url = '${Config.BASE_URL}/get_cart.php?user_id=${widget.userId}';
      print('Requesting cart data from: $url');

      // Contoh untuk testing, ganti widget.userId dengan "1" untuk memastikan
      // final url = '${Config.BASE_URL}/get_cart.php?user_id=1';

      // Atau cetak nilai userId untuk debugging
      print('Using userId: ${widget.userId}');

      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<dynamic> cartData = data['data'] ?? [];
          print('Got ${cartData.length} cart items');

          if (cartData.isEmpty) {
            print('Cart is empty according to API');
            setState(() {
              _cartItems = [];
              _selected = [];
            });
          } else {
            setState(() {
              _cartItems =
                  cartData.map((item) => CartItem.fromMap(item)).toList();
              _selected = List<bool>.filled(_cartItems.length, false);
            });
            print('Successfully parsed ${_cartItems.length} items');
          }
        } else {
          print('API returned success: false. Message: ${data['message']}');
          setState(() {
            _cartItems = [];
            _selected = [];
          });
        }
      } else {
        print('Error response: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Exception during cart fetch: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  int get totalPrice => _cartItems.asMap().entries.fold(0, (sum, entry) {
    if (!_selected[entry.key]) return sum;
    final qty = entry.value.quantity;
    final price = parseHarga(entry.value.price);
    return sum + (qty * price);
  });

  int get totalItems => _cartItems.asMap().entries.fold(0, (sum, entry) {
    if (!_selected[entry.key]) return sum;
    final qty = entry.value.quantity;
    return sum + qty;
  });

  void _showActionModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pilih Aksi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Hapus Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteSelectedItems();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _deleteSelectedItems() async {
    final selectedIds = [
      for (var i = 0; i < _cartItems.length; i++)
        if (_selected[i]) _cartItems[i].id,
    ];

    for (final id in selectedIds) {
      try {
        await http.post(
          Uri.parse('${Config.BASE_URL}/delete_cart_item.php'),
          body: {'cart_id': id, 'action': 'delete'}, // <-- tambahkan action
        );
      } catch (e) {
        print('Error deleting item: $e');
      }
    }

    await fetchCart();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item berhasil dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Keranjang Saya',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Tombol refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: fetchCart,
          ),
          // Tombol ubah jika tidak kosong
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                if (!_selected.contains(true)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pilih item terlebih dahulu')),
                  );
                  return;
                }
                _showActionModal();
              },
              child: const Text(
                'Ubah',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty
              ? const Center(child: Text('Keranjang kamu kosong'))
              : Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cartItems.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        // Bangun URL gambar dengan benar
                        final imageUrl =
                            item.image.startsWith('http')
                                ? item.image
                                : '${Config.BASE_URL}/uploads/products/${item.image}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CheckboxListTile(
                              value: _selected[index],
                              onChanged: (v) {
                                setState(() => _selected[index] = v ?? false);
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${item.quantity} item • Rp${currencyFormatter.format(parseHarga(item.price))}',
                              ),
                              secondary: Image.network(
                                imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                    'Error loading image: $imageUrl - $error',
                                  );
                                  return const Icon(Icons.broken_image);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total ($totalItems)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp${currencyFormatter.format(totalPrice)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              _selected.contains(true)
                                  ? () async {
                                    await navigateToCheckout(
                                      context,
                                      widget.userId,
                                      _cartItems,
                                      _selected,
                                    );
                                    // Setelah kembali dari checkout, refresh cart
                                    fetchCart();
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

Future<Map<String, String>> fetchDefaultAddress(String userId) async {
  final url = Uri.parse(
    '${Config.BASE_URL}/get_default_address.php?user_id=$userId',
  );
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return {
          'name': data['address']['nama_penerima'],
          'phone': data['address']['no_hp'],
          'address': data['address']['detail_alamat'],
        };
      }
    }
  } catch (e) {
    print("Error fetching default address: $e");
  }
  return {
    'name': 'Tidak Ada Alamat',
    'phone': '-',
    'address': 'Silakan tambahkan alamat pengiriman.',
  };
}

final NumberFormat currencyFormatter = NumberFormat('#,##0', 'id_ID');

String formatCurrency(int amount) {
  return 'Rp${currencyFormatter.format(amount)}';
}

int parseHarga(dynamic harga) {
  // Pastikan harga string
  String hargaStr = harga.toString();
  // Jika ada koma/desimal, ambil bagian sebelum koma
  hargaStr = hargaStr.split(',')[0].split('.')[0];
  // Hapus semua karakter non-digit
  hargaStr = hargaStr.replaceAll(RegExp(r'[^\d]'), '');
  return int.tryParse(hargaStr) ?? 0;
}

Future<void> navigateToCheckout(
  BuildContext context,
  String userId,
  List<CartItem> cartItems,
  List<bool> selected,
) async {
  // Hanya kirim item yang dipilih
  final selectedItems = <CartItem>[];
  final selectedCartIds = <String>[];
  for (int i = 0; i < cartItems.length; i++) {
    if (selected[i]) {
      selectedItems.add(cartItems[i]);
      selectedCartIds.add(cartItems[i].id);
    }
  }

  // Jika tidak ada item yang dipilih, tampilkan pesan
  if (selectedItems.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pilih item terlebih dahulu')));
    return;
  }

  final defaultAddress = await fetchDefaultAddress(userId);

  // Navigasi ke halaman checkout dan tunggu hasilnya
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (_) => CheckoutScreen(
            userId: userId,
            cartItems: selectedItems, // Kirim hanya item yang dipilih
            address: defaultAddress,
            totalPrice: selectedItems.fold(0, (sum, item) {
              final price = parseHarga(item.price);
              return (sum ?? 0) + (item.quantity * price);
            }),
          ),
    ),
  );

  // Jika checkout berhasil (misal return true), hapus item dari keranjang
  if (result == true && selectedCartIds.isNotEmpty) {
    for (final id in selectedCartIds) {
      try {
        await http.post(
          Uri.parse('${Config.BASE_URL}/delete_cart_item.php'),
          body: {'cart_id': id},
        );
      } catch (e) {
        print('Error deleting item after checkout: $e');
      }
    }
    // Refresh cart jika masih di halaman cart
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil, item dihapus dari keranjang'),
        ),
      );
      // Jika ingin refresh otomatis, bisa panggil fetchCart jika context masih CartScreen
      // (context as Element).markNeedsBuild(); // atau panggil fetchCart jika perlu
    }
  }
}
