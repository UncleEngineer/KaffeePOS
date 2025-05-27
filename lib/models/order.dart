class Order {
  final int? id;
  final String billNumber;
  final DateTime date;
  final double total;
  final String shopName;
  final List<OrderItem> items;

  Order({
    this.id,
    required this.billNumber,
    required this.date,
    required this.total,
    required this.shopName,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_number': billNumber,
      'date': date.toIso8601String(),
      'total': total,
      'shop_name': shopName,
    };
  }

  static Order fromMap(Map<String, dynamic> map, List<OrderItem> items) {
    return Order(
      id: map['id'],
      billNumber: map['bill_number'],
      date: DateTime.parse(map['date']),
      total: map['total'],
      shopName: map['shop_name'],
      items: items,
    );
  }
}

class OrderItem {
  final int? id;
  final int orderId;
  final String productName;
  final double productPrice;
  final int quantity;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
  });

  double get total => productPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
    };
  }

  static OrderItem fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      productName: map['product_name'],
      productPrice: map['product_price'],
      quantity: map['quantity'],
    );
  }
}