import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHelper {
  /// ขอ permission สำหรับใช้กล้อง
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    // ถ้าได้รับอนุญาตแล้ว
    if (status.isGranted) {
      return true;
    }

    // ถ้ายังไม่ได้ขออนุญาต หรือ ถูกปฏิเสธ
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    // ถ้าถูกปฏิเสธถาวร
    if (status.isPermanentlyDenied) {
      // แสดง dialog แจ้งให้ไปเปิด permission ใน settings
      if (context.mounted) {
        await _showPermissionDialog(context);
      }
      return false;
    }

    // ถ้าถูก restricted (iOS)
    if (status.isRestricted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('การใช้งานกล้องถูกจำกัดโดยระบบ'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    return false;
  }

  /// แสดง dialog เมื่อ permission ถูกปฏิเสธถาวร
  static Future<void> _showPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // ผู้ใช้ต้องกดปุ่มเท่านั้น
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.orange),
              SizedBox(width: 8),
              Text('ต้องการอนุญาตใช้กล้อง'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'แอปต้องการเข้าถึงกล้องเพื่อสแกน QR Code บนใบเสร็จ',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'วิธีเปิดอนุญาต:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  '1. กดปุ่ม "เปิดการตั้งค่า"\n'
                  '2. เลือก "สิทธิ์" หรือ "Permissions"\n'
                  '3. เปิดสิทธิ์ "กล้อง" หรือ "Camera"\n'
                  '4. กลับมาที่แอปและลองใหม่',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // เปิดหน้าการตั้งค่าแอป
              },
              icon: const Icon(Icons.settings),
              label: const Text('เปิดการตั้งค่า'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// ตรวจสอบสถานะ permission ปัจจุบัน
  static Future<PermissionStatus> getCameraPermissionStatus() async {
    return await Permission.camera.status;
  }

  /// ขอ permission สำหรับเก็บไฟล์ (สำหรับอนาคต)
  static Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showStoragePermissionDialog(context);
      }
      return false;
    }

    return false;
  }

  /// แสดง dialog สำหรับ storage permission
  static Future<void> _showStoragePermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.folder, color: Colors.orange),
              SizedBox(width: 8),
              Text('ต้องการอนุญาตเข้าถึงไฟล์'),
            ],
          ),
          content: const Text(
            'แอปต้องการสิทธิ์ในการเข้าถึงไฟล์เพื่อบันทึกหรือส่งออกข้อมูล\n\n'
            'กรุณาเปิดการตั้งค่าและอนุญาตการเข้าถึงที่จัดเก็บข้อมูล',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('เปิดการตั้งค่า'),
            ),
          ],
        );
      },
    );
  }

  /// ตรวจสอบ permission หลายตัวพร้อมกัน
  static Future<Map<Permission, PermissionStatus>> checkMultiplePermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  /// แสดงข้อมูลสถานะ permission (สำหรับ debug)
  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'ได้รับอนุญาต';
      case PermissionStatus.denied:
        return 'ถูกปฏิเสธ';
      case PermissionStatus.restricted:
        return 'ถูกจำกัด';
      case PermissionStatus.limited:
        return 'อนุญาตบางส่วน';
      case PermissionStatus.permanentlyDenied:
        return 'ถูกปฏิเสธถาวร';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }
}
