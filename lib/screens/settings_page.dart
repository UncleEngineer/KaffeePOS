import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'category_list_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _shopNameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _currentGridLayout = '3x2'; // Default grid layout

  // Grid layout options
  final Map<String, GridLayoutConfig> _gridLayouts = {
    '3x2': GridLayoutConfig(columns: 3, rows: 2, label: '3x2 (6 ปุ่มต่อหน้า)'),
    '3x3': GridLayoutConfig(columns: 3, rows: 3, label: '3x3 (9 ปุ่มต่อหน้า)'),
    '4x2': GridLayoutConfig(columns: 4, rows: 2, label: '4x2 (8 ปุ่มต่อหน้า)'),
    '4x3': GridLayoutConfig(columns: 4, rows: 3, label: '4x3 (12 ปุ่มต่อหน้า)'),
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final shopName = await DatabaseService.getShopName();
      final gridLayout = await DatabaseService.getSetting(
        'grid_layout',
        defaultValue: '3x2',
      );

      setState(() {
        _shopNameController.text = shopName;
        _currentGridLayout = gridLayout;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดการตั้งค่า: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveShopName() async {
    if (_shopNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อร้าน')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await DatabaseService.setShopName(_shopNameController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกชื่อร้านสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveGridLayout(String layout) async {
    try {
      await DatabaseService.setSetting('grid_layout', layout);
      setState(() {
        _currentGridLayout = layout;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'บันทึกการตั้งค่า Grid Layout เป็น ${_gridLayouts[layout]?.label} สำเร็จ',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกการตั้งค่า: $e')),
        );
      }
    }
  }

  void _showShopNameDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('แก้ไขชื่อร้าน'),
            content: TextField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อร้าน',
                hintText: 'กรอกชื่อร้านที่จะแสดงบนใบเสร็จ',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed:
                    _isSaving
                        ? null
                        : () async {
                          await _saveShopName();
                          if (mounted) Navigator.of(context).pop();
                        },
                child: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก'),
              ),
            ],
          ),
    );
  }

  void _showGridLayoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('เลือกรูปแบบ Grid'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._gridLayouts.entries.map((entry) {
                  final key = entry.key;
                  final config = entry.value;
                  final isSelected = _currentGridLayout == key;

                  return RadioListTile<String>(
                    title: Text(config.label),
                    subtitle: Text(
                      '${config.columns} คอลัมน์ x ${config.rows} แถว',
                    ),
                    value: key,
                    groupValue: _currentGridLayout,
                    selected: isSelected,
                    activeColor: Colors.blue,
                    onChanged: (String? value) {
                      if (value != null) {
                        Navigator.of(context).pop();
                        _saveGridLayout(value);
                      }
                    },
                    secondary: Container(
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(2),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: config.columns,
                          mainAxisSpacing: 1,
                          crossAxisSpacing: 1,
                        ),
                        itemCount: config.columns * config.rows,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.blue : Colors.grey[400],
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ],
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
        title: const Text('การตั้งค่า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Shop Settings Section
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.store, color: Colors.blue),
                          title: const Text('ชื่อร้าน'),
                          subtitle: Text(
                            _shopNameController.text.isEmpty
                                ? 'Uncle Coffee Shop'
                                : _shopNameController.text,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showShopNameDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Display Settings Section
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.grid_view,
                            color: Colors.orange,
                          ),
                          title: const Text('รูปแบบ Grid ปุ่มสินค้า'),
                          subtitle: Text(
                            _gridLayouts[_currentGridLayout]?.label ??
                                '3x2 (6 ปุ่มต่อหน้า)',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showGridLayoutDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Management Section
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.category,
                            color: Colors.green,
                          ),
                          title: const Text('จัดการหมวดหมู่สินค้า'),
                          subtitle: const Text('เพิ่ม แก้ไข ลบหมวดหมู่สินค้า'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CategoryListPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Grid Preview Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.preview, color: Colors.purple),
                              const SizedBox(width: 8),
                              Text(
                                'ตัวอย่าง Grid Layout',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        _gridLayouts[_currentGridLayout]
                                            ?.columns ??
                                        3,
                                    childAspectRatio:
                                        _gridLayouts[_currentGridLayout]
                                                    ?.columns ==
                                                4
                                            ? 2.0
                                            : 1.7,
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                  ),
                              itemCount:
                                  (_gridLayouts[_currentGridLayout]?.columns ??
                                      3) *
                                  (_gridLayouts[_currentGridLayout]?.rows ?? 2),
                              itemBuilder: (context, index) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'แสดง ${(_gridLayouts[_currentGridLayout]?.columns ?? 3) * (_gridLayouts[_currentGridLayout]?.rows ?? 2)} ปุ่มต่อหน้า',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Receipt Preview Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                'ตัวอย่างใบเสร็จ',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '#0001',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _shopNameController.text.isEmpty
                                      ? 'Uncle Coffee Shop'
                                      : _shopNameController.text,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Date: ${DateTime.now().toString().substring(0, 16)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                const Text('x1  Coffee       @50      50.00'),
                                const Text('x2  Tea         @30      60.00'),
                                const Divider(),
                                const Text(
                                  'Total: 110.00',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

class GridLayoutConfig {
  final int columns;
  final int rows;
  final String label;

  GridLayoutConfig({
    required this.columns,
    required this.rows,
    required this.label,
  });
}
