import 'package:latlong2/latlong.dart';

/// Texte traduit (fr, en, de, es, zh, ru) avec repli sur l'anglais.
class LocalizedText {
  const LocalizedText(this.values);

  final Map<String, String> values;

  factory LocalizedText.fromJson(Object? json) {
    if (json is String) return LocalizedText(<String, String>{'en': json});
    if (json is Map) {
      return LocalizedText(json.map((k, v) => MapEntry(k.toString(), v.toString())));
    }
    return const LocalizedText(<String, String>{});
  }

  String resolve(String languageCode) =>
      values[languageCode] ?? values['en'] ?? (values.isNotEmpty ? values.values.first : '');

  Map<String, String> toJson() => values;
}

/// Élément de fresque (monument ou scène culturelle).
class SilhouetteItem {
  const SilhouetteItem({
    required this.id,
    required this.label,
    required this.shape,
    this.category,
    this.asset,
  });

  /// Identifiant ; le fichier attendu est `assets/silhouettes/unique/{cityId}_{id}.svg`.
  final String id;
  final String label;

  /// Forme utilisée par le fallback vectoriel si le SVG est absent.
  final String shape;

  /// Pour `culture_life` : food, attire, dance, transport, lifestyle.
  final String? category;

  /// Chemin explicite (ex. `common/tuk_tuk`) prioritaire sur la convention.
  final String? asset;

  factory SilhouetteItem.fromJson(Map<String, dynamic> json) => SilhouetteItem(
        id: json['id'] as String,
        label: (json['label'] ?? json['id']) as String,
        shape: (json['shape'] ?? 'building') as String,
        category: json['category'] as String?,
        asset: json['asset'] as String?,
      );
}

class CapitalModel {
  const CapitalModel({
    required this.id,
    required this.countryCode,
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    required this.isFree,
    required this.alternativeCities,
    required this.monuments,
    required this.cultureLife,
  });

  final String id;
  final String countryCode;
  final LocalizedText name;
  final LocalizedText country;
  final double lat;
  final double lng;
  final bool isFree;
  final List<LocalizedText> alternativeCities;
  final List<SilhouetteItem> monuments;
  final List<SilhouetteItem> cultureLife;

  LatLng get position => LatLng(lat, lng);

  String cityName(String lang) => name.resolve(lang);
  String countryName(String lang) => country.resolve(lang);

  factory CapitalModel.fromJson(Map<String, dynamic> json) {
    return CapitalModel(
      id: json['id'] as String,
      countryCode: json['country_code'] as String,
      name: LocalizedText.fromJson(json['name']),
      country: LocalizedText.fromJson(json['country']),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      isFree: (json['tier'] ?? 'free') == 'free',
      alternativeCities: ((json['alternative_cities'] as List?) ?? const <Object>[])
          .map(LocalizedText.fromJson)
          .toList(growable: false),
      monuments: ((json['monuments'] as List?) ?? const <Object>[])
          .map((e) => SilhouetteItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      cultureLife: ((json['culture_life'] as List?) ?? const <Object>[])
          .map((e) => SilhouetteItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }
}
