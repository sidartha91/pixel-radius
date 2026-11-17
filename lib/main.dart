import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/audio/audio_manager.dart';
import 'core/localization/app_localizations.dart';
import 'core/monetization/purchase_manager.dart';
import 'core/services/catalog_service.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final results = await Future.wait<Object>(<Future<Object>>[
    AppSettings.load(),
    AudioManager.create(),
    PurchaseManager.create(),
  ]);
  final settings = results[0] as AppSettings;
  final audio = results[1] as AudioManager;
  final purchases = results[2] as PurchaseManager;

  CatalogService? catalog;
  Object? catalogError;
  try {
    catalog = await CatalogService.load();
  } catch (e) {
    catalogError = e;
    debugPrint('[main] Catalogue : $e');
  }

  runApp(PixelRadiusApp(
    settings: settings,
    audio: audio,
    purchases: purchases,
    catalog: catalog,
    catalogError: catalogError,
  ));

  WidgetsBinding.instance.addPostFrameCallback((_) => audio.startMusic());
}

class PixelRadiusApp extends StatelessWidget {
  const PixelRadiusApp({
    super.key,
    required this.settings,
    required this.audio,
    required this.purchases,
    required this.catalog,
    this.catalogError,
  });

  final AppSettings settings;
  final AudioManager audio;
  final PurchaseManager purchases;
  final CatalogService? catalog;
  final Object? catalogError;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[settings, audio, purchases]),
      builder: (context, _) {
        final dark = settings.isDarkMode;
        SystemChrome.setSystemUIOverlayStyle(
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        );

        final Widget home =
            catalog == null ? _CatalogErrorScreen(error: catalogError) : const MainMenuScreen();

        return MaterialApp(
          title: 'Pixel Radius',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 350),
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // AppScope au-dessus du Navigator : accessible depuis toutes les routes.
          builder: (context, child) => catalog == null
              ? child!
              : AppScope(
                  settings: settings,
                  audio: audio,
                  purchases: purchases,
                  catalog: catalog!,
                  child: child!,
                ),
          home: home,
        );
      },
    );
  }
}

class _CatalogErrorScreen extends StatelessWidget {
  const _CatalogErrorScreen({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = PixelPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.error_outline, color: PixelColors.wrong, size: 48),
                const SizedBox(height: 16),
                Text(l.t('catalogError'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.onSurface, fontSize: 18)),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
