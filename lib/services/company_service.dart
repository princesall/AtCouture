import '../models/app_user.dart';
import '../models/atelier.dart';
import '../models/client.dart';
import '../models/subscription_plan.dart';
import '../models/user_role.dart';

/// Service simulant la base de données hiérarchique Entreprise → Ateliers → Couturiers.
/// En mode démo (Firebase non connecté), tout vit en mémoire ici.
/// Quand Firebase sera branché, ces mêmes méthodes liront/écriront dans Firestore
/// en respectant EXACTEMENT la même hiérarchie (voir firestore.rules).
///
/// ARCHITECTURE : le Chef d'Entreprise (companyOwner) possède TOUS les
/// pouvoirs d'un Chef d'atelier classique, PLUS la gestion multi-ateliers.
/// Il peut donc continuer à travailler directement avec ses propres clients
/// (son "atelier personnel", créé automatiquement à l'activation du plan
/// Entreprise) sans être obligé de déléguer à un Chef d'atelier. C'est lui
/// qui crée les comptes des Chefs d'atelier ET des Couturiers.
class CompanyService {
  CompanyService._();
  static final CompanyService instance = CompanyService._();

  // ── Données démo en mémoire ──────────────────────────────────────────────
  final List<Company> _companies = [
    Company(
      id: 'company_1',
      name: 'Groupe Keïta Couture',
      ownerId: 'owner_1',
      ownerName: 'Moussa Keïta',
      atelierIds: ['atelier_owner_1', 'atelier_ent_1', 'atelier_ent_2', 'atelier_ent_3'],
      createdAt: DateTime(2026, 1, 5),
    ),
  ];

  final List<Atelier> _ateliers = [
    // ── Atelier PERSONNEL du Chef d'Entreprise lui-même ─────────────────────
    // Lui permet de continuer à avoir ses propres clients/commandes sans
    // passer par un Chef d'atelier intermédiaire.
    Atelier(
      id: 'atelier_owner_1',
      name: 'Keïta Prestige — Siège (Moussa Keïta)',
      headStylistId: 'owner_1',
      headStylistName: 'Moussa Keïta',
      companyId: 'owner_1',
      address: 'Hamdallaye ACI 2000, Bamako',
      tailorIds: ['tailor_ent_7'],
      clientCount: 15,
      activeOrderCount: 6,
      totalRevenue: 540000,
      createdAt: DateTime(2026, 1, 5),
    ),
    // ── Ateliers délégués à des Chefs d'atelier ─────────────────────────────
    Atelier(
      id: 'atelier_ent_1',
      name: 'Keïta Prestige — Bamako Centre',
      headStylistId: 'chef_atelier_1',
      headStylistName: 'Salif Touré',
      companyId: 'owner_1',
      address: 'ACI 2000, Bamako',
      tailorIds: ['tailor_ent_1', 'tailor_ent_2', 'tailor_ent_3'],
      clientCount: 48,
      activeOrderCount: 12,
      totalRevenue: 980000,
      createdAt: DateTime(2026, 1, 10),
    ),
    Atelier(
      id: 'atelier_ent_2',
      name: 'Keïta Prestige — Sogoniko',
      headStylistId: 'chef_atelier_2',
      headStylistName: 'Mariam Sissoko',
      companyId: 'owner_1',
      address: 'Sogoniko, Bamako',
      tailorIds: ['tailor_ent_4', 'tailor_ent_5'],
      clientCount: 31,
      activeOrderCount: 8,
      totalRevenue: 620000,
      createdAt: DateTime(2026, 2, 15),
    ),
    Atelier(
      id: 'atelier_ent_3',
      name: 'Keïta Prestige — Ségou',
      headStylistId: 'chef_atelier_3',
      headStylistName: 'Ousmane Diarra',
      companyId: 'owner_1',
      address: 'Centre-ville, Ségou',
      tailorIds: ['tailor_ent_6'],
      clientCount: 19,
      activeOrderCount: 5,
      totalRevenue: 340000,
      createdAt: DateTime(2026, 5, 1),
    ),

    // ── Atelier indépendant (styliste solo Pro) ────────────────────────────
    Atelier(
      id: 'atelier_1',
      name: 'Atelier Élégance Bamako',
      headStylistId: 'stylist_1',
      headStylistName: 'Aminata Diallo',
      companyId: null,
      tailorIds: ['tailor_1'],
      clientCount: 22,
      activeOrderCount: 14,
      totalRevenue: 345000,
      createdAt: DateTime(2026, 3, 15),
    ),
  ];

  /// Comptes "Chef d'atelier" créés par le Chef d'Entreprise — visibles
  /// uniquement dans la hiérarchie de leur companyId.
  final List<AppUser> _atelierHeads = [
    AppUser(
      id: 'chef_atelier_1',
      email: 'salif.toure@keitaprestige.ml',
      fullName: 'Salif Touré',
      phone: '+223 76 11 22 33',
      role: UserRole.stylist,
      atelierId: 'atelier_ent_1',
      atelierName: 'Keïta Prestige — Bamako Centre',
      companyId: 'owner_1',
      plan: SubscriptionPlan.enterprise,
      createdAt: DateTime(2026, 1, 10),
    ),
    AppUser(
      id: 'chef_atelier_2',
      email: 'mariam.sissoko@keitaprestige.ml',
      fullName: 'Mariam Sissoko',
      phone: '+223 65 44 55 66',
      role: UserRole.stylist,
      atelierId: 'atelier_ent_2',
      atelierName: 'Keïta Prestige — Sogoniko',
      companyId: 'owner_1',
      plan: SubscriptionPlan.enterprise,
      createdAt: DateTime(2026, 2, 15),
    ),
    AppUser(
      id: 'chef_atelier_3',
      email: 'ousmane.diarra@keitaprestige.ml',
      fullName: 'Ousmane Diarra',
      phone: '+223 79 77 88 99',
      role: UserRole.stylist,
      atelierId: 'atelier_ent_3',
      atelierName: 'Keïta Prestige — Ségou',
      companyId: 'owner_1',
      plan: SubscriptionPlan.enterprise,
      createdAt: DateTime(2026, 5, 1),
    ),
  ];

  /// Comptes "Couturier" créés par un Chef (d'atelier ou d'Entreprise),
  /// rattachés à un atelier précis via atelierId.
  final List<AppUser> _tailors = [
    AppUser(id: 'tailor_ent_1', email: 'boubacar.sangare@keitaprestige.ml', fullName: 'Boubacar Sangaré', phone: '+223 76 11 11 11', role: UserRole.tailor, atelierId: 'atelier_ent_1', atelierName: 'Keïta Prestige — Bamako Centre', createdAt: DateTime(2026, 1, 12)),
    AppUser(id: 'tailor_ent_2', email: 'awa.traore@keitaprestige.ml',      fullName: 'Awa Traoré',       phone: '+223 76 22 22 22', role: UserRole.tailor, atelierId: 'atelier_ent_1', atelierName: 'Keïta Prestige — Bamako Centre', createdAt: DateTime(2026, 1, 15)),
    AppUser(id: 'tailor_ent_3', email: 'daouda.konate@keitaprestige.ml',   fullName: 'Daouda Konaté',    phone: '+223 76 33 33 33', role: UserRole.tailor, atelierId: 'atelier_ent_1', atelierName: 'Keïta Prestige — Bamako Centre', createdAt: DateTime(2026, 2, 1)),
    AppUser(id: 'tailor_ent_4', email: 'hawa.camara@keitaprestige.ml',     fullName: 'Hawa Camara',      phone: '+223 65 44 44 44', role: UserRole.tailor, atelierId: 'atelier_ent_2', atelierName: 'Keïta Prestige — Sogoniko',       createdAt: DateTime(2026, 2, 20)),
    AppUser(id: 'tailor_ent_5', email: 'yacouba.diabate@keitaprestige.ml', fullName: 'Yacouba Diabaté',  phone: '+223 65 55 55 55', role: UserRole.tailor, atelierId: 'atelier_ent_2', atelierName: 'Keïta Prestige — Sogoniko',       createdAt: DateTime(2026, 3, 10)),
    AppUser(id: 'tailor_ent_6', email: 'koro.coulibaly@keitaprestige.ml',  fullName: 'Korotoumou Coulibaly', phone: '+223 79 66 66 66', role: UserRole.tailor, atelierId: 'atelier_ent_3', atelierName: 'Keïta Prestige — Ségou', createdAt: DateTime(2026, 5, 5)),
    AppUser(id: 'tailor_ent_7', email: 'youssouf.kante@keitaprestige.ml',  fullName: 'Youssouf Kanté',   phone: '+223 77 12 34 56', role: UserRole.tailor, atelierId: 'atelier_owner_1', atelierName: 'Keïta Prestige — Siège', createdAt: DateTime(2026, 1, 6)),
  ];

  /// Données clients démo par atelier — incluant l'atelier personnel du Chef
  final List<Client> _clients = [
    // Atelier personnel du Chef d'Entreprise
    Client(id: 'cli_o1', fullName: 'Aminata Sidibé',  phone: '+223 70 10 10 10', atelierId: 'atelier_owner_1', atelierName: 'Keïta Prestige — Siège', orderCount: 3, totalSpent: 145000, createdAt: DateTime(2026, 1, 20)),
    Client(id: 'cli_o2', fullName: 'Ibrahim Kouyaté', phone: '+223 70 20 20 20', atelierId: 'atelier_owner_1', atelierName: 'Keïta Prestige — Siège', orderCount: 2, totalSpent: 98000,  createdAt: DateTime(2026, 2, 5)),
    // Atelier Bamako Centre
    Client(id: 'cli_b1', fullName: 'Mariam Touré',    phone: '+223 76 30 30 30', atelierId: 'atelier_ent_1', atelierName: 'Keïta Prestige — Bamako Centre', orderCount: 5, totalSpent: 310000, createdAt: DateTime(2026, 1, 25)),
    Client(id: 'cli_b2', fullName: 'Seydou Camara',   phone: '+223 76 40 40 40', atelierId: 'atelier_ent_1', atelierName: 'Keïta Prestige — Bamako Centre', orderCount: 2, totalSpent: 120000, createdAt: DateTime(2026, 2, 10)),
    Client(id: 'cli_b3', fullName: 'Fatoumata Bah',   phone: '+223 76 50 50 50', atelierId: 'atelier_ent_1', atelierName: 'Keïta Prestige — Bamako Centre', orderCount: 4, totalSpent: 220000, createdAt: DateTime(2026, 3, 1)),
    // Atelier Sogoniko
    Client(id: 'cli_s1', fullName: 'Aminata Koné',    phone: '+223 65 60 60 60', atelierId: 'atelier_ent_2', atelierName: 'Keïta Prestige — Sogoniko', orderCount: 3, totalSpent: 175000, createdAt: DateTime(2026, 2, 28)),
    Client(id: 'cli_s2', fullName: 'Modibo Sangaré',  phone: '+223 65 70 70 70', atelierId: 'atelier_ent_2', atelierName: 'Keïta Prestige — Sogoniko', orderCount: 1, totalSpent: 95000,  createdAt: DateTime(2026, 4, 3)),
    // Atelier Ségou
    Client(id: 'cli_sg1', fullName: 'Fanta Diarra',   phone: '+223 79 80 80 80', atelierId: 'atelier_ent_3', atelierName: 'Keïta Prestige — Ségou', orderCount: 2, totalSpent: 110000, createdAt: DateTime(2026, 5, 10)),
  ];

  /// Commandes démo consolidées (tous ateliers)
  final List<CompanyOrder> _orders = [
    CompanyOrder(id: 'ord_1', clientName: 'Mariam Touré',    garment: 'Boubou Brodé Or',       price: 85000,  status: 'inProgress', atelierId: 'atelier_ent_1',   atelierName: 'Bamako Centre',  tailorName: 'Boubacar Sangaré', date: DateTime(2026, 6, 20)),
    CompanyOrder(id: 'ord_2', clientName: 'Seydou Camara',   garment: 'Costume Cérémonie',     price: 120000, status: 'pending',    atelierId: 'atelier_ent_1',   atelierName: 'Bamako Centre',  tailorName: 'Awa Traoré',       date: DateTime(2026, 6, 22)),
    CompanyOrder(id: 'ord_3', clientName: 'Aminata Koné',    garment: 'Robe Wax Moderne',      price: 55000,  status: 'done',       atelierId: 'atelier_ent_2',   atelierName: 'Sogoniko',       tailorName: 'Hawa Camara',      date: DateTime(2026, 6, 18)),
    CompanyOrder(id: 'ord_4', clientName: 'Modibo Sangaré',  garment: 'Grand Boubou',          price: 95000,  status: 'problem',    atelierId: 'atelier_ent_2',   atelierName: 'Sogoniko',       tailorName: 'Yacouba Diabaté',  date: DateTime(2026, 6, 15)),
    CompanyOrder(id: 'ord_5', clientName: 'Fanta Diarra',    garment: 'Ensemble Bazin',        price: 60000,  status: 'inProgress', atelierId: 'atelier_ent_3',   atelierName: 'Ségou',          tailorName: 'Korotoumou Coulibaly', date: DateTime(2026, 6, 21)),
    CompanyOrder(id: 'ord_6', clientName: 'Aminata Sidibé',  garment: 'Robe de Soirée Or',     price: 75000,  status: 'done',       atelierId: 'atelier_owner_1', atelierName: 'Siège (Moussa)', tailorName: 'Youssouf Kanté',   date: DateTime(2026, 6, 19)),
    CompanyOrder(id: 'ord_7', clientName: 'Ibrahim Kouyaté', garment: 'Complet Wax 3 pièces',  price: 70000,  status: 'inProgress', atelierId: 'atelier_owner_1', atelierName: 'Siège (Moussa)', tailorName: 'Youssouf Kanté',   date: DateTime(2026, 6, 25)),
    CompanyOrder(id: 'ord_8', clientName: 'Fatoumata Bah',   garment: 'Boubou Dentelle',       price: 90000,  status: 'pending',    atelierId: 'atelier_ent_1',   atelierName: 'Bamako Centre',  tailorName: 'Daouda Konaté',    date: DateTime(2026, 6, 26)),
  ];

  // ── Compteurs pour génération d'IDs démo ─────────────────────────────────
  int _idCounter = 9000;
  String _nextId(String prefix) => '${prefix}_${_idCounter++}';

  /// Pour l'Admin : liste de TOUTES les Entreprises de la plateforme
  List<Company> get allCompanies => List.unmodifiable(_companies);

  /// Pour l'Admin : liste de TOUS les ateliers de la plateforme
  List<Atelier> get allAteliers => List.unmodifiable(_ateliers);

  // ── Lectures ──────────────────────────────────────────────────────────────

  /// Récupère l'Entreprise dont l'owner est `ownerId`, ou null si compte solo.
  Company? companyForOwner(String ownerId) =>
      _companies.where((c) => c.ownerId == ownerId).firstOrNull;

  /// Tous les ateliers d'une Entreprise (vue consolidée du Chef d'Entreprise),
  /// y compris son propre atelier personnel.
  List<Atelier> ateliersOfCompany(String companyId) =>
      _ateliers.where((a) => a.companyId == companyId).toList();

  /// L'atelier géré par un Chef Styliste précis (vue d'un seul atelier)
  Atelier? atelierOfStylist(String stylistId) =>
      _ateliers.where((a) => a.headStylistId == stylistId).firstOrNull;

  /// Tous les Chefs d'atelier d'une Entreprise donnée (hors le owner lui-même)
  List<AppUser> atelierHeadsOfCompany(String companyId) =>
      _atelierHeads.where((u) => u.companyId == companyId).toList();

  /// Tous les couturiers rattachés à un atelier
  List<AppUser> tailorsOfAtelier(String atelierId) =>
      _tailors.where((t) => t.atelierId == atelierId).toList();

  /// Tous les couturiers de TOUS les ateliers d'une Entreprise (vue globale)
  List<AppUser> allTailorsOfCompany(String companyId) {
    final atelierIds = ateliersOfCompany(companyId).map((a) => a.id).toSet();
    return _tailors.where((t) => atelierIds.contains(t.atelierId)).toList();
  }

  /// TOUS les clients de TOUS les ateliers de l'Entreprise
  List<Client> allClientsOfCompany(String companyId) {
    final atelierIds = ateliersOfCompany(companyId).map((a) => a.id).toSet();
    return _clients.where((c) => atelierIds.contains(c.atelierId)).toList();
  }

  /// Clients d'un atelier précis uniquement
  List<Client> clientsOfAtelier(String atelierId) =>
      _clients.where((c) => c.atelierId == atelierId).toList();

  /// TOUTES les commandes de TOUS les ateliers de l'Entreprise
  List<CompanyOrder> allOrdersOfCompany(String companyId) {
    final atelierIds = ateliersOfCompany(companyId).map((a) => a.id).toSet();
    return _orders.where((o) => atelierIds.contains(o.atelierId)).toList();
  }

  /// Commandes d'un atelier précis uniquement
  List<CompanyOrder> ordersOfAtelier(String atelierId) =>
      _orders.where((o) => o.atelierId == atelierId).toList();

  /// KPIs consolidés de toute l'Entreprise (réels, depuis les données)
  ({int totalAteliers, int totalTailors, int totalClients, int totalOrders, int totalRevenue})
      companyStats(String companyId) {
    final atelierIds = ateliersOfCompany(companyId).map((a) => a.id).toSet();
    final clients = _clients.where((c) => atelierIds.contains(c.atelierId)).toList();
    final orders = _orders.where((o) => atelierIds.contains(o.atelierId)).toList();
    final tailors = _tailors.where((t) => atelierIds.contains(t.atelierId)).toList();
    return (
      totalAteliers: atelierIds.length,
      totalTailors: tailors.length,
      totalClients: clients.length,
      totalOrders: orders.length,
      totalRevenue: orders.fold(0, (sum, o) => sum + o.price),
    );
  }


  // ── Écritures (démo, persistent en mémoire le temps de la session) ──────

  /// Crée automatiquement la structure Company + l'atelier personnel du
  /// propriétaire quand son compte passe au plan Entreprise (appelé par
  /// SubscriptionService.approveSubscriptionRequest). Le Chef d'Entreprise
  /// garde ainsi IMMÉDIATEMENT un atelier à son nom pour ses propres clients.
  Company createCompanyForNewOwner({
    required String ownerId,
    required String ownerName,
  }) {
    final existing = companyForOwner(ownerId);
    if (existing != null) return existing;

    final now = DateTime.now();
    final personalAtelierId = _nextId('atelier_owner');

    final personalAtelier = Atelier(
      id: personalAtelierId,
      name: '$ownerName — Atelier Principal',
      headStylistId: ownerId,
      headStylistName: ownerName,
      companyId: ownerId,
      createdAt: now,
    );
    _ateliers.add(personalAtelier);

    final company = Company(
      id: _nextId('company'),
      name: '$ownerName & Associés',
      ownerId: ownerId,
      ownerName: ownerName,
      atelierIds: [personalAtelierId],
      createdAt: now,
    );
    _companies.add(company);
    return company;
  }

  /// Crée un nouveau Chef d'atelier + son Atelier, rattachés à l'Entreprise.
  /// Réservé au Chef d'Entreprise (vérifié côté UI ET règles serveur).
  AppUser createAtelierHead({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required String atelierName,
    String? address,
  }) {
    final now = DateTime.now();
    final atelierId = _nextId('atelier');
    final headId = _nextId('chef_atelier');

    final newAtelier = Atelier(
      id: atelierId,
      name: atelierName,
      headStylistId: headId,
      headStylistName: fullName,
      companyId: companyId,
      address: address,
      createdAt: now,
    );

    final newHead = AppUser(
      id: headId,
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: UserRole.stylist,
      atelierId: atelierId,
      atelierName: atelierName,
      companyId: companyId,
      plan: SubscriptionPlan.enterprise,
      createdAt: now,
    );

    _ateliers.add(newAtelier);
    _atelierHeads.add(newHead);

    final companyIndex = _companies.indexWhere((c) => c.ownerId == companyId);
    if (companyIndex != -1) {
      final company = _companies[companyIndex];
      _companies[companyIndex] = company.copyWith(
        atelierIds: [...company.atelierIds, atelierId],
      );
    }

    return newHead;
  }

  /// Crée un nouveau Couturier rattaché à un atelier précis. Peut être
  /// appelé par : le Chef d'atelier (pour son propre atelier), ou le Chef
  /// d'Entreprise (pour n'importe quel atelier de son Entreprise, y compris
  /// le sien propre).
  AppUser createTailor({
    required String atelierId,
    required String atelierName,
    required String fullName,
    required String email,
    required String phone,
  }) {
    final now = DateTime.now();
    final tailorId = _nextId('tailor');

    final newTailor = AppUser(
      id: tailorId,
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: UserRole.tailor,
      atelierId: atelierId,
      atelierName: atelierName,
      createdAt: now,
    );

    _tailors.add(newTailor);

    final atelierIndex = _ateliers.indexWhere((a) => a.id == atelierId);
    if (atelierIndex != -1) {
      final atelier = _ateliers[atelierIndex];
      _ateliers[atelierIndex] = atelier.copyWith(
        tailorIds: [...atelier.tailorIds, tailorId],
      );
    }

    return newTailor;
  }

  void removeAtelierHead(String headId) {
    final head = _atelierHeads.where((u) => u.id == headId).firstOrNull;
    if (head == null) return;
    _atelierHeads.removeWhere((u) => u.id == headId);
    _ateliers.removeWhere((a) => a.headStylistId == headId);
  }

  void removeTailor(String tailorId) {
    final tailor = _tailors.where((t) => t.id == tailorId).firstOrNull;
    if (tailor == null) return;
    _tailors.removeWhere((t) => t.id == tailorId);
    final atelierIndex = _ateliers.indexWhere((a) => a.id == tailor.atelierId);
    if (atelierIndex != -1) {
      final atelier = _ateliers[atelierIndex];
      _ateliers[atelierIndex] = atelier.copyWith(
        tailorIds: atelier.tailorIds.where((id) => id != tailorId).toList(),
      );
    }
  }

  /// Recherche un compte (Chef d'atelier OU Couturier) par email, pour le
  /// flux de connexion unique — voir AuthService.signIn.
  AppUser? findAccountByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final inHeads = _atelierHeads.where((u) => u.email.toLowerCase() == normalized).firstOrNull;
    if (inHeads != null) return inHeads;
    return _tailors.where((u) => u.email.toLowerCase() == normalized).firstOrNull;
  }

  /// Ajoute un client à un atelier
  Client addClient({
    required String atelierId,
    required String atelierName,
    required String fullName,
    required String phone,
    String? email,
    String? notes,
  }) {
    final client = Client(
      id: _nextId('cli'),
      fullName: fullName.trim(),
      phone: phone.trim(),
      atelierId: atelierId,
      atelierName: atelierName,
      email: email?.trim(),
      notes: notes,
      createdAt: DateTime.now(),
    );
    _clients.add(client);
    return client;
  }
}

// ── Modèle commande interne à CompanyService ─────────────────────────────────
class CompanyOrder {
  const CompanyOrder({
    required this.id,
    required this.clientName,
    required this.garment,
    required this.price,
    required this.status,
    required this.atelierId,
    required this.atelierName,
    required this.tailorName,
    required this.date,
  });
  final String id;
  final String clientName;
  final String garment;
  final int price;
  final String status; // 'pending' | 'inProgress' | 'done' | 'problem'
  final String atelierId;
  final String atelierName;
  final String tailorName;
  final DateTime date;
}
