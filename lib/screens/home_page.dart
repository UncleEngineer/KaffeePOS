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
      cart[index].quantity = quantity;
    });
  }

  Future<void> _printReceipt() async {
    await PrinterService.printReceipt(cart, total);
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
            icon: const Icon(Icons.print),
            onPressed: cart.isEmpty ? null : _printReceipt,
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
          IconButton(
            onPressed: _showAddProductDialog,
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ).then((_) => _loadData()); // Reload data when returning from settings
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
                // Grid toggle button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_showGrid ? Icons.grid_view : Icons.list),
                        onPressed: () {
                          setState(() {
                            _showGrid = !_showGrid;
                          });
                        },
                        tooltip: _showGrid ? 'เปลี่ยนเป็นมุมมองรายการ' : 'เปลี่ยนเป็นมุมมองตาราง',
                      ),
                      const Spacer(),
                      if (categories.isNotEmpty && _currentCategoryIndex < categories.length)
                        Text(
                          '${categories[_currentCategoryIndex].title} (${currentCategoryProducts.length} รายการ)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                    ],
                  ),
                ),

                // Product display area
                Expanded(
                  flex: 3,
                  child: currentCategoryProducts.isEmpty
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
                      : _showGrid
                          ? ProductGrid(
                              products: currentCategoryProducts,
                              onProductTap: _addToCart,
                              scrollable: true,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: currentCategoryProducts.length,
                              itemBuilder: (context, index) {
                                final product = currentCategoryProducts[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(product.name),
                                    subtitle: Text('฿${product.price.toStringAsFixed(2)}'),
                                    trailing: ElevatedButton(
                                      onPressed: () => _addToCart(product),
                                      child: const Text('เพิ่ม'),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),

                const Divider(),

                // Cart area
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: CartList(
                          cart: cart,
                          onItemTap: _showEditQuantityDialog,
                        ),
                      ),
                      // Total
                      Container(
                        padding: const EdgeInsets.all(16.0),
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: cart.isEmpty ? null : _printReceipt,
                              icon: const Icon(Icons.print),
                              label: const Text('พิมพ์'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
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