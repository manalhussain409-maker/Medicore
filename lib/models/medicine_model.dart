import '../utils/firestore_utils.dart';

class MedicineModel {
  final String id;
  final String name;
  final int stock;
  final double price;
  final String? category;
  final String? description;
  final DateTime? lastUpdated;

  MedicineModel({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    this.category,
    this.description,
    this.lastUpdated,
  });

  factory MedicineModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return MedicineModel(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      stock: (map['stock'] ?? 0) is int
          ? map['stock'] as int
          : int.tryParse('${map['stock']}') ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'],
      description: map['description'],
      lastUpdated: parseFirestoreDate(map['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'stock': stock,
      'price': price,
      'category': category,
      'description': description,
    };
  }

  bool get inStock => stock > 0;
}
