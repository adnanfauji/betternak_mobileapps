import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'models/cart_item.dart';
import 'views/order_history_screen.dart';
import 'views/splash_screen.dart';
import 'views/checkout_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Better-Nak',
      home: const SplashScreen(),
      routes: {
        '/orderHistory':
            (context) => OrderHistoryScreen(
              userId: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
    );
  }
}

void navigateToCheckout({
  required BuildContext context,
  required String userId,
  required Map<String, dynamic> addressData,
  required double totalPrice,
  required List<CartItem> cartItems,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (context) => CheckoutScreen(
            userId: userId,
            address: addressData.map(
              (key, value) => MapEntry(key, value.toString()),
            ), // Convert Map<String, dynamic> to Map<String, String>
            totalPrice: totalPrice,
            cartItems: cartItems,
          ),
    ),
  );
}
