/// Résultat d'une réponse au Shadow Quiz.
enum AnswerOutcome {
  /// Capitale de référence exacte.
  exact,

  /// Bon pays, mais ville secondaire (`selectedCountry == targetCountry`).
  sameCountry,

  /// Mauvais pays.
  wrong,

  /// Temps écoulé sans réponse.
  timeout,
}

class ScoreResult {
  const ScoreResult({
    required this.outcome,
    required this.basePoints,
    required this.speedBonus,
  });

  final AnswerOutcome outcome;
  final int basePoints;
  final int speedBonus;

  int get total => basePoints + speedBonus;

  bool get isExact => outcome == AnswerOutcome.exact;
  bool get isPartial => outcome == AnswerOutcome.sameCountry;
}

/// Double scoring du mode Ombre Chinoise.
///
/// - Capitale exacte : 1000 pts + bonus rapidité (`temps_restant * 20`).
/// - Bon pays, autre ville : 350 pts fixes, sans bonus temps.
/// - Mauvais pays / temps écoulé : 0 pt.
class ScoreCalculator {
  const ScoreCalculator._();

  static const int exactPoints = 1000;
  static const int speedBonusPerSecond = 20;
  static const int sameCountryPoints = 350;

  static ScoreResult evaluate({
    required String? selectedCityId,
    required String? selectedCountryCode,
    required String targetCityId,
    required String targetCountryCode,
    required int secondsRemaining,
  }) {
    if (selectedCityId == null || selectedCountryCode == null) {
      return const ScoreResult(outcome: AnswerOutcome.timeout, basePoints: 0, speedBonus: 0);
    }
    if (selectedCityId == targetCityId && selectedCountryCode == targetCountryCode) {
      final remaining = secondsRemaining < 0 ? 0 : secondsRemaining;
      return ScoreResult(
        outcome: AnswerOutcome.exact,
        basePoints: exactPoints,
        speedBonus: remaining * speedBonusPerSecond,
      );
    }
    if (selectedCountryCode == targetCountryCode) {
      return const ScoreResult(
        outcome: AnswerOutcome.sameCountry,
        basePoints: sameCountryPoints,
        speedBonus: 0,
      );
    }
    return const ScoreResult(outcome: AnswerOutcome.wrong, basePoints: 0, speedBonus: 0);
  }

  /// Score maximal théorique d'une partie.
  static int maxScore({required int rounds, required int durationSeconds}) =>
      rounds * (exactPoints + durationSeconds * speedBonusPerSecond);
}
