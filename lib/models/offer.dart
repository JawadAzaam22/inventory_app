// ملف جديد: lib/models/offer.dart
class Offer {
  int? id; // معرف العرض (سيتم تعيينه تلقائيًا من قاعدة البيانات)
  final String name; // اسم العرض
  final String description; // وصف العرض
  final double priceInLira; // سعر العرض بالليرة السورية
  final String imagePath; // مسار صورة العرض
  final DateTime dateAdded; // تاريخ إضافة العرض

  Offer({
    this.id,
    required this.name,
    required this.description,
    required this.priceInLira,
    required this.imagePath,
    required this.dateAdded,
  });

  // تحويل العرض إلى Map لتخزينه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priceInLira': priceInLira,
      'imagePath': imagePath,
      'dateAdded': dateAdded.toIso8601String(), // تحويل التاريخ إلى نص
    };
  }

  // إنشاء عرض من Map (عند القراءة من قاعدة البيانات)
  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      priceInLira: map['priceInLira'],
      imagePath: map['imagePath'],
      dateAdded: DateTime.parse(map['date']), // تحويل النص إلى تاريخ
    );
  }
}