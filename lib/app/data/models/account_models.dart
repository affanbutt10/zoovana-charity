class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.primary,
  });

  final String id;
  final String label;
  final String address;
  final bool primary;

  SavedAddress copyWith({bool? primary}) => SavedAddress(
    id: id,
    label: label,
    address: address,
    primary: primary ?? this.primary,
  );

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'] as String,
    label: json['label'] as String,
    address: json['address'] as String,
    primary: json['primary'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'address': address,
    'primary': primary,
  };
}

class SavedPaymentMethod {
  const SavedPaymentMethod({
    required this.id,
    required this.brand,
    required this.lastFour,
    required this.primary,
  });

  final String id;
  final String brand;
  final String lastFour;
  final bool primary;

  SavedPaymentMethod copyWith({bool? primary}) => SavedPaymentMethod(
    id: id,
    brand: brand,
    lastFour: lastFour,
    primary: primary ?? this.primary,
  );

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) =>
      SavedPaymentMethod(
        id: json['id'] as String,
        brand: json['brand'] as String,
        lastFour: json['lastFour'] as String,
        primary: json['primary'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'lastFour': lastFour,
    'primary': primary,
  };
}
