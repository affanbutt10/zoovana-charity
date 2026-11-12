import 'package:get/get.dart';

import '../../../apis/core/api_response.dart';
import '../../core/services/app_locale.dart';

enum AnimalKind {
  cat,
  bird,
  dog,

  /// An `animal_type` this app version has no artwork for.
  other;

  static AnimalKind fromCode(String? code) => switch (code?.toLowerCase()) {
    'cat' || 'cats' => cat,
    'bird' || 'birds' => bird,
    'dog' || 'dogs' => dog,
    _ => other,
  };
}

/// Street feeding rounds and shelter campaigns use different donation flows.
enum CampaignKind { street, shelter }

/// A feeding programme: one city and one animal type.
class CharityCampaign {
  const CharityCampaign({
    required this.id,
    required this.title,
    required this.city,
    required this.animal,
    required this.animalKind,
    required this.description,
    this.supporters = 0,
    this.kind = CampaignKind.street,
    this.code = '',
    this.cityCode = '',
    this.imageUrl,
    this.fulfilmentSlaHours,
  });

  final String id;
  final String code;
  final String title;
  final String city;

  /// Groups programmes by city on the city choice.
  final String cityCode;

  /// Label of the animal type, e.g. "Cats".
  final String animal;
  final AnimalKind animalKind;
  final String description;

  /// Not sent by the API yet; 0 hides the supporters line.
  final int supporters;
  final CampaignKind kind;
  final String? imageUrl;
  final int? fulfilmentSlaHours;

  bool get isShelter => kind == CampaignKind.shelter;

  /// The donor app currently offers only cat and bird feeding in these cities.
  bool get isSupportedFeeding =>
      (animalKind == AnimalKind.cat || animalKind == AnimalKind.bird) &&
      (isMakkah ||
          '${cityCode.toLowerCase()} ${city.toLowerCase()}'.contains('madin'));

  /// Cities with bundled artwork; others use a generic card.
  bool get isMakkah =>
      cityCode.toLowerCase().contains('mak') || city == 'Makkah';

  /// `GET /programs` item.
  factory CharityCampaign.fromApi(Map<String, dynamic> json) {
    final animalType = json.str('animal_type');
    final kind = AnimalKind.fromCode(animalType);
    return CharityCampaign(
      id: json.str('id'),
      code: json.str('code'),
      title: AppLocale.pick(
        json.strOrNull('title_en'),
        json.strOrNull('title_ar'),
        json.strOrNull('title_ur'),
      ),
      city: AppLocale.pick(
        json.strOrNull('city_name_en'),
        json.strOrNull('city_name_ar'),
        json.strOrNull('city_name_ur'),
      ),
      cityCode: json.str('city_code'),
      animal: switch (kind) {
        AnimalKind.cat => 'Cats'.tr,
        AnimalKind.bird => 'Birds'.tr,
        AnimalKind.dog => 'Dogs'.tr,
        AnimalKind.other =>
          animalType.isEmpty
              ? 'Animals'.tr
              : '${animalType[0].toUpperCase()}${animalType.substring(1)}',
      },
      animalKind: kind,
      description: AppLocale.pick(
        json.strOrNull('description_en'),
        json.strOrNull('description_ar'),
        json.strOrNull('description_ur'),
      ),
      imageUrl: json.strOrNull('image_url'),
      fulfilmentSlaHours: json['fulfilment_sla_hours'] == null
          ? null
          : json.integer('fulfilment_sla_hours'),
    );
  }

  factory CharityCampaign.fromJson(Map<String, dynamic> json) {
    return CharityCampaign(
      id: json['id'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      animal: json['animal'] as String,
      animalKind: AnimalKind.fromCode(json['animalKind'] as String?),
      description: json['description'] as String,
      supporters: (json['supporters'] as num? ?? 0).toInt(),
      kind: CampaignKind.values.byName(json['kind'] as String? ?? 'street'),
      code: json['code'] as String? ?? '',
      cityCode: json['cityCode'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'city': city,
    'animal': animal,
    'animalKind': animalKind.name,
    'description': description,
    'supporters': supporters,
    'kind': kind.name,
    'code': code,
    'cityCode': cityCode,
    'imageUrl': imageUrl,
  };
}

/// An anonymised, approved feeding shown on the home screen
/// (`GET /programs/{id}/highlights`).
class FeedingHighlight {
  const FeedingHighlight({
    required this.id,
    required this.programId,
    required this.zone,
    required this.mealCount,
    required this.animalsFedEstimate,
    this.fedAt,
    this.note = '',
    this.imageUrl,
  });

  final String id;
  final String programId;
  final String zone;
  final int mealCount;
  final int animalsFedEstimate;
  final DateTime? fedAt;
  final String note;

  /// HTTPS URL, or a bundled asset in seed data.
  final String? imageUrl;

  factory FeedingHighlight.fromApi(Map<String, dynamic> json) {
    final cover =
        json.object('cover_image') ?? json.objects('media').firstOrNull;
    return FeedingHighlight(
      id: json.str('proof_id'),
      programId: json.str('program_id'),
      zone: AppLocale.pick(
        json.strOrNull('approximate_zone_en'),
        json.strOrNull('approximate_zone_ar'),
        json.strOrNull('approximate_zone_ur'),
      ),
      mealCount: json.integer('meal_count'),
      animalsFedEstimate: json.integer('animals_fed_estimate'),
      fedAt: json.time('fed_at'),
      note: json.str('feeder_note'),
      imageUrl: cover?.strOrNull('thumbnail_url') ?? cover?.strOrNull('url'),
    );
  }
}
