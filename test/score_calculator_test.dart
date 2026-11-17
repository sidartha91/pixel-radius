import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_radius/shadow_quiz/logic/quiz_models.dart';
import 'package:pixel_radius/shadow_quiz/logic/score_calculator.dart';

QuizCity _city(String id, String cc, List<String> alts) => QuizCity.fromJson(<String, dynamic>{
      'id': id,
      'country_code': cc,
      'name': <String, String>{'en': id},
      'country': <String, String>{'en': cc},
      'alternative_cities': alts,
      'monuments': const <Object>[],
      'culture_life': const <Object>[],
    });

void main() {
  group('ScoreCalculator', () {
    test('capitale exacte = 1000 + temps_restant * 20', () {
      final r = ScoreCalculator.evaluate(
        selectedCityId: 'colombo', selectedCountryCode: 'LK',
        targetCityId: 'colombo', targetCountryCode: 'LK', secondsRemaining: 12,
      );
      expect(r.outcome, AnswerOutcome.exact);
      expect(r.total, 1000 + 12 * 20);
    });

    test('bon pays, ville secondaire = 350 fixes', () {
      final r = ScoreCalculator.evaluate(
        selectedCityId: 'colombo#alt0', selectedCountryCode: 'LK',
        targetCityId: 'colombo', targetCountryCode: 'LK', secondsRemaining: 20,
      );
      expect(r.outcome, AnswerOutcome.sameCountry);
      expect(r.total, 350);
    });

    test('mauvais pays = 0', () {
      final r = ScoreCalculator.evaluate(
        selectedCityId: 'paris', selectedCountryCode: 'FR',
        targetCityId: 'colombo', targetCountryCode: 'LK', secondsRemaining: 20,
      );
      expect(r.outcome, AnswerOutcome.wrong);
      expect(r.total, 0);
    });

    test('temps écoulé = 0', () {
      final r = ScoreCalculator.evaluate(
        selectedCityId: null, selectedCountryCode: null,
        targetCityId: 'colombo', targetCountryCode: 'LK', secondsRemaining: 0,
      );
      expect(r.outcome, AnswerOutcome.timeout);
      expect(r.total, 0);
    });
  });

  test('QuizRoundBuilder : 11 choix = 1 bonne + 2 même pays + 8 autres pays', () {
    final cities = <QuizCity>[
      _city('colombo', 'LK', <String>['Kandy', 'Galle', 'Kotte']),
      for (var i = 0; i < 12; i++) _city('c$i', 'X$i', <String>['a', 'b']),
    ];
    final round = QuizRoundBuilder.build(
      target: cities.first, allCities: cities, languageCode: 'fr', random: Random(1),
    );
    expect(round.options.length, 11);
    expect(round.options.where((o) => o.kind == QuizOptionKind.correct).length, 1);
    expect(round.options.where((o) => o.kind == QuizOptionKind.sameCountryDecoy).length, 2);
    final others = round.options.where((o) => o.kind == QuizOptionKind.otherCountryDecoy);
    expect(others.length, 8);
    expect(others.map((o) => o.countryCode).toSet().length, 8);
  });
}
