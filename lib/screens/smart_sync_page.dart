import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/database_service.dart';

class SmartSyncPage extends StatefulWidget {
  const SmartSyncPage({super.key});

  @override
  State<SmartSyncPage> createState() => _SmartSyncPageState();
}

class _SmartSyncPageState extends State<SmartSyncPage> {
  final _urlController = TextEditingController();
  final _jsonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isUrlMode = true;
  bool _isLoading = false;
  List<Map<String, dynamic>> _previewData = [];
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _previewData = [];
    });

    try {
      String jsonData;
      
      if (_isUrlMode) {
        // Load from URL
        final url = _urlController.text.trim();
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          jsonData = response.body;
        } else {
          throw Exception('HTTP ${response.statusCode}: ไม่สามารถดาวน์โหลดข้อมูลได้');
        }
      } else {
        // Load from JSON text
        jsonData = _jsonController.text.trim();
      }

      // Parse JSON
      final List<dynamic> parsed = json.decode(jsonData);
      final List<Map<String, dynamic>> products = [];

      for (var item in parsed) {
        if (item is Map<String, dynamic>) {
          // Validate required fields
          if (!item.containsKey('name') || !item.containsKey('price')) {
            throw Exception('ข้อมูลไม่ครบถ้วน: ต้องมี name และ price');
          }
          
          products.add({
            'name': item['name']?.toString() ?? '',
            'price': _parsePrice(item['price']),
            'category_id': item['category_id']?.toString() ?? 'GEN',
          });
        }
      }

      if (products.isEmpty) {
        throw Exception('ไม่พบข้อมูลสินค้าที่ถูกต้อง');
      }

      setState(() {
        _previewData = products;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _parsePrice(dynamic price) {
    if (price is num) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }

  // Generate random color for new categories
  String _generateRandomColor() {
    final colors = [
      '#2196F3', // Blue
      '#4CAF50', // Green
      '#FF9800', // Orange
      '#F44336', // Red
      '#9C27B0', // Purple
      '#009688', // Teal
      '#E91E63', // Pink
      '#3F51B5', // Indigo
      '#FFC107', // Amber
      '#00BCD4', // Cyan
      '#CDDC39', // Lime
      '#FF5722', // Deep Orange
      '#607D8B', // Blue Grey
      '#795548', // Brown
    ];
    colors.shuffle();
    return colors.first;
  }

  Future<void> _syncData() async {
    if (_previewData.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load existing categories
      final categories = await DatabaseService.getCategories();
      final categoryMap = <String, int>{};
      for (var cat in categories) {
        categoryMap[cat.code] = cat.id!;
      }

      int syncedCount = 0;
      int skippedCount = 0;
      int newCategoriesCount = 0;
      List<String> errors = [];
      List<String> newCategories = [];

      for (var productData in _previewData) {
        try {
          final name = productData['name'] as String;
          final price = productData['price'] as double;
          final categoryCode = productData['category_id'] as String;

          // Check if category exists
          int? categoryId = categoryMap[categoryCode];
          if (categoryId == null) {
            // Create new category if it doesn't exist
            try {
              await DatabaseService.addCategory(
                categoryCode, // title เหมือนกับ code
                categoryCode, // code
                _generateRandomColor(), // สีแบบสุ่ม
              );
              
              // Reload categories to get the new category ID
              final updatedCategories = await DatabaseService.getCategories();
              final newCategory = updatedCategories.firstWhere((cat) => cat.code == categoryCode);
              categoryId = newCategory.id!;
              categoryMap[categoryCode] = categoryId;
              
              newCategoriesCount++;
              newCategories.add(categoryCode);
              print('Created new category: $categoryCode');
            } catch (e) {
              // If category creation fails, use default category
              categoryId = categoryMap['GEN'] ?? categories.first.id!;
              print('Failed to create category $categoryCode, using default: $e');
            }
          }

          // Check if product already exists
          final existingProducts = await DatabaseService.getProducts();
          final exists = existingProducts.any((p) => p.name.toLowerCase() == name.toLowerCase());

          if (exists) {
            skippedCount++;
            print('Skipped: $name (already exists)');
          } else {
            await DatabaseService.addProduct(name, price, categoryId);
            syncedCount++;
            print('Added: $name');
          }
        } catch (e) {
          errors.add('${productData['name']}: ${e.toString()}');
        }
      }

      // Show result
      String message = 'Sync เสร็จสิ้น!\n';
      message += 'เพิ่มสินค้าใหม่: $syncedCount รายการ\n';
      if (newCategoriesCount > 0) {
        message += 'สร้างหมวดหมู่ใหม่: $newCategoriesCount หมวดหมู่\n';
      }
      if (skippedCount > 0) {
        message += 'ข้ามสินค้าที่มีอยู่แล้ว: $skippedCount รายการ\n';
      }
      if (errors.isNotEmpty) {
        message += 'ข้อผิดพลาด: ${errors.length} รายการ';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ผลลัพธ์การ Sync'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  if (newCategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('หมวดหมู่ใหม่ที่สร้าง:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...newCategories.map((cat) => Text('• $cat', style: const TextStyle(fontSize: 12, color: Colors.green))),
                  ],
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('รายละเอียดข้อผิดพลาด:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (syncedCount > 0 || newCategoriesCount > 0) {
                    Navigator.of(context).pop(true); // Return true to indicate data was changed
                  }
                },
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }

      // Clear preview data
      setState(() {
        _previewData = [];
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการ sync: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'ช่วยเหลือ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sync_alt, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Smart Sync',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'นำเข้าข้อมูลสินค้าจาก URL หรือ JSON',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mode Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เลือกรูปแบบการนำเข้า:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('URL'),
                              subtitle: const Text('ลิงก์ไฟล์ JSON'),
                              value: true,
                              groupValue: _isUrlMode,
                              onChanged: (value) {
                                setState(() {
                                  _isUrlMode = value ?? true;
                                  _previewData = [];
                                  _errorMessage = null;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('JSON'),
                              subtitle: const Text('ข้อความ JSON'),
                              value: false,
                              groupValue: _isUrlMode,
                              onChanged: (value) {
                                setState(() {
                                  _isUrlMode = value ?? true;
                                  _previewData = [];
                                  _errorMessage = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Input Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isUrlMode) ...[
                        TextFormField(
                          controller: _urlController,
                          initialValue: 'https://raw.githubusercontent.com/UncleEngineer/KaffeePOS/refs/heads/main/examples_menu.json',
                          decoration: const InputDecoration(
                            labelText: 'URL',
                            hintText: 'https://example.com/products.json',
                            prefixIcon: Icon(Icons.link),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรุณาใส่ URL';
                            }
                            final uri = Uri.tryParse(value.trim());
                            if (uri == null || !uri.hasAbsolutePath || (!uri.isScheme('http') && !uri.isScheme('https'))) {
                              return 'URL ไม่ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        const Text(
                          'JSON Data:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _jsonController,
                          decoration: const InputDecoration(
                            hintText: '[{"name":"กาแฟ","price":50,"category_id":"BEV"}]',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 8,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรุณาใส่ข้อมูล JSON';
                            }
                            try {
                              json.decode(value.trim());
                            } catch (e) {
                              return 'รูปแบบ JSON ไม่ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Load Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadData,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                          label: Text(_isLoading ? 'กำลังโหลด...' : 'โหลดข้อมูล'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null)
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Preview Section
              if (_previewData.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.preview, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'ตัวอย่างข้อมูล (${_previewData.length} รายการ)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _previewData.length,
                            itemBuilder: (context, index) {
                              final item = _previewData[index];
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.green,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                ),
                                title: Text(item['name']),
                                subtitle: Text('฿${item['price']} | ${item['category_id']}'),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _syncData,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(_isLoading ? 'กำลัง Sync...' : 'Sync ข้อมูล'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Example Section
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'ตัวอย่าง JSON',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          '[\n'
                          '  {"name":"กาแฟ","price":50,"category_id":"BEV"},\n'
                          '  {"name":"ขนมปัง","price":10,"category_id":"GEN"},\n'
                          '  {"name":"เค้ก","price":80,"category_id":"CAKE"}\n'
                          ']',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'หมายเหตุ:\n'
                        '• หากหมวดหมู่ไม่มีอยู่ ระบบจะสร้างหมวดหมู่ใหม่อัตโนมัติ\n'
                        '• ชื่อหมวดหมู่จะเป็นเหมือนกับ category_id\n'
                        '• สีจะถูกสุ่มให้อัตโนมัติ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
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
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('วิธีใช้ Smart Sync'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. เลือกรูปแบบการนำเข้า:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• URL: ใส่ลิงก์ไฟล์ JSON'),
              Text('• JSON: วางข้อความ JSON โดยตรง'),
              SizedBox(height: 12),
              Text(
                '2. รูปแบบ JSON ที่ถูกต้อง:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• name: ชื่อสินค้า (จำเป็น)'),
              Text('• price: ราคา (จำเป็น)'),
              Text('• category_id: รหัสหมวดหมู่ (ถ้าไม่ใส่จะใช้ GEN)'),
              SizedBox(height: 12),
              Text(
                '3. การทำงาน:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• ระบบจะตรวจสอบสินค้าซ้ำ'),
              Text('• สินค้าที่มีชื่อเดียวกันจะถูกข้าม'),
              Text('• หากหมวดหมู่ไม่มี จะสร้างหมวดหมู่ใหม่อัตโนมัติ'),
              Text('• ชื่อหมวดหมู่ใหม่จะเป็นเหมือนกับ category_id'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('เข้าใจแล้ว'),
          ),
        ],
      ),
    );
  }
}