class Product {
  int? id;
  final String name;
  final double priceInDollars;
  final int quantity;
  final String? imagePath;

  Product({
    this.id,
    required this.name,
    required this.priceInDollars,
    required this.quantity,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'priceInDollars': priceInDollars,
      'quantity': quantity,
      'imagePath': imagePath,
    };
  }
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      priceInDollars: map['priceInDollars'],
      quantity: map['quantity'],
      imagePath: map['imagePath'],
    );
  }
}