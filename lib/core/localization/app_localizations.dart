import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Localisations Pixel Radius — 7 langues : fr, en, de, es, zh, ru, si.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const List<String> supportedLanguageCodes = <String>['fr', 'en', 'de', 'es', 'zh', 'ru', 'si'];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('zh'),
    Locale('ru'),
    Locale('si'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('fr'));
  }

  String get languageCode =>
      supportedLanguageCodes.contains(locale.languageCode) ? locale.languageCode : 'en';

  /// Libellé court affiché dans le sélecteur de langue.
  static String shortLabel(String code) => code.toUpperCase();

  /// Nom natif de la langue.
  static String nativeName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'es':
        return 'Español';
      case 'zh':
        return '中文';
      case 'ru':
        return 'Русский';
      case 'si':
        return 'සිංහල';
      default:
        return code;
    }
  }

  String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[languageCode] ?? entry['en'] ?? key;
  }

  /// Remplace les marqueurs {name} par les valeurs fournies.
  String tf(String key, Map<String, Object> args) {
    var value = t(key);
    args.forEach((k, v) => value = value.replaceAll('{$k}', '$v'));
    return value;
  }

  // Raccourcis typés
  String get appSubtitle => t('appSubtitle');
  String get modeClassic => t('modeClassic');
  String get modeClassicDesc => t('modeClassicDesc');
  String get modeShadow => t('modeShadow');
  String get modeShadowDesc => t('modeShadowDesc');
  String get timer => t('timer');
  String get play => t('play');
  String get restorePurchases => t('restorePurchases');
  String get unlockWorld => t('unlockWorld');
  String get premiumActive => t('premiumActive');

  static const Map<String, Map<String, String>> _strings = <String, Map<String, String>>{
    'appSubtitle': {
      'fr': 'AAI Studio', 'en': 'AAI Studio', 'de': 'AAI Studio',
      'es': 'AAI Studio', 'zh': 'AAI Studio', 'ru': 'AAI Studio',
      'si': 'AAI Studio',
    },
    'tagline': {
      'fr': 'Géographie culturelle · Neo-Soul',
      'en': 'Cultural geography · Neo-Soul',
      'de': 'Kulturgeografie · Neo-Soul',
      'es': 'Geografía cultural · Neo-Soul',
      'zh': '文化地理 · 新灵魂乐',
      'ru': 'Культурная география · Neo-Soul',
      'si': 'සංස්කෘතික භූගෝල විද්‍යාව · Neo-Soul',
    },
    'modeClassic': {
      'fr': 'CLASSIQUE', 'en': 'CLASSIC', 'de': 'KLASSISCH',
      'es': 'CLÁSICO', 'zh': '经典模式', 'ru': 'КЛАССИКА',
      'si': 'සම්භාව්‍ය',
    },
    'modeClassicDesc': {
      'fr': 'Carte du monde', 'en': 'World map', 'de': 'Weltkarte',
      'es': 'Mapa del mundo', 'zh': '世界地图', 'ru': 'Карта мира',
      'si': 'ලෝක සිතියම',
    },
    'modeShadow': {
      'fr': 'OMBRE CHINOISE', 'en': 'SHADOW QUIZ', 'de': 'SCHATTENSPIEL',
      'es': 'SOMBRAS CHINESCAS', 'zh': '皮影猜城', 'ru': 'ТЕНЕВОЙ КВИЗ',
      'si': 'සෙවණැලි රූප',
    },
    'modeShadowDesc': {
      'fr': 'Quiz fresques culturelles', 'en': 'Cultural skyline quiz',
      'de': 'Kulturelles Skyline-Quiz', 'es': 'Quiz de frescos culturales',
      'zh': '文化剪影问答', 'ru': 'Квиз культурных панорам',
      'si': 'සංස්කෘතික සෙවණැලි ප්‍රශ්න',
    },
    'shadowNormal': {
      'fr': 'Normal', 'en': 'Normal', 'de': 'Normal', 'es': 'Normal', 'zh': '普通', 'ru': 'Обычный', 'si': 'සාමාන්‍ය',
    },
    'shadowRapid': {
      'fr': 'Rapid Fire', 'en': 'Rapid Fire', 'de': 'Rapid Fire', 'es': 'Rapid Fire',
      'zh': '极速模式', 'ru': 'Rapid Fire', 'si': 'Rapid Fire',
    },
    'shadowNormalDesc': {
      'fr': 'La fresque complète dès le départ.',
      'en': 'The full skyline from the start.',
      'de': 'Das ganze Panorama von Anfang an.',
      'es': 'El fresco completo desde el inicio.',
      'zh': '一开始就显示完整剪影。',
      'ru': 'Вся панорама сразу.',
      'si': 'මුල සිටම සම්පූර්ණ සෙවණැලි චිත්‍රය.',
    },
    'shadowRapidDesc': {
      'fr': 'Les ombres apparaissent une à une : trouvez au plus vite, bonus ×2 !',
      'en': 'Shadows appear one by one: guess as fast as you can, bonus ×2!',
      'de': 'Die Schatten erscheinen nach und nach: schnell raten, Bonus ×2!',
      'es': 'Las sombras aparecen una a una: ¡adivina rápido, bonus ×2!',
      'zh': '剪影逐一出现：越快猜中，奖励×2！',
      'ru': 'Тени появляются по одной: угадайте быстрее, бонус ×2!',
      'si': 'සෙවණැලි එකින් එක දිස් වේ: ඉක්මනින් සොයන්න, ප්‍රසාද ×2!',
    },
    'didYouKnow': {
      'fr': 'Le saviez-vous ?', 'en': 'Did you know?', 'de': 'Schon gewusst?', 'es': '¿Sabías que…?',
      'zh': '你知道吗？', 'ru': 'А вы знали?', 'si': 'ඔබ දැන සිටියාද?',
    },
    'timer': {
      'fr': 'Chrono', 'en': 'Timer', 'de': 'Zeit',
      'es': 'Tiempo', 'zh': '计时', 'ru': 'Таймер',
      'si': 'කාලය',
    },
    'play': {
      'fr': 'JOUER', 'en': 'PLAY', 'de': 'SPIELEN',
      'es': 'JUGAR', 'zh': '开始', 'ru': 'ИГРАТЬ',
      'si': 'ක්‍රීඩා කරන්න',
    },
    'restorePurchases': {
      'fr': 'Restaurer mes achats', 'en': 'Restore purchases', 'de': 'Käufe wiederherstellen',
      'es': 'Restaurar compras', 'zh': '恢复购买', 'ru': 'Восстановить покупки',
      'si': 'මිලදී ගැනීම් ප්‍රතිසාධනය කරන්න',
    },
    'unlockWorld': {
      'fr': 'Débloquer le monde entier', 'en': 'Unlock the whole world',
      'de': 'Ganze Welt freischalten', 'es': 'Desbloquear el mundo entero',
      'zh': '解锁全世界', 'ru': 'Открыть весь мир',
      'si': 'මුළු ලෝකයම විවෘත කරන්න',
    },
    'premiumActive': {
      'fr': 'Monde entier débloqué ✦', 'en': 'Whole world unlocked ✦',
      'de': 'Ganze Welt freigeschaltet ✦', 'es': 'Mundo entero desbloqueado ✦',
      'zh': '全世界已解锁 ✦', 'ru': 'Весь мир открыт ✦',
      'si': 'මුළු ලෝකයම විවෘතයි ✦',
    },
    'restoreDone': {
      'fr': 'Achats restaurés.', 'en': 'Purchases restored.', 'de': 'Käufe wiederhergestellt.',
      'es': 'Compras restauradas.', 'zh': '购买已恢复。', 'ru': 'Покупки восстановлены.',
      'si': 'මිලදී ගැනීම් ප්‍රතිසාධනය විය.',
    },
    'restoreNothing': {
      'fr': 'Aucun achat à restaurer.', 'en': 'No purchase to restore.',
      'de': 'Keine Käufe zum Wiederherstellen.', 'es': 'No hay compras que restaurar.',
      'zh': '没有可恢复的购买。', 'ru': 'Нет покупок для восстановления.',
      'si': 'ප්‍රතිසාධනය කිරීමට මිලදී ගැනීමක් නැත.',
    },
    'storeUnavailable': {
      'fr': 'Boutique indisponible pour le moment.', 'en': 'Store unavailable right now.',
      'de': 'Store derzeit nicht verfügbar.', 'es': 'Tienda no disponible por ahora.',
      'zh': '商店暂不可用。', 'ru': 'Магазин сейчас недоступен.',
      'si': 'වෙළඳසැල දැනට ලබා ගත නොහැක.',
    },
    'purchaseError': {
      'fr': 'L\'achat a échoué.', 'en': 'Purchase failed.', 'de': 'Kauf fehlgeschlagen.',
      'es': 'La compra ha fallado.', 'zh': '购买失败。', 'ru': 'Покупка не удалась.',
      'si': 'මිලදී ගැනීම අසාර්ථක විය.',
    },
    'purchaseSuccess': {
      'fr': 'Merci ! Le monde entier est débloqué.', 'en': 'Thank you! The whole world is unlocked.',
      'de': 'Danke! Die ganze Welt ist freigeschaltet.', 'es': '¡Gracias! El mundo entero está desbloqueado.',
      'zh': '谢谢！全世界已解锁。', 'ru': 'Спасибо! Весь мир открыт.',
      'si': 'ස්තූතියි! මුළු ලෝකයම විවෘතයි.',
    },
    'language': {
      'fr': 'Langue', 'en': 'Language', 'de': 'Sprache',
      'es': 'Idioma', 'zh': '语言', 'ru': 'Язык',
      'si': 'භාෂාව',
    },
    'musicOn': {
      'fr': 'Couper la musique', 'en': 'Mute music', 'de': 'Musik aus',
      'es': 'Silenciar música', 'zh': '关闭音乐', 'ru': 'Выключить музыку',
      'si': 'සංගීතය නිහඬ කරන්න',
    },
    'musicOff': {
      'fr': 'Activer la musique', 'en': 'Unmute music', 'de': 'Musik an',
      'es': 'Activar música', 'zh': '开启音乐', 'ru': 'Включить музыку',
      'si': 'සංගීතය සක්‍රිය කරන්න',
    },
    'themeToggle': {
      'fr': 'Changer de thème', 'en': 'Switch theme', 'de': 'Design wechseln',
      'es': 'Cambiar tema', 'zh': '切换主题', 'ru': 'Сменить тему',
      'si': 'තේමාව මාරු කරන්න',
    },
    'bestScore': {
      'fr': 'Record', 'en': 'Best', 'de': 'Rekord',
      'es': 'Récord', 'zh': '最高分', 'ru': 'Рекорд',
      'si': 'වාර්තාව',
    },
    'whereIs': {
      'fr': 'Où se trouve', 'en': 'Where is', 'de': 'Wo liegt',
      'es': 'Dónde está', 'zh': '在哪里：', 'ru': 'Где находится',
      'si': 'කොහේද',
    },
    'tapToPlace': {
      'fr': 'Touchez la carte pour placer votre épingle',
      'en': 'Tap the map to drop your pin',
      'de': 'Tippe auf die Karte, um deine Nadel zu setzen',
      'es': 'Toca el mapa para colocar tu marcador',
      'zh': '点击地图放置图钉',
      'ru': 'Коснитесь карты, чтобы поставить метку',
      'si': 'ඔබේ අල්පෙනෙත්ත තැබීමට සිතියම ස්පර්ශ කරන්න',
    },
    'validate': {
      'fr': 'VALIDER', 'en': 'CONFIRM', 'de': 'BESTÄTIGEN',
      'es': 'CONFIRMAR', 'zh': '确认', 'ru': 'ПОДТВЕРДИТЬ',
      'si': 'තහවුරු කරන්න',
    },
    'next': {
      'fr': 'SUIVANT', 'en': 'NEXT', 'de': 'WEITER',
      'es': 'SIGUIENTE', 'zh': '下一题', 'ru': 'ДАЛЕЕ',
      'si': 'ඊළඟ',
    },
    'seeResults': {
      'fr': 'RÉSULTATS', 'en': 'RESULTS', 'de': 'ERGEBNIS',
      'es': 'RESULTADOS', 'zh': '查看结果', 'ru': 'ИТОГИ',
      'si': 'ප්‍රතිඵල',
    },
    'round': {
      'fr': 'Manche {n}/{total}', 'en': 'Round {n}/{total}', 'de': 'Runde {n}/{total}',
      'es': 'Ronda {n}/{total}', 'zh': '第 {n}/{total} 轮', 'ru': 'Раунд {n}/{total}',
      'si': 'වටය {n}/{total}',
    },
    'distance': {
      'fr': '{km} km de la cible', 'en': '{km} km from target', 'de': '{km} km vom Ziel',
      'es': 'a {km} km del objetivo', 'zh': '距目标 {km} 公里', 'ru': '{km} км от цели',
      'si': 'ඉලක්කයේ සිට කි.මී. {km}',
    },
    'pointsGained': {
      'fr': '+{pts} pts', 'en': '+{pts} pts', 'de': '+{pts} Pkt',
      'es': '+{pts} pts', 'zh': '+{pts} 分', 'ru': '+{pts} очк.',
      'si': '+{pts} ලකුණු',
    },
    'timeUp': {
      'fr': 'Temps écoulé !', 'en': 'Time\'s up!', 'de': 'Zeit abgelaufen!',
      'es': '¡Se acabó el tiempo!', 'zh': '时间到！', 'ru': 'Время вышло!',
      'si': 'කාලය අවසන්!',
    },
    'noGuess': {
      'fr': 'Aucune épingle posée', 'en': 'No pin dropped', 'de': 'Keine Nadel gesetzt',
      'es': 'Ningún marcador', 'zh': '未放置图钉', 'ru': 'Метка не поставлена',
      'si': 'අල්පෙනෙත්තක් තැබුවේ නැත',
    },
    'gameOver': {
      'fr': 'Partie terminée', 'en': 'Game over', 'de': 'Spiel beendet',
      'es': 'Fin de la partida', 'zh': '游戏结束', 'ru': 'Игра окончена',
      'si': 'ක්‍රීඩාව අවසන්',
    },
    'totalScore': {
      'fr': 'Score total', 'en': 'Total score', 'de': 'Gesamtpunktzahl',
      'es': 'Puntuación total', 'zh': '总分', 'ru': 'Итоговый счёт',
      'si': 'මුළු ලකුණු',
    },
    'newRecord': {
      'fr': 'Nouveau record !', 'en': 'New record!', 'de': 'Neuer Rekord!',
      'es': '¡Nuevo récord!', 'zh': '新纪录！', 'ru': 'Новый рекорд!',
      'si': 'නව වාර්තාවක්!',
    },
    'playAgain': {
      'fr': 'REJOUER', 'en': 'PLAY AGAIN', 'de': 'NOCHMAL',
      'es': 'OTRA VEZ', 'zh': '再玩一次', 'ru': 'ЕЩЁ РАЗ',
      'si': 'නැවත ක්‍රීඩා කරන්න',
    },
    'backToMenu': {
      'fr': 'Menu', 'en': 'Menu', 'de': 'Menü',
      'es': 'Menú', 'zh': '菜单', 'ru': 'Меню',
      'si': 'මෙනුව',
    },
    'loading': {
      'fr': 'Chargement…', 'en': 'Loading…', 'de': 'Lädt…',
      'es': 'Cargando…', 'zh': '加载中…', 'ru': 'Загрузка…',
      'si': 'පූරණය වෙමින්…',
    },
    'catalogError': {
      'fr': 'Impossible de charger le catalogue.', 'en': 'Unable to load the catalog.',
      'de': 'Katalog konnte nicht geladen werden.', 'es': 'No se pudo cargar el catálogo.',
      'zh': '无法加载城市目录。', 'ru': 'Не удалось загрузить каталог.',
      'si': 'නාමාවලිය පූරණය කළ නොහැක.',
    },
    'freeCitiesInfo': {
      'fr': '{free} villes gratuites · {total} avec Premium',
      'en': '{free} free cities · {total} with Premium',
      'de': '{free} Gratis-Städte · {total} mit Premium',
      'es': '{free} ciudades gratis · {total} con Premium',
      'zh': '{free} 座免费城市 · 高级版 {total} 座',
      'ru': '{free} бесплатных городов · {total} с Premium',
      'si': 'නොමිලේ නගර {free} · Premium සමඟ {total}',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
