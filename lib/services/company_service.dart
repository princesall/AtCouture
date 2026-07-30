import '../models/app_user.dart';
import '../models/atelier.dart';
import '../models/client.dart';
import '../models/order.dart';
import '../models/subscription_plan.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'order_service.dart';

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
  final List<Company> _companies = [];

  final List<Atelier> _ateliers = [];

  /// Comptes "Chef d'atelier" créés par le Chef d'Entreprise — visibles
  /// uniquement dans la hiérarchie de leur companyId.
  final List<AppUser> _atelierHeads = [];

  /// Comptes "Couturier" créés par un Chef (d'atelier ou d'Entreprise),
  /// rattachés à un atelier précis via atelierId.
  final List<AppUser> _tailors = [];

  // NOTE : les clients et commandes ne sont PAS stockés ici. OrderService est
  // l'UNIQUE source de vérité pour Client/Order (utilisée aussi bien par
  // l'espace Styliste solo que par l'espace Entreprise) — voir clientsOfAtelier/
  // ordersOfAtelier ci-dessous. Ça évite que les données d'un atelier
  // deviennent invisibles quand son compte passe du plan solo au plan
  // Entreprise (l'atelier personnel créé à cette occasion réutilise le MÊME
  // atelierId, voir createCompanyForNewOwner).

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
    final atelierIds = ateliersOfCompany(companyId).map((a) => a.id);
    return atelierIds.expand(OrderService.instance.clientsOfAtelier).toList();
  }

  /// Clients d'un atelier précis uniquement
  List<Client> clientsOfAtelier(String atelierId) =>
      OrderService.instance.clientsOfAtelier(atelierId);

  /// TOUTES les commandes de TOUS les ateliers de l'Entreprise
  List<Order> allOrdersOfCompany(String companyId) {
    final atelierIds = ateliersOfCompany(companyId).map((a) => a.id);
    return atelierIds.expand(OrderService.instance.ordersOfAtelier).toList();
  }

  /// Commandes d'un atelier précis uniquement
  List<Order> ordersOfAtelier(String atelierId) =>
      OrderService.instance.ordersOfAtelier(atelierId);

  /// KPIs consolidés de toute l'Entreprise (réels, depuis les données)
  ({int totalAteliers, int totalTailors, int totalClients, int totalOrders, int totalRevenue})
      companyStats(String companyId) {
    final atelierIds = ateliersOfCompany(companyId).map((a) => a.id).toSet();
    final tailors = _tailors.where((t) => atelierIds.contains(t.atelierId));
    final totalClients = atelierIds.fold<int>(
        0, (sum, id) => sum + OrderService.instance.clientsOfAtelier(id).length);
    final totalOrders = atelierIds.fold<int>(
        0, (sum, id) => sum + OrderService.instance.ordersOfAtelier(id).length);
    final totalRevenue = atelierIds.fold<int>(
        0, (sum, id) => sum + OrderService.instance.atelierRevenue(id));
    return (
      totalAteliers: atelierIds.length,
      totalTailors: tailors.length,
      totalClients: totalClients,
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
    );
  }


  // ── Écritures (démo, persistent en mémoire le temps de la session) ──────

  /// Crée automatiquement la structure Company + l'atelier personnel du
  /// propriétaire quand son compte passe au plan Entreprise (appelé par
  /// SubscriptionService.approveSubscriptionRequest). Le Chef d'Entreprise
  /// garde ainsi IMMÉDIATEMENT un atelier à son nom pour ses propres clients.
  ///
  /// IMPORTANT : `personalAtelierId`/`personalAtelierName` doivent être
  /// l'atelierId/atelierName QUE LE COMPTE UTILISAIT DÉJÀ avant de passer au
  /// plan Entreprise (celui rattaché à son AppUser.atelierId). On réutilise
  /// volontairement le MÊME id plutôt que d'en générer un nouveau : sinon les
  /// clients/commandes déjà créés par ce compte (via OrderService, indexés
  /// par cet atelierId) deviendraient invisibles dans le nouveau dashboard
  /// Entreprise.
  Future<Company> createCompanyForNewOwner({
    required String ownerId,
    required String ownerName,
    required String personalAtelierId,
    required String personalAtelierName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final existing = companyForOwner(ownerId);
    if (existing != null) return existing;

    final now = DateTime.now();

    final personalAtelier = Atelier(
      id: personalAtelierId,
      name: personalAtelierName,
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
  Future<({AppUser user, String temporaryPassword})> createAtelierHead({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required String atelierName,
    String? address,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

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

    final temporaryPassword = AuthService.generateTemporaryPassword(newHead.email);
    return (user: newHead, temporaryPassword: temporaryPassword);
  }

  /// Crée un nouveau Couturier rattaché à un atelier précis. Peut être
  /// appelé par : le Chef d'atelier (pour son propre atelier), ou le Chef
  /// d'Entreprise (pour n'importe quel atelier de son Entreprise, y compris
  /// le sien propre).
  Future<({AppUser user, String temporaryPassword})> createTailor({
    required String atelierId,
    required String atelierName,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

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

    final temporaryPassword = AuthService.generateTemporaryPassword(newTailor.email);
    return (user: newTailor, temporaryPassword: temporaryPassword);
  }

  Future<void> removeAtelierHead(String headId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final head = _atelierHeads.where((u) => u.id == headId).firstOrNull;
    if (head == null) return;
    _atelierHeads.removeWhere((u) => u.id == headId);
    _ateliers.removeWhere((a) => a.headStylistId == headId);
  }

  Future<void> removeTailor(String tailorId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

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

  /// Met à jour les informations d'un couturier existant
  Future<void> updateTailor({
    required String tailorId,
    required String fullName,
    required String phone,
    String? email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _tailors.indexWhere((t) => t.id == tailorId);
    if (index == -1) return;

    final tailor = _tailors[index];
    final updatedTailor = tailor.copyWith(
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email?.trim(),
    );
    
    _tailors[index] = updatedTailor;
  }

  /// Recherche un compte (Chef d'atelier OU Couturier) par email, pour le
  /// flux de connexion unique — voir AuthService.signIn.
  AppUser? findAccountByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final inHeads = _atelierHeads.where((u) => u.email.toLowerCase() == normalized).firstOrNull;
    if (inHeads != null) return inHeads;
    return _tailors.where((u) => u.email.toLowerCase() == normalized).firstOrNull;
  }

  /// Met à jour un utilisateur existant dans _atelierHeads ou _tailors (utilisé par AdminDemoData)
  void updateUser(AppUser updatedUser) {
    final headsIndex = _atelierHeads.indexWhere((u) => u.id == updatedUser.id);
    if (headsIndex != -1) {
      _atelierHeads[headsIndex] = updatedUser;
      return;
    }

    final tailorsIndex = _tailors.indexWhere((u) => u.id == updatedUser.id);
    if (tailorsIndex != -1) {
      _tailors[tailorsIndex] = updatedUser;
    }
  }

  /// Le nom du couturier assigné à une commande, ou null si aucun/non trouvé.
  String? tailorNameForOrder(Order order) {
    if (order.tailorId == null) return null;
    return _tailors.where((t) => t.id == order.tailorId).firstOrNull?.fullName;
  }

  /// Ajoute un client à un atelier
  Future<Client> addClient({
    required String atelierId,
    required String atelierName,
    required String fullName,
    required String phone,
    String? email,
    String? notes,
  }) =>
      OrderService.instance.addClient(
        atelierId: atelierId,
        atelierName: atelierName,
        fullName: fullName,
        phone: phone,
        email: email,
        notes: notes,
      );
}
