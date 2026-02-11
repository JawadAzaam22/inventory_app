class Product {
  int? id; // معرف المنتج (سيتم تعيينه تلقائيًا من قاعدة البيانات)
  final String name; // اسم المنتج
  final double priceInDollars; // سعر المنتج بالدولار
  final int quantity; // الكمية المتاحة
  final String? imagePath; // مسار صورة المنتج (اختياري)

  Product({
    this.id,
    required this.name,
    required this.priceInDollars,
    required this.quantity,
    this.imagePath,
  });

  // تحويل المنتج إلى Map لتخزينه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'priceInDollars': priceInDollars,
      'quantity': quantity,
      'imagePath': imagePath,
    };
  }

  // إنشاء منتج من Map (عند القراءة من قاعدة البيانات)
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