import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet_appointment.dart';

class AppointmentRepository {
  AppointmentRepository(this._preferences);

  static const _storageKey = 'zoovana_appointments_v1';
  final SharedPreferences _preferences;

  List<PetAppointment> getAppointments() {
    final stored = _preferences.getStringList(_storageKey) ?? const [];
    return stored
        .map(
          (item) =>
              PetAppointment.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList()
        .reversed
        .toList();
  }

  Future<void> addAppointment(PetAppointment appointment) async {
    final appointments = getAppointments().reversed.toList()..add(appointment);
    await _preferences.setStringList(
      _storageKey,
      appointments.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
