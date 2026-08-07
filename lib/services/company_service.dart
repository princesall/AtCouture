import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/atelier.dart';
import '../models/client.dart';
import '../models/order.dart';
import '../models/subscription_plan.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'firebase_service.dart';
import 'order_service.dart';

/// Service de la hiérarchie Entreprise → Ateliers → Couturiers.
/// En mode démo (Firebase non connecté), tout vit en mémoire ici. En mode
/// Firebase, les mêmes listes deviennent un CACHE tenu à jour par des
/// écoutes Firestore déclenchées à la demande (voir _ensureCompanySynced/
/// _ensureAtelierTailorsSynced) — les mêmes getters synchrones continuent de
/// fonctionner sans changement de signature pour les écrans appelants.
///
/// ARCHITECTURE : le Chef d'Entreprise (companyOwner) possède TOUS les
/// pouvoirs d'un Chef d'atelier classique, PLUS la gestion multi-ateliers.
/// Il peut donc continuer à travailler directement avec ses propres clients
/// (son "atelier personnel", créé automatiquement à l'activation du plan
/// Entreprise) sans être obligé de déléguer à un Chef d'atelier. C'est lui
/// qui crée les comptes des Chefs d'atelier ET des Couturiers.
class CompanyService extends ChangeNotifier {
  CompanyService._();
  static final CompanyService instance = CompanyService._();

  // ── Données en mémoire (source de vérité démo, cache en mode Firestore) ──
  final List<Company> _companies = [];

  final List<Atelier> _ateliers = [];

  /// Comptes "Chef d'atelier" créés par le Chef d'Entreprise — visibles
  /// uniquement dans la hiérarchie de leur companyId.
  final List<AppUser> _atelierHeads = [];

  /// Comptes "Couturier" créés par un Chef (d'atelier ou d'Entreprise),
  /// rattachés à un atelier précis via atelierId.
  final List<AppUser> _tailors = [];

  // ── Idempotence (voir OrderService pour le principe) — sans ça, rejouer
  // createAtelierHead/createTailor créait un compte fantôme en double avec
  // un mot de passe temporaire différent à chaque appel, aucune vérification
  // d'unicité n'existant ici (contrairement à AuthService.registerStylist).
  final Map<String, ({AppUser user, String temporaryPassword})> _atelierHeadIdempotencyCache = {};
  final Map<String, ({AppUser user, String temporaryPassword})> _tailorIdempotencyCache = {};

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

  // ── Synchronisation Firestore (mode réel uniquement) ─────────────────────
  // Une entreprise n'est écoutée qu'une fois, déclenché par la première
  // lecture demandée pour elle (ateliersOfCompany/allOrdersOfCompany/...).
  // Dès que la liste des ateliers d'une entreprise arrive, on enchaîne
  // automatiquement la synchronisation des couturiers de CHACUN de ses
  // ateliers (cascade auto-cicatrisante : peu importe l'ordre d'arrivée
  // des snapshots).
  final Set<String> _syncedCompanies = {};
  final Set<String> _syncedAtelierTailors = {};
  bool _allCompaniesSynced = false;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptions = [];

  /// Écoute TOUTE la collection `companies` — nécessaire pour l'admin
  /// (allCompanies), qui doit voir toutes les Entreprises de la plateforme
  /// et pas seulement celle d'un companyId précis (contrairement à
  /// _ensureCompanySynced, ciblé sur une seule entreprise pour l'espace
  /// Chef d'Entreprise). Sans cette écoute, `allCompanies` restait toujours
  /// vide en mode Firebase : rien ne remplissait jamais `_companies`.
  void _ensureAllCompaniesSynced() {
    if (!FirebaseService.isAvailable) return;
    if (_allCompaniesSynced) return;
    _allCompaniesSynced = true;

    _subscriptions.add(
      FirebaseFirestore.instance.collection('companies').snapshots().listen((snap) {
        _companies
          ..clear()
          ..addAll(snap.docs.map((d) => Company.fromMap(d.data(), d.id)));
        notifyListeners();
      }),
    );
  }

  void _ensureCompanySynced(String companyId) {
    if (!FirebaseService.isAvailable) return;
    if (!_syncedCompanies.add(companyId)) return;

    final firestore = FirebaseFirestore.instance;
    _subscriptions.add(
      firestore.collection('ateliers').where('companyId', isEqualTo: companyId).snapshots().listen((snap) {
        _ateliers.removeWhere((a) => a.companyId == companyId);
        final ateliers = snap.docs.map((d) => Atelier.fromMap(d.data(), d.id)).toList();
        _ateliers.addAll(ateliers);
        for (final atelier in ateliers) {
          _ensureAtelierTailorsSynced(atelier.id);
        }
        notifyListeners();
      }),
    );
    _subscriptions.add(
      firestore
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: 'stylist')
          .snapshots()
          .listen((snap) {
        _atelierHeads.removeWhere((u) => u.companyId == companyId);
        _atelierHeads.addAll(snap.docs.map((d) => AppUser.fromMap(d.data(), d.id)));
        notifyListeners();
      }),
    );
  }

  void _ensureAtelierTailorsSynced(String atelierId) {
    if (!FirebaseService.isAvailable) return;
    if (!_syncedAtelierTailors.add(atelierId)) return;

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('users')
          .where('atelierId', isEqualTo: atelierId)
          .where('role', isEqualTo: 'tailor')
          .snapshots()
          .listen((snap) {
        _tailors.removeWhere((t) => t.atelierId == atelierId);
        _tailors.addAll(snap.docs.map((d) => AppUser.fromMap(d.data(), d.id)));
        notifyListeners();
      }),
    );
  }

  /// Pour l'Admin : liste de TOUTES les Entreprises de la plateforme
  List<Company> get allCompanies {
    _ensureAllCompaniesSynced();
    return List.unmodifiable(_companies);
  }

  /// Pour l'Admin : liste de TOUS les ateliers de la plateforme
  List<Atelier> get allAteliers => List.unmodifiable(_ateliers);

  // ── Lectures ──────────────────────────────────────────────────────────────

  /// Récupère l'Entreprise dont l'owner est `ownerId`, ou null si compte solo.
  Company? companyForOwner(String ownerId) =>
      _companies.where((c) => c.ownerId == ownerId).firstOrNull;

  /// Tous les ateliers d'une Entreprise (vue consolidée du Chef d'Entreprise),
  /// y compris son propre atelier personnel.
  List<Atelier> ateliersOfCompany(String companyId) {
    _ensureCompanySynced(companyId);
    return _ateliers.where((a) => a.companyId == companyId).toList();
  }

  /// L'atelier géré par un Chef Styliste précis (vue d'un seul atelier).
  /// Suppose que la synchronisation a déjà été déclenchée par ailleurs (ex:
  /// ateliersOfCompany) — non appelé directement par l'UI aujourd'hui.
  Atelier? atelierOfStylist(String stylistId) =>
      _ateliers.where((a) => a.headStylistId == stylistId).firstOrNull;

  /// Lecture ponctuelle (pas d'écoute live) d'UN atelier par son ID — utilisé
  /// par un Couturier pour retrouver le nom/téléphone de son propre Chef
  /// d'atelier (voir TailorShell._TailorProfile), un cas d'usage qui ne
  /// justifie pas d'ouvrir un abonnement Firestore permanent comme les autres
  /// méthodes de ce service. Un couturier peut lire ce document précis (voir
  /// firestore.rules : uid() in tailorIds).
  Future<Atelier?> fetchAtelier(String atelierId) async {
    if (!FirebaseService.isAvailable) {
      return _ateliers.where((a) => a.id == atelierId).firstOrNull;
    }
    final doc = await FirebaseFirestore.instance.collection('ateliers').doc(atelierId).get();
    if (!doc.exists) return null;
    return Atelier.fromMap(doc.data()!, doc.id);
  }

  /// Tous les Chefs d'atelier d'une Entreprise donnée (hors le owner lui-même)
  List<AppUser> atelierHeadsOfCompany(String companyId) {
    _ensureCompanySynced(companyId);
    return _atelierHeads.where((u) => u.companyId == companyId).toList();
  }

  /// Tous les couturiers rattachés à un atelier
  List<AppUser> tailorsOfAtelier(String atelierId) {
    _ensureAtelierTailorsSynced(atelierId);
    return _tailors.where((t) => t.atelierId == atelierId).toList();
  }

  /// Tous les couturiers de TOUS les ateliers d'une Entreprise (vue globale)
  List<AppUser> allTailorsOfCompany(String companyId) {
    final atelierIds = ateliersOfCompany(companyId).map((a) => a.id).toSet();
    for (final id in atelierIds) {
      _ensureAtelierTailorsSynced(id);
    }
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
    for (final id in atelierIds) {
      _ensureAtelierTailorsSynced(id);
    }
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

  // ── Création de comptes Firebase Auth pour un tiers ──────────────────────
  // Un Chef d'Entreprise/d'atelier crée des comptes pour d'autres personnes
  // (Chef d'atelier, Couturier) sans jamais perdre sa propre session — on
  // passe par une DEUXIÈME instance FirebaseApp temporaire, jetée aussitôt
  // après. Sans Cloud Functions (Admin SDK), c'est la seule façon sûre de
  // créer un compte Firebase Auth pour quelqu'un d'autre depuis le client.
  Future<fb_auth.User> _createSecondaryAuthUser(String email, String password) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = fb_auth.FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(email: email, password: password);
      await secondaryAuth.signOut();
      return credential.user!;
    } finally {
      await secondaryApp.delete();
    }
  }

  // ── Écritures ─────────────────────────────────────────────────────────────

  /// Crée automatiquement la structure Company + l'atelier personnel du
  /// propriétaire quand son compte passe au plan Entreprise (appelé par
  /// SubscriptionService.approveSubscriptionRequest, donc par l'ADMIN — pas
  /// par le propriétaire lui-même). Le Chef d'Entreprise garde ainsi
  /// IMMÉDIATEMENT un atelier à son nom pour ses propres clients.
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
    if (FirebaseService.isAvailable) {
      return _createCompanyForNewOwnerFirebase(
        ownerId: ownerId,
        ownerName: ownerName,
        personalAtelierId: personalAtelierId,
        personalAtelierName: personalAtelierName,
      );
    }

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

  Future<Company> _createCompanyForNewOwnerFirebase({
    required String ownerId,
    required String ownerName,
    required String personalAtelierId,
    required String personalAtelierName,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final existingSnap =
        await firestore.collection('companies').where('ownerId', isEqualTo: ownerId).limit(1).get();
    if (existingSnap.docs.isNotEmpty) {
      final doc = existingSnap.docs.first;
      return Company.fromMap(doc.data(), doc.id);
    }

    final companyRef = firestore.collection('companies').doc();
    final company = Company(
      id: companyRef.id,
      name: '$ownerName & Associés',
      ownerId: ownerId,
      ownerName: ownerName,
      atelierIds: [personalAtelierId],
      createdAt: DateTime.now(),
    );

    final batch = firestore.batch();
    batch.set(companyRef, company.toMap());
    batch.update(firestore.collection('ateliers').doc(personalAtelierId), {'companyId': ownerId});
    await batch.commit();

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
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && _atelierHeadIdempotencyCache.containsKey(idempotencyKey)) {
      return _atelierHeadIdempotencyCache[idempotencyKey]!;
    }

    final result = FirebaseService.isAvailable
        ? await _createAtelierHeadFirebase(
            companyId: companyId,
            fullName: fullName,
            email: email,
            phone: phone,
            atelierName: atelierName,
            address: address,
          )
        : await _createAtelierHeadDemo(
            companyId: companyId,
            fullName: fullName,
            email: email,
            phone: phone,
            atelierName: atelierName,
            address: address,
          );

    if (idempotencyKey != null) {
      _atelierHeadIdempotencyCache[idempotencyKey] = result;
    }
    return result;
  }

  Future<({AppUser user, String temporaryPassword})> _createAtelierHeadDemo({
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
      headStylistPhone: phone.trim(),
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
      mustChangePassword: true,
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

  Future<({AppUser user, String temporaryPassword})> _createAtelierHeadFirebase({
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    required String atelierName,
    String? address,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final temporaryPassword = AuthService.generateTemporaryPassword(normalizedEmail);
    final authUser = await _createSecondaryAuthUser(normalizedEmail, temporaryPassword);
    final uid = authUser.uid;

    final now = DateTime.now();
    final firestore = FirebaseFirestore.instance;
    final atelierId = firestore.collection('ateliers').doc().id;

    final newHead = AppUser(
      id: uid,
      email: normalizedEmail,
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: UserRole.stylist,
      atelierId: atelierId,
      atelierName: atelierName,
      companyId: companyId,
      plan: SubscriptionPlan.enterprise,
      mustChangePassword: true,
      createdAt: now,
    );
    final newAtelier = Atelier(
      id: atelierId,
      name: atelierName,
      headStylistId: uid,
      headStylistName: fullName.trim(),
      headStylistPhone: phone.trim(),
      companyId: companyId,
      address: address,
      createdAt: now,
    );

    final batch = firestore.batch();
    batch.set(firestore.collection('users').doc(uid), newHead.toMap());
    batch.set(firestore.collection('ateliers').doc(atelierId), newAtelier.toMap());
    // Tenu à jour en mode Firebase aussi (déjà fait côté démo ci-dessus) —
    // Company.atelierIds n'est lu nulle part aujourd'hui (admin_companies_screen
    // re-requête ateliersOfCompany en direct), mais laisser ce champ divergent
    // de la réalité est un piège pour toute future fonctionnalité qui s'y fierait.
    batch.update(firestore.collection('companies').doc(companyId), {
      'atelierIds': FieldValue.arrayUnion([atelierId]),
    });
    await batch.commit();

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
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && _tailorIdempotencyCache.containsKey(idempotencyKey)) {
      return _tailorIdempotencyCache[idempotencyKey]!;
    }

    final result = FirebaseService.isAvailable
        ? await _createTailorFirebase(
            atelierId: atelierId,
            atelierName: atelierName,
            fullName: fullName,
            email: email,
            phone: phone,
          )
        : await _createTailorDemo(
            atelierId: atelierId,
            atelierName: atelierName,
            fullName: fullName,
            email: email,
            phone: phone,
          );

    if (idempotencyKey != null) {
      _tailorIdempotencyCache[idempotencyKey] = result;
    }
    return result;
  }

  Future<({AppUser user, String temporaryPassword})> _createTailorDemo({
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
      mustChangePassword: true,
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

  Future<({AppUser user, String temporaryPassword})> _createTailorFirebase({
    required String atelierId,
    required String atelierName,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final temporaryPassword = AuthService.generateTemporaryPassword(normalizedEmail);
    final authUser = await _createSecondaryAuthUser(normalizedEmail, temporaryPassword);
    final uid = authUser.uid;

    final now = DateTime.now();
    final newTailor = AppUser(
      id: uid,
      email: normalizedEmail,
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: UserRole.tailor,
      atelierId: atelierId,
      atelierName: atelierName,
      mustChangePassword: true,
      createdAt: now,
    );

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    batch.set(firestore.collection('users').doc(uid), newTailor.toMap());
    batch.update(firestore.collection('ateliers').doc(atelierId), {
      'tailorIds': FieldValue.arrayUnion([uid]),
    });
    await batch.commit();

    return (user: newTailor, temporaryPassword: temporaryPassword);
  }

  /// Supprime le compte d'un Chef d'atelier, mais PRÉSERVE son Atelier : au
  /// lieu de le supprimer (ce qui rendrait ses commandes/clients définitivement
  /// inaccessibles — firestore.rules résout les droits en relisant le document
  /// atelier par ID, donc plus de document = plus d'accès pour personne, pas
  /// même le Chef d'Entreprise), l'atelier est directement REPRIS par le Chef
  /// d'Entreprise, exactement comme son atelier personnel. Ses couturiers,
  /// clients et commandes restent donc intacts et pleinement accessibles.
  /// Voir assignHeadToExistingAtelier pour transférer ensuite cet atelier
  /// repris à un nouveau Chef d'atelier sans perdre son historique, et
  /// confirmAndRemoveAtelierHead pour l'avertissement affiché à l'utilisateur.
  Future<void> removeAtelierHead(String headId) async {
    if (FirebaseService.isAvailable) {
      final firestore = FirebaseFirestore.instance;
      final atelierSnap = await firestore.collection('ateliers').where('headStylistId', isEqualTo: headId).get();

      final batch = firestore.batch();
      batch.delete(firestore.collection('users').doc(headId));

      for (final doc in atelierSnap.docs) {
        final companyId = doc.data()['companyId'] as String?;
        if (companyId == null) {
          // Ne devrait jamais arriver (un atelier de Chef d'atelier a
          // toujours companyId) — filet de sécurité pour ne pas laisser un
          // atelier orphelin sans propriétaire identifiable.
          batch.delete(doc.reference);
          continue;
        }
        final ownerDoc = await firestore.collection('users').doc(companyId).get();
        final ownerName = ownerDoc.data()?['fullName'] as String? ?? 'Chef d\'Entreprise';
        final ownerPhone = ownerDoc.data()?['phone'] as String?;
        batch.update(doc.reference, {
          'headStylistId': companyId,
          'headStylistName': ownerName,
          'headStylistPhone': ownerPhone,
        });
      }
      await batch.commit();
      // NOTE : le compte Firebase Auth du chef d'atelier reste techniquement
      // actif (pas d'Admin SDK sans Cloud Functions), mais devient inerte —
      // AuthService.signIn refuse la connexion dès que users/{uid} n'existe
      // plus. Sera nettoyé proprement par une Cloud Function en Phase 3/4.
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final head = _atelierHeads.where((u) => u.id == headId).firstOrNull;
    if (head == null) return;
    _atelierHeads.removeWhere((u) => u.id == headId);

    final companyId = head.companyId;
    for (var i = 0; i < _ateliers.length; i++) {
      if (_ateliers[i].headStylistId != headId) continue;
      if (companyId == null) continue;
      final owner = AuthService.findById(companyId);
      _ateliers[i] = _ateliers[i].copyWith(
        headStylistId: companyId,
        headStylistName: owner?.fullName ?? 'Chef d\'Entreprise',
        headStylistPhone: owner?.phone,
      );
    }
  }

  /// Assigne un nouveau Chef d'atelier à un atelier EXISTANT — typiquement un
  /// atelier repris par le Chef d'Entreprise après le renvoi de son ancien
  /// chef (voir removeAtelierHead). Contrairement à createAtelierHead, ne
  /// crée PAS de nouvel atelier : le nouveau chef hérite immédiatement de
  /// tout l'historique (couturiers, clients, commandes) déjà associé à cet
  /// atelierId, au lieu de repartir d'un atelier vide.
  Future<({AppUser user, String temporaryPassword})> assignHeadToExistingAtelier({
    required String atelierId,
    required String atelierName,
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && _atelierHeadIdempotencyCache.containsKey(idempotencyKey)) {
      return _atelierHeadIdempotencyCache[idempotencyKey]!;
    }

    final result = FirebaseService.isAvailable
        ? await _assignHeadToExistingAtelierFirebase(
            atelierId: atelierId,
            atelierName: atelierName,
            companyId: companyId,
            fullName: fullName,
            email: email,
            phone: phone,
          )
        : await _assignHeadToExistingAtelierDemo(
            atelierId: atelierId,
            atelierName: atelierName,
            companyId: companyId,
            fullName: fullName,
            email: email,
            phone: phone,
          );

    if (idempotencyKey != null) {
      _atelierHeadIdempotencyCache[idempotencyKey] = result;
    }
    return result;
  }

  Future<({AppUser user, String temporaryPassword})> _assignHeadToExistingAtelierDemo({
    required String atelierId,
    required String atelierName,
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final headId = _nextId('chef_atelier');

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
      mustChangePassword: true,
      createdAt: now,
    );
    _atelierHeads.add(newHead);

    final atelierIndex = _ateliers.indexWhere((a) => a.id == atelierId);
    if (atelierIndex != -1) {
      _ateliers[atelierIndex] = _ateliers[atelierIndex].copyWith(
        headStylistId: headId,
        headStylistName: fullName.trim(),
        headStylistPhone: phone.trim(),
      );
    }

    final temporaryPassword = AuthService.generateTemporaryPassword(newHead.email);
    return (user: newHead, temporaryPassword: temporaryPassword);
  }

  Future<({AppUser user, String temporaryPassword})> _assignHeadToExistingAtelierFirebase({
    required String atelierId,
    required String atelierName,
    required String companyId,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final temporaryPassword = AuthService.generateTemporaryPassword(normalizedEmail);
    final authUser = await _createSecondaryAuthUser(normalizedEmail, temporaryPassword);
    final uid = authUser.uid;

    final now = DateTime.now();
    final newHead = AppUser(
      id: uid,
      email: normalizedEmail,
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: UserRole.stylist,
      atelierId: atelierId,
      atelierName: atelierName,
      companyId: companyId,
      plan: SubscriptionPlan.enterprise,
      mustChangePassword: true,
      createdAt: now,
    );

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    batch.set(firestore.collection('users').doc(uid), newHead.toMap());
    batch.update(firestore.collection('ateliers').doc(atelierId), {
      'headStylistId': uid,
      'headStylistName': fullName.trim(),
      'headStylistPhone': phone.trim(),
    });
    await batch.commit();

    return (user: newHead, temporaryPassword: temporaryPassword);
  }

  /// Met à jour les informations d'un Chef d'atelier existant, et propage le
  /// nom vers son Atelier (headStylistName y est dupliqué pour l'affichage —
  /// voir Atelier.headStylistName — sinon la fiche atelier resterait figée
  /// sur l'ancien nom après un renommage).
  Future<void> updateAtelierHead({
    required String headId,
    required String fullName,
    required String phone,
    String? email,
  }) async {
    final trimmedName = fullName.trim();

    if (FirebaseService.isAvailable) {
      final firestore = FirebaseFirestore.instance;
      final atelierSnap = await firestore.collection('ateliers').where('headStylistId', isEqualTo: headId).get();
      final batch = firestore.batch();
      batch.update(firestore.collection('users').doc(headId), {
        'fullName': trimmedName,
        'phone': phone.trim(),
        'email': ?email?.trim(),
      });
      for (final doc in atelierSnap.docs) {
        batch.update(doc.reference, {'headStylistName': trimmedName, 'headStylistPhone': phone.trim()});
      }
      await batch.commit();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _atelierHeads.indexWhere((u) => u.id == headId);
    if (index == -1) return;

    final updatedHead = _atelierHeads[index].copyWith(
      fullName: trimmedName,
      phone: phone.trim(),
      email: email?.trim(),
    );
    _atelierHeads[index] = updatedHead;

    final atelierIndex = _ateliers.indexWhere((a) => a.headStylistId == headId);
    if (atelierIndex != -1) {
      _ateliers[atelierIndex] = _ateliers[atelierIndex].copyWith(headStylistName: trimmedName, headStylistPhone: phone.trim());
    }
  }

  /// Suspend ou réactive le compte d'un Chef d'atelier — voir
  /// setTailorActive pour le même mécanisme côté couturier.
  Future<void> setAtelierHeadActive(String headId, bool isActive) async {
    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('users').doc(headId).update({
        'isActive': isActive,
      });
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _atelierHeads.indexWhere((u) => u.id == headId);
    if (index == -1) return;
    _atelierHeads[index] = _atelierHeads[index].copyWith(isActive: isActive);
  }

  Future<void> removeTailor(String tailorId) async {
    if (FirebaseService.isAvailable) {
      final tailor = _tailors.where((t) => t.id == tailorId).firstOrNull;
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.delete(firestore.collection('users').doc(tailorId));
      if (tailor != null) {
        batch.update(firestore.collection('ateliers').doc(tailor.atelierId), {
          'tailorIds': FieldValue.arrayRemove([tailorId]),
        });
      }
      await batch.commit();
      return;
    }

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

  /// Réassigne un couturier d'un atelier à un autre — utilisé par le Chef
  /// d'Entreprise depuis la vue globale des couturiers (CompanyTailorsScreen)
  /// pour redistribuer son équipe entre ses ateliers sans supprimer/recréer
  /// le compte (ce qui perdrait son historique de commandes assignées).
  Future<void> reassignTailor({
    required String tailorId,
    required String currentAtelierId,
    required String newAtelierId,
    required String newAtelierName,
  }) async {
    if (currentAtelierId == newAtelierId) return;

    if (FirebaseService.isAvailable) {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.update(firestore.collection('users').doc(tailorId), {
        'atelierId': newAtelierId,
        'atelierName': newAtelierName,
      });
      batch.update(firestore.collection('ateliers').doc(currentAtelierId), {
        'tailorIds': FieldValue.arrayRemove([tailorId]),
      });
      batch.update(firestore.collection('ateliers').doc(newAtelierId), {
        'tailorIds': FieldValue.arrayUnion([tailorId]),
      });
      await batch.commit();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _tailors.indexWhere((t) => t.id == tailorId);
    if (index == -1) return;
    _tailors[index] = _tailors[index].copyWith(atelierId: newAtelierId, atelierName: newAtelierName);

    final oldAtelierIndex = _ateliers.indexWhere((a) => a.id == currentAtelierId);
    if (oldAtelierIndex != -1) {
      final atelier = _ateliers[oldAtelierIndex];
      _ateliers[oldAtelierIndex] = atelier.copyWith(
        tailorIds: atelier.tailorIds.where((id) => id != tailorId).toList(),
      );
    }
    final newAtelierIndex = _ateliers.indexWhere((a) => a.id == newAtelierId);
    if (newAtelierIndex != -1) {
      final atelier = _ateliers[newAtelierIndex];
      _ateliers[newAtelierIndex] = atelier.copyWith(
        tailorIds: [...atelier.tailorIds, tailorId],
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
    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('users').doc(tailorId).update({
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'email': ?email?.trim(),
      });
      return;
    }

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

  /// Suspend ou réactive le compte d'un couturier, sans le supprimer (voir
  /// removeTailor pour une suppression définitive) — utile pour une absence
  /// temporaire (congé...) sans perdre son historique de commandes. Un
  /// compte suspendu (isActive == false) se voit refuser la connexion par
  /// AuthService.signIn, mais reste visible et réactivable à tout moment.
  Future<void> setTailorActive(String tailorId, bool isActive) async {
    if (FirebaseService.isAvailable) {
      await FirebaseFirestore.instance.collection('users').doc(tailorId).update({
        'isActive': isActive,
      });
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final index = _tailors.indexWhere((t) => t.id == tailorId);
    if (index == -1) return;
    _tailors[index] = _tailors[index].copyWith(isActive: isActive);
  }

  /// Recherche un compte (Chef d'atelier OU Couturier) par email, pour le
  /// flux de connexion unique — voir AuthService.signIn. Mode démo
  /// uniquement : en mode Firebase, AuthService._signInFirebase authentifie
  /// directement via Firebase Auth (qui connaît TOUS les comptes, quelle que
  /// soit la méthode de création) sans passer par ce cache local.
  AppUser? findAccountByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final inHeads = _atelierHeads.where((u) => u.email.toLowerCase() == normalized).firstOrNull;
    if (inHeads != null) return inHeads;
    return _tailors.where((u) => u.email.toLowerCase() == normalized).firstOrNull;
  }

  /// Recherche un compte (Chef d'atelier OU Couturier) par ID — voir
  /// AuthService.findById pour les comptes "principaux" (admin, styliste
  /// solo, chef d'entreprise). Mode démo uniquement (voir AdminDemoData, qui
  /// relira directement Firestore une fois migré).
  AppUser? findAccountById(String id) {
    final inHeads = _atelierHeads.where((u) => u.id == id).firstOrNull;
    if (inHeads != null) return inHeads;
    return _tailors.where((u) => u.id == id).firstOrNull;
  }

  /// Met à jour un utilisateur existant dans _atelierHeads ou _tailors
  /// (utilisé par AdminDemoData). Mode démo uniquement.
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
    String? idempotencyKey,
  }) =>
      OrderService.instance.addClient(
        atelierId: atelierId,
        atelierName: atelierName,
        fullName: fullName,
        phone: phone,
        email: email,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );
}
