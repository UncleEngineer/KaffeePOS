import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartList extends StatelessWidget {
  final List<CartItem> cart;
  final void Function(int index) onItemTap;

  const CartList({
    super.key,
    required this.cart,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: cart.length,
      itemBuilder: (_, i) {
        final item = cart[i];
        return ListTile(
          title: Text(item.product.name),
          subtitle: Text(
            "จำนวน: ${item.quantity} @${item.product.price}",
          ),
          trailing: Text(item.total.toStringAsFixed(2)),
          onTap: () => onItemTap(i),
        );
      },
    );
  }
}