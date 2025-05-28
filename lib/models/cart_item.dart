class CartItem {
  final String id;
  final String name;
  final int quantity;
  final String price;
  final String image;
  final String productId;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
    this.productId = '',
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    try {
      return CartItem(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Produk',
        quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
        price: map['price']?.toString() ?? '0',
        image: map['image']?.toString() ?? '',
        productId: map['product_id']?.toString() ?? '',
      );
    } catch (e) {
      print('Error creating CartItem from map: $e');
      print('Map data: $map');
      return CartItem(
        id: '',
        name: 'Error Product',
        quantity: 1,
        price: '0',
        image: '',
      );
    }
  }
}
