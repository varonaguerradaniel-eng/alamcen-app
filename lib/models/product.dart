class Product {
  int? id;
  String barcode;
  String name;
  String spanishName;
  String category;
  double costPrice;
  double salePrice;
  int quantity;
  String location;
  double? weight;
  DateTime createdAt;
  DateTime updatedAt;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    this.spanishName = '',
    required this.category,
    required this.costPrice,
    required this.salePrice,
    required this.quantity,
    required this.location,
    this.weight,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'spanish_name': spanishName,
      'category': category,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'quantity': quantity,
      'location': location,
      'weight': weight,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      barcode: map['barcode'] as String,
      name: map['name'] as String,
      spanishName: map['spanish_name'] as String? ?? '',
      category: map['category'] as String,
      costPrice: (map['cost_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
      location: map['location'] as String,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  double get profit => salePrice - costPrice;
  double get profitMargin => costPrice > 0 ? (profit / costPrice) * 100 : 0;

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    String? spanishName,
    String? category,
    double? costPrice,
    double? salePrice,
    int? quantity,
    String? location,
    double? weight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      spanishName: spanishName ?? this.spanishName,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
