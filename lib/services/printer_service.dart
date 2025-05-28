import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/cart_item.dart';

class PrinterService {
  static Future<void> initialize() async {
    await SunmiPrinter.bindingPrinter();
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
  }

  // ฟังก์ชันแปลงข้อความเป็นรูปภาพแล้วปริ้น (ใช้ monospace font)
  static Future<void> printTextAsImage(
    String text, {
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.left,
  }) async {
    var builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontStyle: FontStyle.normal,
        fontSize: fontSize,
        fontWeight: fontWeight,
        textAlign: textAlign,
        fontFamily: 'monospace', // ใช้ monospace font
      ),
    );

    builder.pushStyle(
      ui.TextStyle(
        color: ui.Color(0xFF000000),
        fontFamily: 'monospace', // ตั้งค่า monospace font
      ),
    );
    builder.addText(text);
    builder.pop();

    ui.Paragraph paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: 580));

    final recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    double textHeight = paragraph.height + 10;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, 580, textHeight),
      Paint()..color = Colors.white,
    );
    canvas.drawParagraph(paragraph, Offset.zero);

    final picture = recorder.endRecording();
    var image = await picture.toImage(580, textHeight.toInt());
    ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);

    if (data != null) {
      final Uint8List bytes = data.buffer.asUint8List();
      await SunmiPrinter.printImage(bytes);
    }
  }

  // ฟังก์ชันคำนวณความกว้างที่เหมาะสำหรับภาษาไทย (แบบง่าย)
  static double calculateThaiCompatibleWidth(String text) {
    double width = 0.0;

    for (int i = 0; i < text.length; i++) {
      int code = text.codeUnitAt(i);

      // ตัวอักษรไทย
      if (code >= 0x0E00 && code <= 0x0E7F) {
        // วรรณยุกต์และสระบน-ล่าง - ไม่มีความกว้าง
        if ((code >= 0x0E48 && code <= 0x0E4B) || // วรรณยุกต์
            (code >= 0x0E34 && code <= 0x0E3A) || // สระบน-ล่าง
            code == 0x0E47 ||
            code == 0x0E4C) {
          // ไม้ไผ่, ไม้หันอากาศ
          continue;
        }
        // สระหน้า - แคบกว่า
        else if (code == 0x0E40 ||
            code == 0x0E41 ||
            code == 0x0E42 ||
            code == 0x0E43 ||
            code == 0x0E44) {
          width += 0.8;
        }
        // พยัญชนะไทยปกติ
        else {
          width += 1.0;
        }
      }
      // ตัวเลขและอังกฤษ
      else if ((code >= 0x0030 && code <= 0x0039) || // 0-9
          (code >= 0x0041 && code <= 0x005A) || // A-Z
          (code >= 0x0061 && code <= 0x007A)) {
        // a-z
        width += 0.6;
      }
      // สัญลักษณ์
      else if (code == 0x0040 ||
          code == 0x002E ||
          code == 0x003A ||
          code == 0x0078 ||
          code == 0x0020) {
        // @ . : x space
        width += 0.5;
      }
      // อื่นๆ
      else {
        width += 0.8;
      }
    }

    return width;
  }

  // ฟังก์ชันสร้าง space แบบเรียบง่าย - ใช้ regular space เท่านั้น
  static String createSimpleSpaces(int spaceCount) {
    if (spaceCount <= 0) {
      return ' '; // อย่างน้อย 1 space
    }
    return ' ' * spaceCount;
  }

  // ฟังก์ชันสร้างบรรทัดที่มี right alignment สำหรับ monospace font
  static String createMonospaceAlignedLine(
    String leftText,
    String rightText, {
    int lineWidth = 40,
  }) {
    print("Left: '$leftText' (length: ${leftText.length})");
    print("Right: '$rightText' (length: ${rightText.length})");

    // สำหรับ monospace font ทุกตัวอักษรมีความกว้างเท่ากัน
    int leftLength = leftText.length;
    int rightLength = rightText.length;
    int spacesNeeded = lineWidth - leftLength - rightLength;

    // ตรวจสอบว่าพื้นที่เพียงพอหรือไม่
    if (spacesNeeded < 2) {
      spacesNeeded = 2; // อย่างน้อย 2 spaces
      print(
        "Warning: Text too long for line width $lineWidth, using minimum spaces",
      );
    }

    // จำกัดจำนวน spaces สูงสุด
    if (spacesNeeded > 20) {
      spacesNeeded = 20;
      print("Warning: Too many spaces needed, limiting to 20");
    }

    print("Line width: $lineWidth");
    print("Spaces needed: $spacesNeeded");

    String spaces = ' ' * spacesNeeded;
    String result = leftText + spaces + rightText;

    print("Final: '$result'");
    print("Final length: ${result.length}");
    print("Expected length: ${leftLength + spacesNeeded + rightLength}");
    print("---");

    return result;
  }

  static Future<void> printReceipt(
    List<CartItem> cart,
    double total,
    String billNumber,
    String shopName,
  ) async {
    final transactionId = DateTime.now().millisecondsSinceEpoch;
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

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

    // ปริ้นรายการสินค้าด้วยการคำนวณความกว้างที่แม่นยำ
    for (var item in cart) {
      String qtyText = "x${item.quantity}";
      String nameText =
          item.product.name.length > 15
              ? item.product.name.substring(0, 15) + "~"
              : item.product.name;
      String priceText = "@${item.product.price.toStringAsFixed(0)}";
      String subtotalText = item.total.toStringAsFixed(2);

      // สร้าง leftPart
      String leftPart = "$qtyText $nameText $priceText";

      // ใช้ฟังก์ชันสำหรับ monospace font
      String alignedLine = createMonospaceAlignedLine(
        leftPart,
        subtotalText,
        lineWidth: 38,
      );

      // ปริ้นด้วย monospace font เพื่อให้ alignment ถูกต้อง
      await printTextAsImage(alignedLine, fontSize: 16);
    }

    // Print total
    await SunmiPrinter.lineWrap(1);
    // String totalLine = createMonospaceAlignedLine(
    //   "Total:",
    //   total.toStringAsFixed(2),
    //   lineWidth: 38,
    // );
    // await printTextAsImage(
    //   totalLine,
    //   fontSize: 30,
    //   fontWeight: FontWeight.bold,
    // );
    final formatter = NumberFormat('#,##0.00');

    await SunmiPrinter.printText(
      'Total: ${formatter.format(total)}',
      style: SunmiStyle(
        align: SunmiPrintAlign.CENTER,
        fontSize: SunmiFontSize.XL,
      ),
    );

    // Print separator line
    await SunmiPrinter.printText(
      "-----------------------",
      style: SunmiStyle(align: SunmiPrintAlign.CENTER),
    );

    await SunmiPrinter.lineWrap(3);
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint();
  }
}
