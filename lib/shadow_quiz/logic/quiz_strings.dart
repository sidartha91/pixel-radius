/// Textes du module Shadow Quiz (autonome, 7 langues).
class QuizStrings {
  const QuizStrings(this.languageCode);

  final String languageCode;

  String _t(Map<String, String> m) => m[languageCode] ?? m['en']!;

  String get question => _t(const {
        'fr': 'Quelle ville se cache dans cette fresque ?',
        'en': 'Which city hides in this skyline?',
        'de': 'Welche Stadt verbirgt sich in diesem Panorama?',
        'es': '¿Qué ciudad se esconde en este fresco?',
        'zh': '这幅剪影藏着哪座城市？',
        'ru': 'Какой город скрыт в этой панораме?',
        'si': 'මෙම සෙවණැලි චිත්‍රයේ සැඟවී ඇත්තේ කුමන නගරයද?',
      });

  String get exact => _t(const {
        'fr': 'Capitale exacte !', 'en': 'Spot on!', 'de': 'Volltreffer!',
        'es': '¡Exacto!', 'zh': '完全正确！', 'ru': 'В точку!',
        'si': 'නිවැරදියි!',
      });

  String get rightCountry => _t(const {
        'fr': 'Bon pays ! (+350 pts)', 'en': 'Right country! (+350 pts)',
        'de': 'Richtiges Land! (+350 Pkt)', 'es': '¡País correcto! (+350 pts)',
        'zh': '国家正确！(+350 分)', 'ru': 'Верная страна! (+350 очк.)',
        'si': 'නිවැරදි රට! (+ලකුණු 350)',
      });

  String get wrong => _t(const {
        'fr': 'Mauvais pays', 'en': 'Wrong country', 'de': 'Falsches Land',
        'es': 'País equivocado', 'zh': '国家错误', 'ru': 'Не та страна',
        'si': 'වැරදි රට',
      });

  String get timeUp => _t(const {
        'fr': 'Temps écoulé !', 'en': 'Time\'s up!', 'de': 'Zeit abgelaufen!',
        'es': '¡Se acabó el tiempo!', 'zh': '时间到！', 'ru': 'Время вышло!',
        'si': 'කාලය අවසන්!',
      });

  String get next => _t(const {
        'fr': 'SUIVANT', 'en': 'NEXT', 'de': 'WEITER',
        'es': 'SIGUIENTE', 'zh': '下一题', 'ru': 'ДАЛЕЕ',
        'si': 'ඊළඟ',
      });

  String get results => _t(const {
        'fr': 'RÉSULTATS', 'en': 'RESULTS', 'de': 'ERGEBNIS',
        'es': 'RESULTADOS', 'zh': '查看结果', 'ru': 'ИТОГИ',
        'si': 'ප්‍රතිඵල',
      });

  String get gameOver => _t(const {
        'fr': 'Fin de la tournée', 'en': 'Tour complete', 'de': 'Tour beendet',
        'es': 'Fin de la gira', 'zh': '巡游结束', 'ru': 'Тур завершён',
        'si': 'චාරිකාව අවසන්',
      });

  String get totalScore => _t(const {
        'fr': 'Score total', 'en': 'Total score', 'de': 'Gesamtpunktzahl',
        'es': 'Puntuación total', 'zh': '总分', 'ru': 'Итоговый счёт',
        'si': 'මුළු ලකුණු',
      });

  String get newRecord => _t(const {
        'fr': 'Nouveau record !', 'en': 'New record!', 'de': 'Neuer Rekord!',
        'es': '¡Nuevo récord!', 'zh': '新纪录！', 'ru': 'Новый рекорд!',
        'si': 'නව වාර්තාවක්!',
      });

  String get playAgain => _t(const {
        'fr': 'REJOUER', 'en': 'PLAY AGAIN', 'de': 'NOCHMAL',
        'es': 'OTRA VEZ', 'zh': '再玩一次', 'ru': 'ЕЩЁ РАЗ',
        'si': 'නැවත ක්‍රීඩා කරන්න',
      });

  String get menu => _t(const {
        'fr': 'Menu', 'en': 'Menu', 'de': 'Menü', 'es': 'Menú', 'zh': '菜单', 'ru': 'Меню',
        'si': 'මෙනුව',
      });

  String get loading => _t(const {
        'fr': 'Assemblage de la fresque…', 'en': 'Assembling the skyline…',
        'de': 'Panorama wird gebaut…', 'es': 'Montando el fresco…',
        'zh': '正在拼装剪影…', 'ru': 'Собираем панораму…',
        'si': 'සෙවණැලි චිත්‍රය සකසමින්…',
      });

  String get loadError => _t(const {
        'fr': 'Impossible de charger le quiz.', 'en': 'Unable to load the quiz.',
        'de': 'Quiz konnte nicht geladen werden.', 'es': 'No se pudo cargar el quiz.',
        'zh': '无法加载问答。', 'ru': 'Не удалось загрузить квиз.',
        'si': 'ප්‍රශ්නාවලිය පූරණය කළ නොහැක.',
      });

  String round(int n, int total) => _t({
        'fr': 'Manche $n/$total', 'en': 'Round $n/$total', 'de': 'Runde $n/$total',
        'es': 'Ronda $n/$total', 'zh': '第 $n/$total 轮', 'ru': 'Раунд $n/$total',
        'si': 'වටය $n/$total',
      });

  String points(int pts) => _t({
        'fr': '+$pts pts', 'en': '+$pts pts', 'de': '+$pts Pkt',
        'es': '+$pts pts', 'zh': '+$pts 分', 'ru': '+$pts очк.',
        'si': '+ලකුණු $pts',
      });

  String answerWas(String city, String country) => _t({
        'fr': 'Réponse : $city, $country', 'en': 'Answer: $city, $country',
        'de': 'Lösung: $city, $country', 'es': 'Respuesta: $city, $country',
        'zh': '答案：$city，$country', 'ru': 'Ответ: $city, $country',
        'si': 'පිළිතුර: $city, $country',
      });

  String summary(int exact, int partial, int rounds) => _t({
        'fr': '$exact exactes · $partial bons pays · $rounds manches',
        'en': '$exact exact · $partial right country · $rounds rounds',
        'de': '$exact exakt · $partial richtiges Land · $rounds Runden',
        'es': '$exact exactas · $partial país correcto · $rounds rondas',
        'zh': '$exact 完全正确 · $partial 国家正确 · 共 $rounds 轮',
        'ru': '$exact точно · $partial верная страна · $rounds раундов',
        'si': 'නිවැරදි $exact · නිවැරදි රට $partial · වට $rounds',
      });
}
