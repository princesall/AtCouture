import '../models/subscription_plan.dart';

/// Données 100 % factices de la maquette admin web.
///
/// Aucun accès Firebase, aucune authentification : uniquement de quoi juger
/// le layout, les densités, les hiérarchies typographiques et les tableaux.
/// À remplacer par les services réels (`AdminDemoData`, `SubscriptionService`,
/// `SupportMessageService`) au moment de la vraie migration.

enum PreviewAccountStatus { active, expiring, suspended }

extension PreviewAccountStatusX on PreviewAccountStatus {
  String get label => switch (this) {
        PreviewAccountStatus.active => 'Actif',
        PreviewAccountStatus.expiring => 'Expire bientôt',
        PreviewAccountStatus.suspended => 'Suspendu',
      };
}

enum PreviewRequestStatus { pending, approved, rejected }

extension PreviewRequestStatusX on PreviewRequestStatus {
  String get label => switch (this) {
        PreviewRequestStatus.pending => 'En attente',
        PreviewRequestStatus.approved => 'Approuvée',
        PreviewRequestStatus.rejected => 'Refusée',
      };
}

class PreviewStylist {
  const PreviewStylist({
    required this.name,
    required this.atelier,
    required this.email,
    required this.city,
    required this.plan,
    required this.status,
    required this.orders,
    required this.revenue,
    required this.expiresInDays,
    required this.lastActive,
    this.online = false,
  });

  final String name;
  final String atelier;
  final String email;
  final String city;
  final SubscriptionPlan plan;
  final PreviewAccountStatus status;
  final int orders;
  final int revenue;

  /// Nombre de jours avant expiration ; null = pas d'expiration (gratuit).
  final int? expiresInDays;
  final String lastActive;
  final bool online;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length < 2) return name.isEmpty ? '?' : name[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class PreviewRequest {
  const PreviewRequest({
    required this.name,
    required this.atelier,
    required this.plan,
    required this.requestedAt,
    required this.status,
    this.note,
  });

  final String name;
  final String atelier;
  final SubscriptionPlan plan;
  final DateTime requestedAt;
  final PreviewRequestStatus status;
  final String? note;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length < 2) return name.isEmpty ? '?' : name[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class PreviewMessage {
  const PreviewMessage({
    required this.author,
    required this.text,
    required this.time,
    this.fromAdmin = false,
  });

  final String author;
  final String text;
  final String time;
  final bool fromAdmin;
}

class PreviewThread {
  const PreviewThread({
    required this.name,
    required this.atelier,
    required this.role,
    required this.lastMessage,
    required this.time,
    required this.messages,
    this.unread = 0,
    this.flagged = false,
  });

  final String name;
  final String atelier;
  final String role;
  final String lastMessage;
  final String time;
  final List<PreviewMessage> messages;
  final int unread;
  final bool flagged;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length < 2) return name.isEmpty ? '?' : name[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatage local — pas d'intl, pas d'initialisation de locale : la maquette
// doit démarrer partout, y compris hors ligne.
// ─────────────────────────────────────────────────────────────────────────────

const _monthsShort = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

String previewDate(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

String previewShortDate(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';

String fcfa(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}$buffer FCFA';
}

String compactFcfa(int amount) {
  if (amount >= 1000000) {
    final m = amount / 1000000;
    return '${m.toStringAsFixed(m >= 10 ? 0 : 1).replaceAll('.', ',')} M FCFA';
  }
  if (amount >= 1000) {
    final k = amount / 1000;
    return '${k.toStringAsFixed(k >= 100 ? 0 : 1).replaceAll('.', ',')} k FCFA';
  }
  return fcfa(amount);
}

// ─────────────────────────────────────────────────────────────────────────────
// Contenu de démonstration
// ─────────────────────────────────────────────────────────────────────────────

const previewStylists = <PreviewStylist>[
  PreviewStylist(
    name: 'Aminata Traoré',
    atelier: 'Atelier Wax & Soie',
    email: 'aminata.traore@mail.ml',
    city: 'Bamako',
    plan: SubscriptionPlan.pro,
    status: PreviewAccountStatus.active,
    orders: 184,
    revenue: 412000,
    expiresInDays: 42,
    lastActive: 'il y a 4 min',
    online: true,
  ),
  PreviewStylist(
    name: 'Fatoumata Diallo',
    atelier: 'Maison Fato',
    email: 'f.diallo@mail.ml',
    city: 'Bamako',
    plan: SubscriptionPlan.enterprise,
    status: PreviewAccountStatus.active,
    orders: 312,
    revenue: 745000,
    expiresInDays: 118,
    lastActive: 'il y a 12 min',
    online: true,
  ),
  PreviewStylist(
    name: 'Ibrahim Keïta',
    atelier: 'Le Fil d\'Or',
    email: 'i.keita@mail.ml',
    city: 'Sikasso',
    plan: SubscriptionPlan.starter,
    status: PreviewAccountStatus.expiring,
    orders: 67,
    revenue: 128000,
    expiresInDays: 5,
    lastActive: 'il y a 2 h',
  ),
  PreviewStylist(
    name: 'Mariam Coulibaly',
    atelier: 'Couture Mariam',
    email: 'mariam.c@mail.ml',
    city: 'Ségou',
    plan: SubscriptionPlan.free,
    status: PreviewAccountStatus.active,
    orders: 9,
    revenue: 0,
    expiresInDays: null,
    lastActive: 'hier',
  ),
  PreviewStylist(
    name: 'Ousmane Sangaré',
    atelier: 'Sangaré Haute Couture',
    email: 'o.sangare@mail.ml',
    city: 'Bamako',
    plan: SubscriptionPlan.pro,
    status: PreviewAccountStatus.active,
    orders: 221,
    revenue: 389000,
    expiresInDays: 76,
    lastActive: 'il y a 28 min',
    online: true,
  ),
  PreviewStylist(
    name: 'Kadidia Touré',
    atelier: 'Kadi Style',
    email: 'k.toure@mail.ml',
    city: 'Mopti',
    plan: SubscriptionPlan.starter,
    status: PreviewAccountStatus.expiring,
    orders: 41,
    revenue: 96000,
    expiresInDays: 3,
    lastActive: 'il y a 5 h',
  ),
  PreviewStylist(
    name: 'Seydou Bagayoko',
    atelier: 'Bagayoko & Frères',
    email: 's.bagayoko@mail.ml',
    city: 'Kayes',
    plan: SubscriptionPlan.free,
    status: PreviewAccountStatus.suspended,
    orders: 14,
    revenue: 0,
    expiresInDays: null,
    lastActive: 'il y a 6 j',
  ),
  PreviewStylist(
    name: 'Awa Cissé',
    atelier: 'Awa Couture Paris',
    email: 'awa.cisse@mail.ml',
    city: 'Bamako',
    plan: SubscriptionPlan.enterprise,
    status: PreviewAccountStatus.active,
    orders: 408,
    revenue: 912000,
    expiresInDays: 201,
    lastActive: 'il y a 1 h',
    online: true,
  ),
  PreviewStylist(
    name: 'Bakary Diarra',
    atelier: 'Diarra Tissus',
    email: 'b.diarra@mail.ml',
    city: 'Bamako',
    plan: SubscriptionPlan.starter,
    status: PreviewAccountStatus.active,
    orders: 53,
    revenue: 104000,
    expiresInDays: 29,
    lastActive: 'il y a 3 h',
  ),
  PreviewStylist(
    name: 'Nana Sylla',
    atelier: 'Nana Broderie',
    email: 'nana.sylla@mail.ml',
    city: 'Ségou',
    plan: SubscriptionPlan.pro,
    status: PreviewAccountStatus.suspended,
    orders: 98,
    revenue: 201000,
    expiresInDays: 14,
    lastActive: 'il y a 9 j',
  ),
];

final previewRequests = <PreviewRequest>[
  PreviewRequest(
    name: 'Ibrahim Keïta',
    atelier: 'Le Fil d\'Or',
    plan: SubscriptionPlan.pro,
    requestedAt: DateTime(2026, 10, 31, 9, 24),
    status: PreviewRequestStatus.pending,
    note: 'Renouvellement après 6 mois en Starter.',
  ),
  PreviewRequest(
    name: 'Kadidia Touré',
    atelier: 'Kadi Style',
    plan: SubscriptionPlan.starter,
    requestedAt: DateTime(2026, 10, 30, 17, 2),
    status: PreviewRequestStatus.pending,
  ),
  PreviewRequest(
    name: 'Moussa Konaté',
    atelier: 'Konaté Frères',
    plan: SubscriptionPlan.enterprise,
    requestedAt: DateTime(2026, 10, 30, 11, 45),
    status: PreviewRequestStatus.pending,
    note: '3 ateliers à rattacher (Bamako, Sikasso, Kayes).',
  ),
  PreviewRequest(
    name: 'Aïssata Maïga',
    atelier: 'Maïga Créations',
    plan: SubscriptionPlan.pro,
    requestedAt: DateTime(2026, 10, 29, 15, 12),
    status: PreviewRequestStatus.pending,
  ),
  PreviewRequest(
    name: 'Bakary Diarra',
    atelier: 'Diarra Tissus',
    plan: SubscriptionPlan.starter,
    requestedAt: DateTime(2026, 10, 29, 8, 30),
    status: PreviewRequestStatus.approved,
  ),
  PreviewRequest(
    name: 'Salif Traoré',
    atelier: 'Salif Couture',
    plan: SubscriptionPlan.pro,
    requestedAt: DateTime(2026, 10, 28, 19, 5),
    status: PreviewRequestStatus.rejected,
    note: 'Compte en doublon —voir fiche support #482.',
  ),
];

final previewThreads = <PreviewThread>[
  PreviewThread(
    name: 'Aminata Traoré',
    atelier: 'Atelier Wax & Soie',
    role: 'Chef Styliste · Pro',
    lastMessage: 'Merci, le PDF fonctionne parfaitement maintenant.',
    time: '09:42',
    unread: 2,
    messages: [
      PreviewMessage(
        author: 'Aminata Traoré',
        text: 'Bonjour, depuis hier l\'export PDF de mes devis échoue. J\'ai essayé sur deux téléphones.',
        time: '09:31',
      ),
      PreviewMessage(
        author: 'Support StyleConnect',
        text: 'Bonjour Aminata. Le souci venait du modèle « Prestige » qui utilisait une police non embarquée. C\'est corrigé côté serveur.',
        time: '09:38',
        fromAdmin: true,
      ),
      PreviewMessage(
        author: 'Aminata Traoré',
        text: 'Je viens de tester, ça marche. Merci pour la réactivité !',
        time: '09:41',
      ),
      PreviewMessage(
        author: 'Aminata Traoré',
        text: 'Merci, le PDF fonctionne parfaitement maintenant.',
        time: '09:42',
      ),
    ],
  ),
  PreviewThread(
    name: 'Moussa Konaté',
    atelier: 'Konaté Frères',
    role: 'Chef d\'Entreprise · Entreprise',
    lastMessage: 'Puis-je rattacher un troisième atelier à mon offre ?',
    time: '08:15',
    unread: 1,
    flagged: true,
    messages: [
      PreviewMessage(
        author: 'Moussa Konaté',
        text: 'Bonjour, nous ouvrons un atelier à Kayes le mois prochain. Puis-je le rattacher à mon offre Entreprise ?',
        time: '08:15',
      ),
    ],
  ),
  PreviewThread(
    name: 'Ibrahim Keïta',
    atelier: 'Le Fil d\'Or',
    role: 'Chef Styliste · Starter',
    lastMessage: 'Ma demande de passage en Pro est-elle bien reçue ?',
    time: 'Hier',
    messages: [
      PreviewMessage(
        author: 'Ibrahim Keïta',
        text: 'Bonjour, j\'ai envoyé une demande de passage en Pro avant-hier. Est-elle bien reçue ?',
        time: 'Hier 16:20',
      ),
      PreviewMessage(
        author: 'Support StyleConnect',
        text: 'Bonjour Ibrahim, oui elle est en file de validation. Vous recevrez une notification dès qu\'elle est traitée.',
        time: 'Hier 16:34',
        fromAdmin: true,
      ),
      PreviewMessage(
        author: 'Ibrahim Keïta',
        text: 'Ma demande de passage en Pro est-elle bien reçue ?',
        time: 'Hier 16:35',
      ),
    ],
  ),
  PreviewThread(
    name: 'Seydou Bagayoko',
    atelier: 'Bagayoko & Frères',
    role: 'Chef Styliste · Découverte',
    lastMessage: 'Mon compte a été suspendu sans explication.',
    time: 'Hier',
    flagged: true,
    messages: [
      PreviewMessage(
        author: 'Seydou Bagayoko',
        text: 'Bonjour, je ne peux plus me connecter. Mon compte a été suspendu sans explication.',
        time: 'Hier 11:02',
      ),
    ],
  ),
  PreviewThread(
    name: 'Awa Cissé',
    atelier: 'Awa Couture Paris',
    role: 'Chef d\'Entreprise · Entreprise',
    lastMessage: 'Parfait, je valide la nouvelle grille tarifaire.',
    time: '28 oct.',
    messages: [
      PreviewMessage(
        author: 'Awa Cissé',
        text: 'Parfait, je valide la nouvelle grille tarifaire. Merci.',
        time: '28 oct. 18:40',
      ),
    ],
  ),
];

const revenueMonths = <String>[
  'Déc', 'Janv', 'Févr', 'Mars', 'Avr', 'Mai',
  'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov',
];

const revenueValues = <int>[
  620000, 705000, 690000, 810000, 860000, 925000,
  1010000, 980000, 1090000, 1155000, 1210000, 1250000,
];

const planSubscriberCounts = <SubscriptionPlan, int>{
  SubscriptionPlan.free: 54,
  SubscriptionPlan.starter: 31,
  SubscriptionPlan.pro: 28,
  SubscriptionPlan.enterprise: 15,
};
