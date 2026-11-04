class PetProfile {
  const PetProfile({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.birthDate,
    required this.weightKg,
    required this.imageAsset,
    this.heightCm,
    this.microchipId = '',
    this.neutered = false,
  });

  final String id;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final String birthDate;
  final double weightKg;
  final String imageAsset;
  final double? heightCm;
  final String microchipId;
  final bool neutered;

  static const river = PetProfile(
    id: 'river-default',
    name: 'River',
    species: 'Dog',
    breed: 'Border Collie',
    gender: 'Female',
    birthDate: '12 May 2023',
    weightKg: 18.5,
    imageAsset: 'assets/images/pet_river.jpg',
  );

  factory PetProfile.fromJson(Map<String, dynamic> json) => PetProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    species: json['species'] as String,
    breed: json['breed'] as String,
    gender: json['gender'] as String,
    birthDate: json['birthDate'] as String,
    weightKg: (json['weightKg'] as num).toDouble(),
    imageAsset: json['imageAsset'] as String,
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    microchipId: json['microchipId'] as String? ?? '',
    neutered: json['neutered'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'species': species,
    'breed': breed,
    'gender': gender,
    'birthDate': birthDate,
    'weightKg': weightKg,
    'imageAsset': imageAsset,
    'heightCm': heightCm,
    'microchipId': microchipId,
    'neutered': neutered,
  };
}
