import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../widgets/dialogs/edit_product_dialog.dart';
import 'category_list_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> products = [];
  List<Category> categories = [];
  bool isLoading = true;
  bool isLoadingCategories = true;
  bool isSaving = false;
  bool isFormVisible = true; // เพิ่มตัวแปรสำหรับควบคุมการแสดงฟอร์ม
  
  // Form controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  Category? _selectedCategory;
  
  // Form key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(), // โหลด categories ก่อน
      _loadProducts(),
    ]);
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final loadedProducts = await DatabaseService.getProducts();
      if (mounted) {
        setState(() {
          products = loadedProducts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final loadedCategories = await DatabaseService.getCategories();
      if (mounted) {
        setState(() {
          categories = loadedCategories;
          // ตั้งค่า selectedCategory เป็น null ก่อน แล้วค่อยเลือกค่าแรก
          _selectedCategory = null;
          if (loadedCategories.isNotEmpty) {
            _selectedCategory = loadedCategories.first;
          }
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดหมวดหมู่: $e')),
        );
      }
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง')),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text);
      
      await DatabaseService.addProduct(name, price, _selectedCategory!.id!);
      
      // Clear form
      _nameController.clear();
      _priceController.clear();
      // ไม่ reset category ให้เก็บค่าเดิมไว้
      
      await _loadProducts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เพิ่มสินค้าสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่มสินค้า: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _editProduct(Product product, String name, double price, int categoryId) async {
    try {
      final updatedProduct = Product(
        id: product.id,
        name: name,
        price: price,
        categoryId: categoryId,
      );
      await DatabaseService.updateProduct(updatedProduct);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แก้ไขสินค้าสำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการแก้ไขสินค้า: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบสินค้า "${product.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.deleteProduct(product);
        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบสินค้าสำเร็จ')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการลบสินค้า: $e')),
          );
        }
      }
    }
  }

  void _showEditDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => EditProductDialog(
        product: product,
        onEdit: (name, price, categoryId) => _editProduct(product, name, price, categoryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการสินค้าทั้งหมด'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Product Form
          Container(
            padding: const EdgeInsets.all(12), // ลดจาก 16 เป็น 12
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_business, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'เพิ่มสินค้าใหม่',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isFormVisible = !isFormVisible;
                          });
                        },
                        icon: Icon(
                          isFormVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        tooltip: isFormVisible ? 'ซ่อนฟอร์ม' : 'แสดงฟอร์ม',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.all(6), // ลดจาก 8 เป็น 6
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), // ลดจาก 16 เป็น 10
                  
                  // Form fields - แสดงเฉพาะเมื่อ isFormVisible = true
                  if (isFormVisible) ...[
                    // Form fields in vertical layout
                    Column(
                      children: [
                        // Product name field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อสินค้า',
                            border: OutlineInputBorder(),
                            hintText: 'กรอกชื่อสินค้า',
                            prefixIcon: Icon(Icons.shopping_bag),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // ลด padding
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรุณากรอกชื่อสินค้า';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 10), // ลดจาก 16 เป็น 10
                        
                        // Price field
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'ราคา',
                            border: OutlineInputBorder(),
                            hintText: '0.00',
                            prefixText: '฿ ',
                            prefixIcon: Icon(Icons.attach_money),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // ลด padding
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรุณากรอกราคา';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'ราคาต้องเป็นตัวเลขมากกว่า 0';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 10), // ลดจาก 16 เป็น 10
                        
                        // Category dropdown with add button
                        Row(
                          children: [
                            Expanded(
                              child: isLoadingCategories
                                  ? Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0), // ลดจาก 16 เป็น 10
                                        child: const Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            SizedBox(width: 10),
                                            Text('กำลังโหลดหมวดหมู่...'),
                                          ],
                                        ),
                                      ),
                                    )
                                  : categories.isEmpty
                                      ? Container(
                                          padding: const EdgeInsets.all(10), // ลดจาก 12 เป็น 10
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.category, color: Colors.grey),
                                              SizedBox(width: 8),
                                              Text('ไม่มีหมวดหมู่', style: TextStyle(color: Colors.grey)),
                                            ],
                                          ),
                                        )
                                      : DropdownButtonFormField<Category>(
                                          value: _selectedCategory,
                                          decoration: const InputDecoration(
                                            labelText: 'หมวดหมู่',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.category),
                                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // ลด padding
                                          ),
                                          items: categories.map((category) {
                                            return DropdownMenuItem<Category>(
                                              value: category,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 16, // ลดจาก 20 เป็น 16
                                                    height: 16, // ลดจาก 20 เป็น 16
                                                    decoration: BoxDecoration(
                                                      color: category.color ?? Colors.grey,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        category.code ?? '',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 7, // ลดจาก 8 เป็น 7
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      category.title ?? 'ไม่มีชื่อ',
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (Category? value) {
                                            setState(() {
                                              _selectedCategory = value;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null) {
                                              return 'กรุณาเลือกหมวดหมู่';
                                            }
                                            return null;
                                          },
                                          isExpanded: true,
                                        ),
                            ),
                            const SizedBox(width: 6), // ลดจาก 8 เป็น 6
                            IconButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CategoryListPage(),
                                  ),
                                );
                                // รีโหลด categories หลังจากกลับมา
                                if (result == true || mounted) {
                                  await _loadCategories();
                                }
                              },
                              icon: const Icon(Icons.add),
                              tooltip: 'เพิ่มหมวดหมู่',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.all(6), // ลดจาก default
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12), // ลดจาก 20 เป็น 12
                        
                        // Add button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (isSaving || categories.isEmpty) ? null : _addProduct,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16, // ลดจาก 20 เป็น 16
                                    height: 16, // ลดจาก 15 เป็น 16
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: Text(
                              isSaving ? 'กำลังเพิ่มสินค้า...' : 'เพิ่มสินค้า',
                              style: const TextStyle(fontSize: 15), // ลดจาก 16 เป็น 15
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: categories.isEmpty ? Colors.grey : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12), // ลดจาก 16 เป็น 12
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Warning for no categories - แสดงเฉพาะเมื่อฟอร์มมองเห็นได้
                    if (categories.isEmpty && !isLoadingCategories)
                      Padding(
                        padding: const EdgeInsets.only(top: 10), // ลดจาก 16 เป็น 10
                        child: Container(
                          padding: const EdgeInsets.all(10), // ลดจาก 12 เป็น 10
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ยังไม่มีหมวดหมู่ในระบบ กรุณาเพิ่มหมวดหมู่ก่อนเพิ่มสินค้า',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6), // ลดจาก 8 เป็น 6
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CategoryListPage(),
                                      ),
                                    );
                                    if (result == true || mounted) {
                                      await _loadCategories();
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('เพิ่มหมวดหมู่แรก'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10), // ลด padding
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Debug info (แสดงจำนวน categories ที่โหลดได้)
                    if (categories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6), // ลดจาก 8 เป็น 6
                        child: Text(
                          'พบ ${categories.length} หมวดหมู่',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          
          // Products list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'ไม่มีสินค้าในระบบ',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'เพิ่มสินค้าแรกจากฟอร์มด้านบน',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          final product = products[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(product.name),
                              subtitle: Text("฿${product.price.toStringAsFixed(2)}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.amber),
                                    onPressed: () => _showEditDialog(context, product),
                                    tooltip: 'แก้ไข',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteProduct(product),
                                    tooltip: 'ลบ',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}