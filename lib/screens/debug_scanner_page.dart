// หน้าทดสอบ Mobile Scanner (เวอร์ชันที่ทำงานได้)
// เพิ่มลงในไฟล์ lib/screens/debug_scanner_page.dart

import 'package:flutter/material.dart';
import '../services/qr_scanner_service.dart';

class DebugScannerPage extends StatefulWidget {
  const DebugScannerPage({super.key});

  @override
  State<DebugScannerPage> createState() => _DebugScannerPageState();
}

class _DebugScannerPageState extends State<DebugScannerPage> {
  String? scannedValue;
  bool isScanning = false;
  List<String> scanHistory = [];

  // ทดสอบการสแกนครั้งเดียว
  Future<void> _testSingleScan() async {
    setState(() {
      isScanning = true;
      scannedValue = null;
    });

    try {
      final result = await QRScannerService.scanQRCode(context);

      if (mounted) {
        setState(() {
          scannedValue = result;
          if (result != null) {
            scanHistory.insert(
              0,
              '${DateTime.now().toString().substring(11, 19)}: $result',
            );
            if (scanHistory.length > 10) {
              scanHistory = scanHistory.take(10).toList();
            }
          }
        });
      }

      print('Single scan result: $result');
    } catch (e) {
      print('Single scan error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  // ทดสอบการสแกนแบบกำหนดเวลา
  Future<void> _testTimeoutScan() async {
    setState(() {
      isScanning = true;
      scannedValue = null;
    });

    try {
      final result = await QRScannerService.scanWithTimeout(
        context,
        timeoutSeconds: 15,
        showSuccessMessage: true,
      );

      if (mounted) {
        setState(() {
          scannedValue = result;
          if (result != null) {
            scanHistory.insert(
              0,
              '${DateTime.now().toString().substring(11, 19)}: $result',
            );
            if (scanHistory.length > 10) {
              scanHistory = scanHistory.take(10).toList();
            }
          }
        });
      }

      print('Timeout scan result: $result');
    } catch (e) {
      print('Timeout scan error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  // เคลียร์ข้อมูล
  void _clearData() {
    setState(() {
      scannedValue = null;
      scanHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Mobile Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Mobile Scanner Debug - ทดสอบการสแกน QR Code ด้วยกล้อง',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // สถานะปัจจุบัน
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สถานะปัจจุบัน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('กำลังสแกน: ${isScanning ? 'ใช่' : 'ไม่'}'),
                    const Text('Scanner Type: Mobile Scanner (Camera)'),
                    Text('ประวัติ: ${scanHistory.length} รายการ'),
                    const Text('API: mobile_scanner ^3.5.6'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ผลลัพธ์ล่าสุด
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ผลลัพธ์ล่าสุด',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                      child: Text(
                        scannedValue ?? 'ยังไม่ได้สแกน',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              scannedValue != null ? Colors.green : Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ปุ่มควบคุม
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: isScanning ? null : _testSingleScan,
                  icon:
                      isScanning
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.qr_code_scanner),
                  label: Text(isScanning ? 'กำลังสแกน...' : 'สแกน QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: isScanning ? null : _testTimeoutScan,
                  icon: const Icon(Icons.timer),
                  label: const Text('สแกนแบบจำกัดเวลา'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: _clearData,
                  icon: const Icon(Icons.clear),
                  label: const Text('เคลียร์ข้อมูล'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // คำแนะนำการใช้งาน
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'คำแนะนำ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• กดปุ่ม "สแกน QR Code" เพื่อเปิดกล้อง\n'
                      '• จ่อ QR Code ที่กรอบสีเขียว\n'
                      '• สามารถเปิด/ปิดไฟแฟลชได้\n'
                      '• สามารถสลับกล้องหน้า/หลังได้',
                      style: TextStyle(color: Colors.blue[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ประวัติการสแกน
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'ประวัติการสแกน (10 รายการล่าสุด)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child:
                          scanHistory.isEmpty
                              ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'ยังไม่มีประวัติการสแกน',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'กดปุ่มสแกนเพื่อเริ่มทดสอบ',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                itemCount: scanHistory.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.green,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      scanHistory[index],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.copy, size: 16),
                                      onPressed: () {
                                        final value =
                                            scanHistory[index].split(': ').last;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('คัดลอก: $value'),
                                            duration: const Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
