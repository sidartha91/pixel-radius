# Pixel Radius — AAI Studio (`com.aaistudio`)

Jeu de géographie culturelle **Neo-Soul / Cyber-Soul** pour iOS, Android et Android TV / D-Pad.
Deux modes : **Classique 📍** (carte sans labels) et **Ombre Chinoise 👁️** (fresques procédurales).

## Démarrage

```bash
./tool/setup_platforms.sh   # flutter create (org com.aaistudio) + permissions Android/TV
flutter run
flutter test                # tests du double scoring et du générateur de 11 choix
```

Prérequis : Flutter ≥ 3.27 (Dart ≥ 3.6).
Achat intégré : créer le produit **non-consommable** `premium_unlock_world` dans App Store Connect et Google Play Console.

## Arborescence

```
pixel_radius/
├── assets/
│   ├── audio/
│   │   ├── sfx/
│   │   │   ├── correct.m4a
│   │   │   ├── partial.m4a
│   │   │   ├── tap.m4a
│   │   │   └── wrong.m4a
│   │   └── theme_loop.m4a
│   ├── data/
│   │   └── capitals_catalog.json
│   └── silhouettes/
│       ├── common/
│       │   ├── birds_1.svg
│       │   ├── birds_2.svg
│       │   ├── cafe_terrace.svg
│       │   ├── cloud_1.svg
│       │   ├── cloud_2.svg
│       │   ├── cloud_3.svg
│       │   ├── moon.svg
│       │   ├── palm_tree.svg
│       │   ├── sun.svg
│       │   └── tuk_tuk.svg
│       └── unique/
│           ├── colombo_gangaramaya_stupa.svg
│           ├── colombo_jami_ul_alfar.svg
│           ├── colombo_kandyan_dancer.svg
│           ├── colombo_kottu_stall.svg
│           ├── colombo_lotus_tower.svg
│           ├── colombo_stilt_fisherman.svg
│           ├── fes_bab_boujloud.svg
│           ├── fes_djellaba_walker.svg
│           ├── fes_donkey_cart.svg
│           ├── fes_merinid_tombs.svg
│           ├── fes_mint_tea_seller.svg
│           ├── fes_qarawiyyin_minaret.svg
│           ├── fes_tajine_stall.svg
│           ├── london_big_ben.svg
│           ├── london_black_cab.svg
│           ├── london_double_decker.svg
│           ├── london_london_eye.svg
│           ├── london_royal_guard.svg
│           ├── london_st_pauls.svg
│           ├── london_tower_bridge.svg
│           ├── london_umbrella_gentleman.svg
│           ├── paris_accordionist.svg
│           ├── paris_arc_de_triomphe.svg
│           ├── paris_baguette_cyclist.svg
│           ├── paris_bateau_mouche.svg
│           ├── paris_eiffel_tower.svg
│           ├── paris_notre_dame.svg
│           ├── tokyo_cherry_tree.svg
│           ├── tokyo_kimono_walker.svg
│           ├── tokyo_meiji_torii.svg
│           ├── tokyo_ramen_stall.svg
│           ├── tokyo_sensoji_pagoda.svg
│           ├── tokyo_shinkansen.svg
│           ├── tokyo_skytree.svg
│           └── tokyo_tokyo_tower.svg
├── lib/
│   ├── classic_mode/
│   │   └── classic_game_screen.dart
│   ├── core/
│   │   ├── audio/
│   │   │   └── audio_manager.dart
│   │   ├── localization/
│   │   │   └── app_localizations.dart
│   │   ├── models/
│   │   │   └── capital_model.dart
│   │   ├── monetization/
│   │   │   └── purchase_manager.dart
│   │   ├── services/
│   │   │   └── catalog_service.dart
│   │   ├── settings/
│   │   │   └── app_settings.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── widgets/
│   │   │   └── focusable_tap.dart
│   │   └── app_scope.dart
│   ├── screens/
│   │   └── main_menu_screen.dart
│   ├── shadow_quiz/
│   │   ├── logic/
│   │   │   ├── quiz_models.dart
│   │   │   ├── quiz_strings.dart
│   │   │   └── score_calculator.dart
│   │   ├── widgets/
│   │   │   ├── fallback_silhouettes.dart
│   │   │   ├── procedural_skyline_widget.dart
│   │   │   └── quiz_option_button.dart
│   │   └── shadow_quiz_game.dart
│   └── main.dart
├── test/
│   └── score_calculator_test.dart
├── tool/
│   └── setup_platforms.sh
├── analysis_options.yaml
└── pubspec.yaml```

## Architecture

| Couche | Rôle |
|---|---|
| `lib/core/` | Thèmes (Cyber-Soul / Vinyle Vintage), i18n 6 langues, audio (boucle + SFX + mute persistant), IAP, modèles, catalogue, réglages persistés, widget de focus TV |
| `lib/screens/` | Écran d'accueil |
| `lib/classic_mode/` | Carte `flutter_map` (tuiles CARTO `*_nolabels`), carte figée après validation, ligne Rose Néon, score distance + temps |
| `lib/shadow_quiz/` | **Module autonome** (n'importe rien de `lib/core`) : `ShadowQuizGame(isDarkMode, durationSeconds, languageCode)` |

### Shadow Quiz : principes

- **Fresque procédurale** (`ProceduralSkylineWidget`, 40 % supérieurs de l'écran) en 3 calques :
  - ciel : 4 à 6 éléments, échelle de 0,6× à 1,1×, miroir aléatoire ;
  - monuments : 2 ou 3, placés à gauche, au centre et à droite, hauteur ±15 % ;
  - premier plan : sol ou fleuve, plus 3 ou 4 scènes culturelles.

  Un `ColorFilter.mode(…, BlendMode.srcIn)` global unifie le tout. Une signature de composition empêche toute répétition dans la session.
- **Fallback vectoriel** : `AssetManifest` indique quels SVG existent. Pour chaque fichier manquant, `FallbackSilhouette` (un `CustomPainter` qui gère environ 55 formes) dessine la forme indiquée par le champ `shape` du catalogue. Les 23 villes sans SVG dédiés sont donc déjà jouables et visuellement riches.
- **Ajouter des SVG** : déposer `assets/silhouettes/unique/{cityId}_{itemId}.svg` (noir #000000, fond transparent). Ils sont détectés automatiquement, sans modifier le code.
- **Scoring** :
  - capitale exacte : 1000 pts + temps restant × 20 ;
  - bon pays mais autre ville : 350 pts ;
  - mauvais pays : 0 pt.

### Catalogue

28 villes (12 gratuites, 16 avec Premium). La **règle des capitales de référence** est appliquée : la ville emblématique sert de référence et la capitale administrative figure dans `alternative_cities`. Exemples : Colombo / Sri Jayawardenepura Kotte, Abidjan / Yamoussoukro, Lagos / Abuja, Le Cap / Pretoria, Amsterdam / La Haye.

### Audio

`theme_loop.m4a` est une boucle lo-fi Neo-Soul de démonstration (Dm9 – G13 – Cmaj9 – Am9, 76 BPM, 12,6 s, sans couture), accompagnée de 4 SFX. Remplacez-les par vos masters en gardant les mêmes noms.

### Accessibilité TV / manette

Tous les éléments interactifs ont un focus visible : bordure #E5A93C de 2,5 px et léger agrandissement (scale 1,03). Ils s'activent avec Select, Entrée, Espace ou le bouton A.

Navigation sur la carte classique :
- les flèches déplacent la carte ;
- les touches +/− (ou CH+/CH−) zooment ;
- Select pose l'épingle au centre du réticule ;
- un second Select valide.
