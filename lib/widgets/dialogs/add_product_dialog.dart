import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/database_service.dart';

class AddProductDialog extends StatefulWidget {
  final void Function(String name, double price, int categoryId) onAdd;

  const AddProductDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  List<Category> categories = [];
  Category? selectedCategory;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await DatabaseService.getCategories();
      setState(() {
        categories = loadedCategories;
        selectedCategory = loadedCategories.isNotEmpty ? loadedCategories.first : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดหมวดหมู่: $e')),
        );
      }
    }
  }

  void _handleAdd() {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text) ?? 0;
    
    if (name.isEmpty || price <= 0 || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง')),
      );
      return;
    }

    widget.onAdd(name, price, selectedCategory!.id!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AlertDialog(
      title: const Text('เพิ่มสินค้า'),
      content: isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.6, // Responsive height
                maxWidth: double.maxFinite,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อสินค้า',
                        border: OutlineInputBorder(),
                        hintText: 'กรอกชื่อสินค้า',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ราคา',
                        border: OutlineInputBorder(),
                        hintText: 'กรอกราคาสินค้า',
                        prefixText: '฿ ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Category>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'หมวดหมู่',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: category.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    category.code,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Category? value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    if (categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ยังไม่มีหมวดหมู่ในระบบ กรุณาเพิ่มหมวดหมู่ก่อน',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: categories.isEmpty ? null : _handleAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('เพิ่ม'),
        ),
      ],
    );
  }
}