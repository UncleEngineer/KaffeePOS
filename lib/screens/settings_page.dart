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
      _shopNameController.text = shopName;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อร้าน')),
      );
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

  void _showShopNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: _isSaving
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
      body: _isLoading
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
                        subtitle: Text(_shopNameController.text.isEmpty
                            ? 'Uncle Coffee Shop'
                            : _shopNameController.text),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showShopNameDialog,
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
                        leading: const Icon(Icons.category, color: Colors.green),
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
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
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
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _shopNameController.text.isEmpty 
                                    ? 'Uncle Coffee Shop' 
                                    : _shopNameController.text,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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