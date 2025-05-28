import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/database_service.dart';
import '../services/qr_scanner_service.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<Order> orders = [];
  List<Order> filteredOrders = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    try {
      final loadedOrders = await DatabaseService.getOrders();
      setState(() {
        orders = loadedOrders;
        filteredOrders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    }
  }

  void _filterOrders(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredOrders = orders;
      } else {
        // Remove # from search query and search
        String cleanQuery = query.replaceAll('#', '').toLowerCase();
        filteredOrders =
            orders.where((order) {
              String billNumber =
                  order.billNumber.replaceAll('#', '').toLowerCase();
              return billNumber.contains(cleanQuery);
            }).toList();
      }
    });
  }

  Future<void> _scanQRCode() async {
    try {
      final result = await QRScannerService.scanQRCode(context);
      if (result != null) {
        // นำผลลัพธ์ไปใส่ในช่องค้นหา
        _searchController.text = result;
        _filterOrders(result);

        // หากพบบิลที่ตรงกัน ให้เปิดหน้ารายละเอียดเลย
        final matchingOrders =
            filteredOrders.where((order) {
              String billNumber = order.billNumber.replaceAll('#', '');
              String searchQuery = result.replaceAll('#', '');
              return billNumber == searchQuery;
            }).toList();

        if (matchingOrders.isNotEmpty) {
          // เปิดหน้ารายละเอียดของบิลที่พบ
          final selectedOrder = matchingOrders.first;
          await _navigateToOrderDetail(selectedOrder);
        } else {
          // แสดงข้อความแจ้งเตือนหากไม่พบบิล
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ไม่พบบิลหมายเลข $result'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการสแกน QR Code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ฟังก์ชันสำหรับไปยังหน้ารายละเอียด
  Future<void> _navigateToOrderDetail(Order order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => OrderDetailPage(order: order, onEditOrder: _handleEditOrder),
      ),
    );

    // หากมีผลลัพธ์กลับมา (เช่น order ที่ถูกแก้ไข)
    if (result != null) {
      // ส่งผลลัพธ์กลับไปยังหน้า Home
      Navigator.pop(context, result);
    }
  }

  // ฟังก์ชันจัดการการแก้ไขออร์เดอร์
  Future<void> _handleEditOrder(Order order) async {
    // ส่งออร์เดอร์กลับไปยังหน้า Home
    Navigator.pop(context, order);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการสั่งซื้อ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode,
            tooltip: 'สแกน QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with QR scanner button
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'ค้นหาเลขบิล',
                      hintText: 'เช่น #0001 หรือ 1',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterOrders,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                    ),
                    onPressed: _scanQRCode,
                    tooltip: 'สแกน QR Code',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredOrders.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchController.text.isEmpty
                                ? Icons.receipt_long_outlined
                                : Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'ยังไม่มีประวัติการสั่งซื้อ'
                                : 'ไม่พบข้อมูลที่ค้นหา',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          if (_searchController.text.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _scanQRCode,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('สแกน QR Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  order.billNumber,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            title: Text(
                              '฿${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(order.date),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '${order.items.length} รายการ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _navigateToOrderDetail(order),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanQRCode,
        tooltip: 'สแกน QR Code',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
