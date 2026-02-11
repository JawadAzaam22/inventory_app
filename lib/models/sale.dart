// ملف: lib/models/sale.dart
class Sale {
  int? id; // معرف عملية البيع (سيتم تعيينه تلقائيًا من قاعدة البيانات)
  final int productId; // معرف المنتج الذي تم بيعه
  final int quantitySold; // الكمية المباعة
  final double totalDollars; // القيمة الإجمالية بالدولار
  final double exchangeRate; // سعر الصرف وقت البيع
  final DateTime date; // تاريخ البيع

  Sale({
    this.id,
    required this.productId,
    required this.quantitySold,
    required this.totalDollars,
    required this.exchangeRate,
    required this.date,
  });

  // تحويل عملية البيع إلى Map لتخزينها في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantitySold': quantitySold,
      'totalDollars': totalDollars,
      'exchangeRate': exchangeRate,
      'date': date.toIso8601String(), // تحويل التاريخ إلى نص
    };
  }

  // إنشاء عملية بيع من Map (عند القراءة من قاعدة البيانات)
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      productId: map['productId'],
      quantitySold: map['quantitySold'],
      totalDollars: map['totalDollars'],
      exchangeRate: map['exchangeRate'],
      date: DateTime.parse(map['date']), // تحويل النص إلى تاريخ
    );
  }
}