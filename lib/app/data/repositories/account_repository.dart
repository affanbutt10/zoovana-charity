import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/account_models.dart';

class AccountRepository {
  AccountRepository(this._preferences);

  static const _addressesKey = 'zoovana_addresses_v1';
  static const _paymentsKey = 'zoovana_payments_v1';
  static const _favoritesKey = 'zoovana_favorites_v1';
  final SharedPreferences _preferences;

  List<SavedAddress> getAddresses() {
    final stored = _preferences.getStringList(_addressesKey);
    if (stored == null) {
      return [
        const SavedAddress(
          id: 'home-default',
          label: 'Home',
          address:
              '742 Evergreen Boulevard, Suite 104\nOakridge District, Makkah',
          primary: true,
        ),
      ];
    }
    return stored
        .map(
          (item) =>
              SavedAddress.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> addAddress({
    required String label,
    required String address,
  }) async {
    final addresses = getAddresses();
    addresses.add(
      SavedAddress(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        address: address,
        primary: addresses.isEmpty,
      ),
    );
    await _saveAddresses(addresses);
  }

  Future<void> removeAddress(String id) async {
    final addresses = getAddresses()..removeWhere((item) => item.id == id);
    if (addresses.isNotEmpty && !addresses.any((item) => item.primary)) {
      addresses[0] = addresses[0].copyWith(primary: true);
    }
    await _saveAddresses(addresses);
  }

  Future<void> setPrimaryAddress(String id) async {
    final addresses = getAddresses()
        .map((item) => item.copyWith(primary: item.id == id))
        .toList();
    await _saveAddresses(addresses);
  }

  List<SavedPaymentMethod> getPaymentMethods() {
    final stored = _preferences.getStringList(_paymentsKey);
    if (stored == null) {
      return [
        const SavedPaymentMethod(
          id: 'visa-default',
          brand: 'VISA',
          lastFour: '4242',
          primary: true,
        ),
        const SavedPaymentMethod(
          id: 'mada-default',
          brand: 'MADA',
          lastFour: '8721',
          primary: false,
        ),
      ];
    }
    return stored
        .map(
          (item) => SavedPaymentMethod.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> addPaymentMethod({
    required String brand,
    required String lastFour,
  }) async {
    final methods = getPaymentMethods();
    methods.add(
      SavedPaymentMethod(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        brand: brand,
        lastFour: lastFour,
        primary: methods.isEmpty,
      ),
    );
    await _savePayments(methods);
  }

  Future<void> removePaymentMethod(String id) async {
    final methods = getPaymentMethods()..removeWhere((item) => item.id == id);
    if (methods.isNotEmpty && !methods.any((item) => item.primary)) {
      methods[0] = methods[0].copyWith(primary: true);
    }
    await _savePayments(methods);
  }

  Future<void> setPrimaryPaymentMethod(String id) async {
    final methods = getPaymentMethods()
        .map((item) => item.copyWith(primary: item.id == id))
        .toList();
    await _savePayments(methods);
  }

  Set<String> getFavorites() =>
      (_preferences.getStringList(_favoritesKey) ?? const []).toSet();

  bool isFavorite(String id) => getFavorites().contains(id);

  Future<bool> toggleFavorite(String id) async {
    final favorites = getFavorites();
    final selected = favorites.contains(id);
    selected ? favorites.remove(id) : favorites.add(id);
    await _preferences.setStringList(_favoritesKey, favorites.toList()..sort());
    return !selected;
  }

  Future<void> _saveAddresses(List<SavedAddress> addresses) =>
      _preferences.setStringList(
        _addressesKey,
        addresses.map((item) => jsonEncode(item.toJson())).toList(),
      );

  Future<void> _savePayments(List<SavedPaymentMethod> methods) =>
      _preferences.setStringList(
        _paymentsKey,
        methods.map((item) => jsonEncode(item.toJson())).toList(),
      );
}
