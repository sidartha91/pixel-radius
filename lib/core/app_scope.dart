import 'package:flutter/widgets.dart';

import 'audio/audio_manager.dart';
import 'monetization/purchase_manager.dart';
import 'services/catalog_service.dart';
import 'settings/app_settings.dart';

/// Injection simple des services applicatifs dans l'arbre de widgets.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.audio,
    required this.purchases,
    required this.catalog,
    required super.child,
  });

  final AppSettings settings;
  final AudioManager audio;
  final PurchaseManager purchases;
  final CatalogService catalog;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope introuvable dans le contexte');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      settings != oldWidget.settings ||
      audio != oldWidget.audio ||
      purchases != oldWidget.purchases ||
      catalog != oldWidget.catalog;
}
