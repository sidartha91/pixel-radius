import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/capital_model.dart';

/// Charge et expose le catalogue `assets/data/capitals_catalog.json`.
class CatalogService {
  CatalogService._(this.capitals, this.version);

  static const String assetPath = 'assets/data/capitals_catalog.json';

  final List<CapitalModel> capitals;
  final int version;

  static Future<CatalogService> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final data = await compute(_decode, raw);
    final list = (data['capitals'] as List)
        .map((e) => CapitalModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    return CatalogService._(list, (data['version'] as num?)?.toInt() ?? 1);
  }

  static Map<String, dynamic> _decode(String raw) =>
      Map<String, dynamic>.from(jsonDecode(raw) as Map);

  /// Villes jouables selon le statut premium.
  List<CapitalModel> playable({required bool premium}) =>
      premium ? capitals : capitals.where((c) => c.isFree).toList(growable: false);

  int get freeCount => capitals.where((c) => c.isFree).length;

  /// Tire `count` villes distinctes, mélangées.
  List<CapitalModel> drawRounds({required bool premium, required int count, Random? random}) {
    final pool = List<CapitalModel>.of(playable(premium: premium))..shuffle(random ?? Random());
    return pool.take(min(count, pool.length)).toList(growable: false);
  }
}
