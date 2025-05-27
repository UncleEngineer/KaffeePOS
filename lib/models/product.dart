// class Product {
//   final int? id;
//   final String name;
//   final double price;

//   Product({this.id, required this.name, required this.price});

//   Map<String, dynamic> toMap() {
//     return {'id': id, 'name': name, 'price': price};
//   }

//   static Product fromMap(Map<String, dynamic> map) {
//     return Product(id: map['id'], name: map['name'], price: map['price']);
//   }
// }


class Product {
  final int? id;
  final String name;
  final double price;
  final int categoryId;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category_id': categoryId,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      categoryId: map['category_id'],
    );
  }
}