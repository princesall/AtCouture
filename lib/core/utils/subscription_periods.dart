/// Calculs de période d'abonnement partagés par la console admin et
/// l'enregistrement des paiements.
///
/// Les plans StyleConnect sont facturés au mois (`SubscriptionPlan.priceLabel`
/// affiche « .../mois »). Un renouvellement peut néanmoins couvrir plusieurs
/// mois (1 à 12) : la durée est désormais choisie par l'admin au moment de
/// l'action, au lieu d'un « 12 mois » codé en dur qui ne correspondait ni au
/// prix affiché ni à l'approbation d'un plan (30 jours).
abstract final class SubscriptionPeriods {
  /// Bornes du sélecteur de durée proposé à l'admin.
  static const int minMonths = 1;
  static const int maxMonths = 12;

  /// Ajoute [months] mois calendaires à [date].
  ///
  /// Le jour est borné au dernier jour du mois cible : le 31 janvier + 1 mois
  /// donne le 28 (ou 29) février, jamais le 3 mars. L'heure est conservée.
  static DateTime addMonths(DateTime date, int months) {
    final rawMonth = date.month + months;
    final year = date.year + (rawMonth - 1) ~/ 12;
    final month = (rawMonth - 1) % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }

  /// Point de départ du renouvellement.
  ///
  /// Si l'abonnement est encore valide, la prolongation part de l'échéance en
  /// cours : renouveler un compte à qui il reste 6 mois ne doit pas lui faire
  /// perdre ces 6 mois. Sinon, elle part de maintenant.
  static DateTime renewalStart(DateTime? currentExpiry, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return currentExpiry != null && currentExpiry.isAfter(current)
        ? currentExpiry
        : current;
  }

  /// Nouvelle échéance après un renouvellement de [months] mois.
  static DateTime renewalEnd(
    DateTime? currentExpiry,
    int months, {
    DateTime? now,
  }) => addMonths(
    renewalStart(currentExpiry, now: now),
    months.clamp(minMonths, maxMonths).toInt(),
  );

  /// « 1 mois », « 3 mois »... — évite les « 1 mois » grammaticalement faux
  /// dans certains libellés composés.
  static String monthsLabel(int months) =>
      months == 1 ? '1 mois' : '$months mois';
}
