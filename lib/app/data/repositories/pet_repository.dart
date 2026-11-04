import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet_profile.dart';

class PetRepository {
  PetRepository(this._preferences);

  static const _storageKey = 'zoovana_pet_profiles_v1';
  final SharedPreferences _preferences;

  List<PetProfile> getPets() {
    final stored = _preferences.getStringList(_storageKey);
    if (stored == null) return [PetProfile.river];
    return stored
        .map(
          (item) =>
              PetProfile.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> addPet(PetProfile pet) async {
    final pets = getPets();
    final index = pets.indexWhere((item) => item.id == pet.id);
    if (index == -1) {
      pets.add(pet);
    } else {
      pets[index] = pet;
    }
    await _save(pets);
  }

  Future<void> removePet(String id) async {
    final pets = getPets()..removeWhere((item) => item.id == id);
    await _save(pets);
  }

  Future<void> _save(List<PetProfile> pets) async {
    await _preferences.setStringList(
      _storageKey,
      pets.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
