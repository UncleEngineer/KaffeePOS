import 'package:intl/intl.dart';
import '../models/cart_item.dart';

// Mock Printer Service สำหรับการทดสอบโดยไม่ต้องใช้ Sunmi Printer
class PrinterService {
  static Future<void> initialize() async {
    print('🖨️ Printer initialized (Mock)');
  }

  static Future<void> printReceipt(List<CartItem> cart, double total, String billNumber, String shopName) async {
    final transactionId = DateTime.now().millisecondsSinceEpoch;
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

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
    
    print('✅ Receipt $billNumber printed successfully (Mock)');
  }
}