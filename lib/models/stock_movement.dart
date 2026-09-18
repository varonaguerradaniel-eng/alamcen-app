class StockMovement {
  int? id;
  int productId;
  String type; // 'mal_kabul', 'sevkiyat', 'sayim', 'fire_iade'
  int quantity;
  String? note;
  DateTime createdAt;

  // Joined fields (not stored in DB)
  String? productName;
  String? productBarcode;

  StockMovement({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    this.note,
    DateTime? createdAt,
    this.productName,
    this.productBarcode,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      productId: (map['product_id'] as num).toInt(),
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toInt(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      productName: map['product_name'] as String?,
      productBarcode: map['product_barcode'] as String?,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'mal_kabul':
        return 'Stok Girişi';
      case 'sevkiyat':
        return 'Sevkiyat';
      case 'sayim':
        return 'Sayım';
      case 'fire_iade':
        return 'Fire/İade';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'mal_kabul':
        return 'inventory_2';
      case 'sevkiyat':
        return 'local_shipping';
      case 'sayim':
        return 'calculate';
      case 'fire_iade':
        return 'recycling';
      default:
        return 'edit';
    }
  }

  bool get isInbound => type == 'mal_kabul';
  bool get isOutbound => type == 'sevkiyat' || type == 'fire_iade';
}
