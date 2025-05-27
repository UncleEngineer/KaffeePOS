import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import 'database_service.dart';

// Mock Printer Service สำหรับการทดสอบโดยไม่ต้องใช้ Sunmi Printer
class PrinterService {
  static Future<void> initialize() async {
    print('🖨️ Printer initialized (Mock)');
  }

  static Future<void> printReceipt(List<CartItem> cart, double total) async {
    final transactionId = DateTime.now().millisecondsSinceEpoch;
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final billNumber = await DatabaseService.generateBillNumber();
    final shopName = await DatabaseService.getShopName();

    print('🧾 ========== RECEIPT ==========');
    print('🧾 $billNumber');
    print('🧾 $shopName');
    print('🧾 Date: $date');
    print('🧾 Transaction ID: $transactionId');
    print('🧾 ==============================');
    
    for (var item in cart) {
      String qtyFixed = "x${item.quantity}".padRight(4);
      String nameFixed = item.product.name.length > 12
          ? item.product.name.substring(0, 12)
          : item.product.name.padRight(12);
      String priceFixed = "@${item.product.price.toStringAsFixed(0)}".padRight(5);
      String subtotalFixed = item.total.toStringAsFixed(2).padLeft(7);

      String line = qtyFixed + nameFixed + priceFixed + subtotalFixed;
      print('🧾 $line');
    }
    
    print('🧾 ==============================');
    print('🧾 Total: ${total.toStringAsFixed(2)}');
    print('🧾 ========== END ==========');
    
    // แสดง Snackbar แจ้งเตือนว่าพิมพ์สำเร็จ (ใน real app)
    print('✅ Receipt printed successfully (Mock)');
  }
}