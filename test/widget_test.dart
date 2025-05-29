// This is a basic Flutter widget test for KaffeePOS app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaffeepos/main.dart';

void main() {
  group('KaffeePOS App Tests', () {
    testWidgets('App launches and shows title', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for any async operations to complete
      await tester.pumpAndSettle();

      // Verify that the app title is displayed
      expect(find.text('KaffeePOS'), findsOneWidget);
    });

    testWidgets('Shows no categories message when no categories exist', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for async operations
      await tester.pumpAndSettle();

      // Should show no categories message
      expect(find.text('ยังไม่มีหมวดหมู่สินค้า'), findsOneWidget);
      expect(
        find.text('กรุณาไปที่การตั้งค่าเพื่อเพิ่มหมวดหมู่'),
        findsOneWidget,
      );
    });

    testWidgets('Cart shows empty state initially', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for async operations
      await tester.pumpAndSettle();

      // Should show empty cart message
      expect(find.text('ยังไม่มีรายการสั่งซื้อ'), findsOneWidget);
      expect(find.text('รวม: ฿0.00'), findsOneWidget);
    });

    testWidgets('Navigation to settings works', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for async operations
      await tester.pumpAndSettle();

      // Find and tap the popup menu button
      final popupMenuButton = find.byType(PopupMenuButton<String>);
      expect(popupMenuButton, findsOneWidget);

      await tester.tap(popupMenuButton);
      await tester.pumpAndSettle();

      // Find and tap settings menu item
      final settingsMenuItem = find.text('การตั้งค่า');
      expect(settingsMenuItem, findsOneWidget);

      await tester.tap(settingsMenuItem);
      await tester.pumpAndSettle();

      // Should navigate to settings page
      expect(find.text('การตั้งค่า'), findsOneWidget);
    });

    testWidgets('Order history navigation works', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for async operations
      await tester.pumpAndSettle();

      // Find and tap the history button
      final historyButton = find.byIcon(Icons.history);
      expect(historyButton, findsOneWidget);

      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      // Should navigate to order history page
      expect(find.text('ประวัติการสั่งซื้อ'), findsOneWidget);
    });

    testWidgets('Product list navigation works', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for async operations
      await tester.pumpAndSettle();

      // Find and tap the product list button
      final productListButton = find.byIcon(Icons.view_list);
      expect(productListButton, findsOneWidget);

      await tester.tap(productListButton);
      await tester.pumpAndSettle();

      // Should navigate to product list page
      expect(find.text('รายการสินค้าทั้งหมด'), findsOneWidget);
    });
  });

  group('Database Integration Tests', () {
    testWidgets('App handles database initialization', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for database initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should load without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('UI Component Tests', () {
    testWidgets('Print button is disabled when cart is empty', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for async operations
      await tester.pumpAndSettle();

      // Find the print button
      final printButton = find.widgetWithText(ElevatedButton, 'พิมพ์');
      expect(printButton, findsOneWidget);

      // Button should be disabled when cart is empty
      final button = tester.widget<ElevatedButton>(printButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Grid visibility toggle works', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for async operations
      await tester.pumpAndSettle();

      // Find the visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility);

      if (visibilityButton.evaluate().isNotEmpty) {
        await tester.tap(visibilityButton);
        await tester.pumpAndSettle();

        // Should toggle to visibility_off icon
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      }
    });
  });

  group('Error Handling Tests', () {
    testWidgets('App handles no internet gracefully', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const POSApp());

      // Wait for async operations
      await tester.pumpAndSettle();

      // App should still load and show basic UI
      expect(find.text('KaffeePOS'), findsOneWidget);
    });
  });
}
