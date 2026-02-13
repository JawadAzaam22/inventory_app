class Offer {
  int? id;
  final String name;
  final String description;
  final double priceInLira;
  final String imagePath;
  final DateTime dateAdded;

  Offer({
    this.id,
    required this.name,
    required this.description,
    required this.priceInLira,
    required this.imagePath,
    required this.dateAdded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priceInLira': priceInLira,
      'imagePath': imagePath,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }
  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      priceInLira: map['priceInLira'],
      imagePath: map['imagePath'],
      dateAdded: DateTime.parse(map['date']),
    );
  }
}