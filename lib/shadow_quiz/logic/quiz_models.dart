import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// Modèles internes du module Shadow Quiz (indépendants de lib/core).

String _resolve(Object? value, String lang) {
  if (value is String) return value;
  if (value is Map) {
    final v = value[lang] ?? value['en'] ?? (value.isNotEmpty ? value.values.first : '');
    return v.toString();
  }
  return '';
}

class QuizSilhouette {
  const QuizSilhouette({required this.id, required this.shape, this.asset, this.category});

  final String id;
  final String shape;
  final String? asset;
  final String? category;

  factory QuizSilhouette.fromJson(Map<String, dynamic> json) => QuizSilhouette(
        id: json['id'] as String,
        shape: (json['shape'] ?? 'building') as String,
        asset: json['asset'] as String?,
        category: json['category'] as String?,
      );
}

class QuizCity {
  const QuizCity({
    required this.id,
    required this.countryCode,
    required this.nameRaw,
    required this.countryRaw,
    required this.alternativesRaw,
    required this.monuments,
    required this.cultureLife,
  });

  final String id;
  final String countryCode;
  final Object? nameRaw;
  final Object? countryRaw;
  final List<Object?> alternativesRaw;
  final List<QuizSilhouette> monuments;
  final List<QuizSilhouette> cultureLife;

  String name(String lang) => _resolve(nameRaw, lang);
  String country(String lang) => _resolve(countryRaw, lang);
  List<String> alternatives(String lang) =>
      alternativesRaw.map((a) => _resolve(a, lang)).where((s) => s.isNotEmpty).toList();

  factory QuizCity.fromJson(Map<String, dynamic> json) => QuizCity(
        id: json['id'] as String,
        countryCode: json['country_code'] as String,
        nameRaw: json['name'],
        countryRaw: json['country'],
        alternativesRaw: List<Object?>.from((json['alternative_cities'] as List?) ?? const <Object?>[]),
        monuments: ((json['monuments'] as List?) ?? const <Object>[])
            .map((e) => QuizSilhouette.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(growable: false),
        cultureLife: ((json['culture_life'] as List?) ?? const <Object>[])
            .map((e) => QuizSilhouette.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(growable: false),
      );
}

/// Une des 11 propositions.
class QuizOption {
  const QuizOption({
    required this.key,
    required this.cityId,
    required this.cityLabel,
    required this.countryLabel,
    required this.countryCode,
    required this.kind,
  });

  /// Clé unique dans la manche.
  final String key;

  /// Identifiant de ville (référence) ou `cityId#altN` (alternative).
  final String cityId;
  final String cityLabel;
  final String countryLabel;
  final String countryCode;
  final QuizOptionKind kind;
}

enum QuizOptionKind { correct, sameCountryDecoy, otherCountryDecoy }

class QuizRound {
  const QuizRound({required this.target, required this.options});

  final QuizCity target;
  final List<QuizOption> options;
}

class ShadowQuizData {
  const ShadowQuizData(this.cities);

  final List<QuizCity> cities;

  static Future<ShadowQuizData> load(String assetPath, {AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final cities = (json['capitals'] as List)
        .map((e) => QuizCity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    return ShadowQuizData(cities);
  }
}

/// Construit les 11 propositions : 1 bonne, 2 « même pays », 8 « autres pays ».
class QuizRoundBuilder {
  const QuizRoundBuilder._();

  static const int totalOptions = 11;
  static const int sameCountryDecoys = 2;
  static const int otherCountryDecoys = 8;

  static QuizRound build({
    required QuizCity target,
    required List<QuizCity> allCities,
    required String languageCode,
    required Random random,
  }) {
    final options = <QuizOption>[
      QuizOption(
        key: 'ref:${target.id}',
        cityId: target.id,
        cityLabel: target.name(languageCode),
        countryLabel: target.country(languageCode),
        countryCode: target.countryCode,
        kind: QuizOptionKind.correct,
      ),
    ];

    // 2 leurres « même pays » issus de alternative_cities.
    final altIndices = List<int>.generate(target.alternativesRaw.length, (i) => i)..shuffle(random);
    for (final i in altIndices.take(sameCountryDecoys)) {
      options.add(QuizOption(
        key: 'alt:${target.id}:$i',
        cityId: '${target.id}#alt$i',
        cityLabel: _resolve(target.alternativesRaw[i], languageCode),
        countryLabel: target.country(languageCode),
        countryCode: target.countryCode,
        kind: QuizOptionKind.sameCountryDecoy,
      ));
    }

    // Leurres « autres pays » : capitales de référence, un seul par pays.
    final others = allCities.where((c) => c.countryCode != target.countryCode).toList()..shuffle(random);
    final usedCountries = <String>{target.countryCode};
    for (final city in others) {
      if (options.length >= totalOptions) break;
      if (!usedCountries.add(city.countryCode)) continue;
      options.add(QuizOption(
        key: 'ref:${city.id}',
        cityId: city.id,
        cityLabel: city.name(languageCode),
        countryLabel: city.country(languageCode),
        countryCode: city.countryCode,
        kind: QuizOptionKind.otherCountryDecoy,
      ));
    }

    options.shuffle(random);
    return QuizRound(target: target, options: List<QuizOption>.unmodifiable(options));
  }
}
