class Sale {
  int? id;
  final int productId;
  final int quantitySold;
  final double totalDollars;
  final double exchangeRate;
  final DateTime date;

  Sale({
    this.id,
    required this.productId,
    required this.quantitySold,
    required this.totalDollars,
    required this.exchangeRate,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantitySold': quantitySold,
      'totalDollars': totalDollars,
      'exchangeRate': exchangeRate,
      'date': date.toIso8601String(),
    };
  }
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      productId: map['productId'],
      quantitySold: map['quantitySold'],
      totalDollars: map['totalDollars'],
      exchangeRate: map['exchangeRate'],
      date: DateTime.parse(map['date']),
    );
  }
}