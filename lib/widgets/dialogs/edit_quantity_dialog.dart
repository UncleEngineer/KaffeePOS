import 'package:flutter/material.dart';
import '../../models/cart_item.dart';

class EditQuantityDialog extends StatefulWidget {
  final CartItem cartItem;
  final void Function(int quantity) onUpdate;
  final VoidCallback? onDelete; // เพิ่ม callback สำหรับการลบ

  const EditQuantityDialog({
    super.key,
    required this.cartItem,
    required this.onUpdate,
    this.onDelete, // เพิ่ม parameter สำหรับการลบ
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

  void _handleDelete() {
    // แสดง confirmation dialog ก่อนลบ
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบ "${widget.cartItem.product.name}" ออกจากตะกร้าหรือไม่?'),
          actions: [
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ลบ'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด confirmation dialog
                Navigator.of(context).pop(); // ปิด edit quantity dialog
                widget.onDelete?.call(); // เรียก callback สำหรับลบ
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('แก้ไขจำนวน "${widget.cartItem.product.name}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
          const SizedBox(height: 16),
          // ปุ่มลบสินค้าออกจากตะกร้า
          if (widget.onDelete != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('ลบออกจากตะกร้า', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: _handleDelete,
              ),
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