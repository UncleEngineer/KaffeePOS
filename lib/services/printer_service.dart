import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import 'database_service.dart';

class PrinterService {
  static Future<void> initialize() async {
    await SunmiPrinter.bindingPrinter();
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
  }

  static Future<void> printReceipt(List<CartItem> cart, double total) async {
    final transactionId = DateTime.now().millisecondsSinceEpoch;
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final billNumber = await DatabaseService.generateBillNumber();
    final shopName = await DatabaseService.getShopName();

    await initialize();
    await SunmiPrinter.startTransactionPrint(true);

    // Print bill number
    await SunmiPrinter.printText(
      billNumber,
      style: SunmiStyle(
        bold: true,
        align: SunmiPrintAlign.CENTER,
        fontSize: SunmiFontSize.XL,
      ),
    );

    // Print QR code
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printQRCode(billNumber);
    await SunmiPrinter.lineWrap(1);

    // Print shop info (use dynamic shop name)
    await SunmiPrinter.printText(
      shopName,
      style: SunmiStyle(bold: true, align: SunmiPrintAlign.CENTER),
    );

    await SunmiPrinter.printText(
      'Date: $date',
      style: SunmiStyle(align: SunmiPrintAlign.CENTER),
    );

    await SunmiPrinter.printText(
      'Transaction ID: $transactionId',
      style: SunmiStyle(align: SunmiPrintAlign.CENTER),
    );

    await SunmiPrinter.lineWrap(1);

    // Print cart items
    for (var item in cart) {
      String qtyFixed = "x${item.quantity}".padRight(4);
      String nameFixed = item.product.name.length > 12
          ? item.product.name.substring(0, 12)
          : item.product.name.padRight(12);
      String priceFixed = "@${item.product.price.toStringAsFixed(0)}".padRight(5);
      String subtotalFixed = item.total.toStringAsFixed(2).padLeft(7);

      String line = qtyFixed + nameFixed + priceFixed + subtotalFixed;
      await SunmiPrinter.printText(line);
    }

    // Print total
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printText(
      "Total: 	${total.toStringAsFixed(2)}",
      style: SunmiStyle(bold: true),
    );
    
    await SunmiPrinter.lineWrap(3);
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint();
  }
}