#!/usr/bin/env bash
# Génère les dossiers natifs iOS/Android (org com.aaistudio) et applique les réglages requis.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter create . --org com.aaistudio --project-name pixel_radius --platforms=ios,android
# Android : INTERNET en release (tuiles CARTO), facturation Play.
M=android/app/src/main/AndroidManifest.xml
grep -q 'android.permission.INTERNET' "$M" || sed -i.bak 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$M"
grep -q 'com.android.vending.BILLING' "$M" || sed -i.bak 's#<application#<uses-permission android:name="com.android.vending.BILLING"/>\n    <application#' "$M"
# Android TV : déclarer le Leanback et rendre l'écran tactile optionnel.
grep -q 'android.software.leanback' "$M" || sed -i.bak 's#<application#<uses-feature android:name="android.software.leanback" android:required="false"/>\n    <uses-feature android:name="android.hardware.touchscreen" android:required="false"/>\n    <application#' "$M"
rm -f "$M.bak"
flutter pub get
echo "✔ Plateformes prêtes. iOS : activez la capability « In-App Purchase » dans Xcode."
