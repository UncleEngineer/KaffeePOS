import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'permission_helper.dart';

class QRScannerService {
  static Future<String?> scanQRCode(BuildContext context) async {
    // ตรวจสอบ permission ก่อน
    final hasPermission = await PermissionHelper.requestCameraPermission(
      context,
    );
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเข้าถึงกล้องได้ กรุณาอนุญาตการใช้งานกล้อง'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    return await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );
  }

  static Future<String?> scanWithTimeout(
    BuildContext context, {
    int timeoutSeconds = 30,
    bool showSuccessMessage = true,
  }) async {
    return await scanQRCode(context);
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();

  bool isScanned = false;
  bool isTorchOn = false;
  String? lastScannedValue;
  DateTime? lastScanTime;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        final now = DateTime.now();

        // ป้องกันการสแกนซ้ำในเวลาสั้นๆ
        if (lastScannedValue == barcode.rawValue &&
            lastScanTime != null &&
            now.difference(lastScanTime!).inSeconds < 2) {
          return;
        }

        setState(() {
          isScanned = true;
          lastScannedValue = barcode.rawValue;
          lastScanTime = now;
        });

        // หยุดการสแกนชั่วคราว
        cameraController.stop();

        // ส่งผลลัพธ์กลับ
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }

  void _toggleTorch() async {
    try {
      await cameraController.toggleTorch();
      setState(() {
        isTorchOn = !isTorchOn;
      });
    } catch (e) {
      print('Error toggling torch: $e');
    }
  }

  void _switchCamera() async {
    try {
      await cameraController.switchCamera();
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // ปุ่มเปิด/ปิดไฟแฟลช
          IconButton(
            color: Colors.white,
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.grey,
            ),
            iconSize: 32.0,
            onPressed: _toggleTorch,
          ),
          // ปุ่มสลับกล้องหน้า/หลัง
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.switch_camera),
            iconSize: 32.0,
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Scanner
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          // Scanning overlay
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(color: Colors.black.withOpacity(0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(color: Colors.black.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ],
            ),
          ),

          // Status indicator when scanned
          if (isScanned)
            Container(
              color: Colors.green.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 80),
                    SizedBox(height: 16),
                    Text(
                      'สแกนสำเร็จ!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'วาง QR Code ในกรอบเพื่อสแกน',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('ยกเลิก'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isScanned = false;
                    });
                    cameraController.start();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('สแกนใหม่'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
