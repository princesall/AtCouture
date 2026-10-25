import 'package:equatable/equatable.dart';

/// Moyen d'encaissement d'un versement.
///
/// Les valeurs correspondent aux usages réels d'un atelier de couture en
/// Afrique de l'Ouest : espèces, Wave, Orange Money, virement/chèque, et une
/// échappatoire « Autre » pour ne jamais bloquer la saisie.
enum PaymentMethod {
  cash('Espèces'),
  wave('Wave'),
  orangeMoney('Orange Money'),
  bank('Virement / chèque'),
  other('Autre');

  const PaymentMethod(this.label);

  final String label;

  /// Tolère les valeurs inconnues (document écrit par une version plus
  /// récente de l'app) en retombant sur « Espèces » plutôt qu'en levant.
  static PaymentMethod fromName(String? name) => values.firstWhere(
        (m) => m.name == name,
        orElse: () => PaymentMethod.cash,
      );
}

/// Un versement reçu sur une commande — acompte initial ou règlement partiel.
///
/// Une commande porte une LISTE de versements (voir `Order.payments`) et non
/// plus un montant unique : un client qui règle en trois fois laisse trois
/// traces datées, et le solde restant se recalcule tout seul.
class OrderPayment extends Equatable {
  const OrderPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.method = PaymentMethod.cash,
    this.note,
  });

  /// Identifiant stable dans la liste (sert à supprimer un versement saisi
  /// par erreur) — généré côté appelant avec un UUID.
  final String id;

  /// Montant en FCFA (entier, la devise n'a pas de centimes).
  final int amount;

  final DateTime paidAt;
  final PaymentMethod method;
  final String? note;

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
        'method': method.name,
        'note': note,
      };

  factory OrderPayment.fromMap(Map<String, dynamic> map) => OrderPayment(
        id: map['id'] as String? ?? '',
        amount: (map['amount'] as num?)?.toInt() ?? 0,
        paidAt:
            DateTime.tryParse(map['paidAt'] as String? ?? '') ?? DateTime.now(),
        method: PaymentMethod.fromName(map['method'] as String?),
        note: map['note'] as String?,
      );

  @override
  List<Object?> get props => [id, amount, paidAt, method, note];
}
