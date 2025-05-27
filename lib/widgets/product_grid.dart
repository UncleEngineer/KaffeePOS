import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onProductTap;
  final bool scrollable;
  final bool compact;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.scrollable = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: scrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      shrinkWrap: !scrollable,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: compact ? 1.7 : 1.4, // ลดความสูงลง 30% โดยเพิ่ม aspect ratio
        mainAxisSpacing: compact ? 6 : 10,
        crossAxisSpacing: compact ? 6 : 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(compact ? 6 : 8),
          ),
          onPressed: () => onProductTap(product),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '฿${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: compact ? 8 : 10,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}