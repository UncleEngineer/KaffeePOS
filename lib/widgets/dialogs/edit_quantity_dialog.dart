import 'package:flutter/material.dart';
import '../../models/cart_item.dart';

class EditQuantityDialog extends StatefulWidget {
  final CartItem cartItem;
  final void Function(int quantity) onUpdate;

  const EditQuantityDialog({
    super.key,
    required this.cartItem,
    required this.onUpdate,
  });

  @override
  State<EditQuantityDialog> createState() => _EditQuantityDialogState();
}

class _EditQuantityDialogState extends State<EditQuantityDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.cartItem.quantity.toString());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _decreaseQuantity() {
    int current = int.tryParse(controller.text) ?? widget.cartItem.quantity;
    if (current > 1) {
      controller.text = (current - 1).toString();
    }
  }

  void _increaseQuantity() {
    int current = int.tryParse(controller.text) ?? widget.cartItem.quantity;
    controller.text = (current + 1).toString();
  }

  void _handleUpdate() {
    final quantity = int.tryParse(controller.text) ?? widget.cartItem.quantity;
    widget.onUpdate(quantity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('แก้ไขจำนวน "${widget.cartItem.product.name}"'),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _decreaseQuantity,
          ),
          SizedBox(
            width: 60,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _increaseQuantity,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('ยกเลิก'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('ตกลง'),
          onPressed: _handleUpdate,
        ),
      ],
    );
  }
}