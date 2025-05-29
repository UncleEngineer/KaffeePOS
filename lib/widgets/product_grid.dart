import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class ProductGrid extends StatefulWidget {
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
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  int _gridColumns = 3;
  double _aspectRatio = 1.7;
  double _fontSize = 12;
  double _priceSize = 10;
  double _padding = 8;

  @override
  void initState() {
    super.initState();
    _loadGridSettings();
  }

  Future<void> _loadGridSettings() async {
    final gridLayout = await DatabaseService.getSetting(
      'grid_layout',
      defaultValue: '3x2',
    );
    _updateGridSettings(gridLayout);
  }

  void _updateGridSettings(String layout) {
    setState(() {
      switch (layout) {
        case '3x2':
          _gridColumns = 3;
          _aspectRatio = widget.compact ? 1.7 : 1.4;
          _fontSize = widget.compact ? 10 : 12;
          _priceSize = widget.compact ? 8 : 10;
          _padding = widget.compact ? 6 : 8;
          break;
        case '3x3':
          _gridColumns = 3;
          _aspectRatio = widget.compact ? 2.5 : 1.3;
          _fontSize = widget.compact ? 10 : 12;
          _priceSize = widget.compact ? 8 : 10;
          _padding = widget.compact ? 6 : 8;
          break;
        case '4x2':
          _gridColumns = 4;
          _aspectRatio =
              widget.compact ? 1.4 : 1.2; // เพิ่ม aspect ratio เพื่อลดความสูง
          _fontSize = widget.compact ? 9 : 10; // ลดขนาดฟอนต์
          _priceSize = widget.compact ? 7 : 8;
          _padding = widget.compact ? 4 : 6; // ลด padding
          break;
        case '4x3':
          _gridColumns = 4;
          _aspectRatio = widget.compact ? 2.0 : 1.7;
          _fontSize = widget.compact ? 9 : 10;
          _priceSize = widget.compact ? 7 : 8;
          _padding = widget.compact ? 4 : 6;
          break;
        default:
          _gridColumns = 3;
          _aspectRatio = widget.compact ? 1.7 : 1.4;
          _fontSize = widget.compact ? 10 : 12;
          _priceSize = widget.compact ? 8 : 10;
          _padding = widget.compact ? 6 : 8;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics:
          widget.scrollable
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
      shrinkWrap: !widget.scrollable,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumns,
        childAspectRatio: _aspectRatio,
        mainAxisSpacing: widget.compact ? 6 : 10,
        crossAxisSpacing: widget.compact ? 6 : 10,
      ),
      itemCount: widget.products.length,
      itemBuilder: (context, index) {
        final product = widget.products[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(_padding),
          ),
          onPressed: () => widget.onProductTap(product),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    product.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines:
                        _gridColumns == 4
                            ? 2
                            : 3, // ลดจำนวนบรรทัดสำหรับ 4 คอลัมน์
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '฿${product.price.toStringAsFixed(0)}',
                style: TextStyle(fontSize: _priceSize, color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}
