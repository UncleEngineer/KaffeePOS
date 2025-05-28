import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/printer_service.dart';
import '../widgets/product_grid.dart';
import '../widgets/cart_list.dart';
import '../widgets/dialogs/add_product_dialog.dart';
import '../widgets/dialogs/edit_quantity_dialog.dart';
import 'product_list_page.dart';
import 'settings_page.dart';
import 'order_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Product> products = [];
  List<Category> categories = [];
  List<CartItem> cart = [];
  bool _showGrid = true;
  TabController? _tabController;
  int _currentCategoryIndex = 0;
  int _currentPage = 0; // For pagination
  final int _itemsPerPage = 6; // Show 6 items per page

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadCategories();
    await _loadProducts();
  }

  Future<void> _loadCategories() async {
    final loadedCategories = await DatabaseService.getCategories();
    setState(() {
      categories = loadedCategories;
      if (categories.isNotEmpty) {
        _tabController?.dispose();
        _tabController = TabController(
          length: categories.length,
          vsync: this,
          initialIndex: _currentCategoryIndex.clamp(0, categories.length - 1),
        );
        _tabController!.addListener(() {
          if (!_tabController!.indexIsChanging) {
            setState(() {
              _currentCategoryIndex = _tabController!.index;
              _resetPageWhenCategoryChanged(); // Reset page when category changes
            });
          }
        });
      }
    });
  }

  Future<void> _loadProducts() async {
    final loadedProducts = await DatabaseService.getProducts();
    setState(() {
      products = loadedProducts;
    });
  }

  List<Product> get currentCategoryProducts {
    if (categories.isEmpty || _currentCategoryIndex >= categories.length) {
      return [];
    }
    final currentCategory = categories[_currentCategoryIndex];
    return products.where((p) => p.categoryId == currentCategory.id).toList();
  }

  List<Product> get paginatedProducts {
    if (!_showGrid) return currentCategoryProducts; // No pagination when grid is hidden
    
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, currentCategoryProducts.length);
    
    if (startIndex >= currentCategoryProducts.length) return [];
    return currentCategoryProducts.sublist(startIndex, endIndex);
  }

  int get totalPages {
    if (currentCategoryProducts.isEmpty) return 0;
    return (currentCategoryProducts.length / _itemsPerPage).ceil();
  }

  void _goToNextPage() {
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _resetPageWhenCategoryChanged() {
    setState(() {
      _currentPage = 0;
    });
  }

  Future<void> _addProduct(String name, double price, int categoryId) async {
    await DatabaseService.addProduct(name, price, categoryId);
    _loadProducts();
  }

  Future<void> _editProduct(Product product, String name, double price, int categoryId) async {
    final updatedProduct = Product(
      id: product.id,
      name: name,
      price: price,
      categoryId: categoryId,
    );
    await DatabaseService.updateProduct(updatedProduct);
    _loadProducts();
  }

  Future<void> _deleteProduct(Product product) async {
    await DatabaseService.deleteProduct(product);
    _loadProducts();
  }

  double get total => cart.fold(0, (sum, item) => sum + item.total);

  void _addToCart(Product product) {
    setState(() {
      final existing = cart.where((item) => item.product.id == product.id).toList();
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        cart.add(CartItem(product));
      }
    });
  }

  void _updateCartItemQuantity(int index, int quantity) {
    setState(() {
      if (quantity > 0) {
        cart[index].quantity = quantity;
      } else {
        // ถ้าจำนวนเป็น 0 หรือน้อยกว่า ให้ลบสินค้าออกจากตะกร้า
        cart.removeAt(index);
      }
    });
  }

  // เพิ่มฟังก์ชันสำหรับลบสินค้าออกจากตะกร้า
  void _removeCartItem(int index) {
    setState(() {
      cart.removeAt(index);
    });
    
    // แสดงข้อความแจ้งเตือน
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ลบสินค้าออกจากตะกร้าแล้ว'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _printReceipt() async {
    final billNumber = await DatabaseService.generateBillNumber();
    final shopName = await DatabaseService.getShopName();
    
    // Save order to database BEFORE printing
    await DatabaseService.saveOrder(cart, total, billNumber, shopName);
    
    // Print receipt with the same bill number
    await PrinterService.printReceipt(cart, total, billNumber, shopName);
    
    setState(() => cart.clear());
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onAdd: (name, price, categoryId) => _addProduct(name, price, categoryId),
      ),
    );
  }

  void _showEditQuantityDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => EditQuantityDialog(
        cartItem: cart[index],
        onUpdate: (quantity) => _updateCartItemQuantity(index, quantity),
        onDelete: () => _removeCartItem(index), // เชื่อมต่อฟังก์ชันลบ
      ),
    );
  }

  void _showQuickAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เพิ่มสินค้า - ${categories[_currentCategoryIndex].title}'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: currentCategoryProducts.length,
            itemBuilder: (context, index) {
              final product = currentCategoryProducts[index];
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: () {
                  _addToCart(product);
                  Navigator.of(context).pop();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '฿${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 9, color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KaffeePOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
              );
            },
            tooltip: 'ประวัติการสั่งซื้อ',
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductListPage()),
              );
              _loadProducts();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                  _loadData();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('การตั้งค่า'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: categories.isNotEmpty && _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: categories.map((category) {
                  return Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            : null,
      ),
      body: categories.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีหมวดหมู่สินค้า',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'กรุณาไปที่การตั้งค่าเพื่อเพิ่มหมวดหมู่',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Grid toggle button (moved to minimal design)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      const Spacer(), // Push buttons to the right
                    ],
                  ),
                ),

                // Product display area (only show when _showGrid is true)
                if (_showGrid)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Pagination controls
                        if (totalPages > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                                  icon: const Icon(Icons.chevron_left),
                                  tooltip: 'หน้าก่อน',
                                ),
                                Text(
                                  '${_currentPage + 1} / $totalPages',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  onPressed: _currentPage < totalPages - 1 ? _goToNextPage : null,
                                  icon: const Icon(Icons.chevron_right),
                                  tooltip: 'หน้าถัดไป',
                                ),
                              ],
                            ),
                          ),
                        // Product grid
                        Expanded(
                          child: paginatedProducts.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'ไม่มีสินค้าในหมวดหมู่นี้',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ProductGrid(
                                  products: paginatedProducts,
                                  onProductTap: _addToCart,
                                  scrollable: false, // No scroll needed with pagination
                                  compact: true, // New compact mode
                                ),
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 1),

                // Cart area (expands when grid is hidden)
                Expanded(
                  flex: _showGrid ? 3 : 5,
                  child: Column(
                    children: [
                      // Cart header with Quick Add when grid is hidden
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shopping_cart, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'รายการสั่งซื้อ (${cart.length} รายการ)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                // Visibility toggle button
                                IconButton(
                                  icon: Icon(_showGrid ? Icons.visibility : Icons.visibility_off, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _showGrid = !_showGrid;
                                    });
                                  },
                                  tooltip: _showGrid ? 'ซ่อนปุ่มสินค้า' : 'แสดงปุ่มสินค้า',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                if (!_showGrid && currentCategoryProducts.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                                    onPressed: () => _showQuickAddDialog(),
                                    tooltip: 'เพิ่มสินค้าเร็ว',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            // Quick add product list when grid is hidden - REMOVED
                            // Only keep the add_circle button above
                          ],
                        ),
                      ),
                      // Cart list
                      Expanded(
                        child: cart.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'ยังไม่มีรายการสั่งซื้อ',
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : CartList(
                                cart: cart,
                                onItemTap: _showEditQuantityDialog,
                              ),
                      ),
                      // Total
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "รวม: ฿${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: cart.isEmpty ? null : _printReceipt,
                              icon: const Icon(Icons.print, size: 18),
                              label: const Text('พิมพ์', style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}