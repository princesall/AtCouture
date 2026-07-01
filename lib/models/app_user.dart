import 'package:equatable/equatable.dart';

import '../core/utils/plan_permissions.dart';
import 'subscription_plan.dart';
import 'user_role.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.atelierId,
    this.atelierName,
    this.companyId,
    this.photoUrl,
    this.plan = SubscriptionPlan.free,
    this.planExpiresAt,
    this.isActive = true,
    this.mustChangePassword = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;
  final String? atelierId;
  final String? atelierName;

  /// Si ce user est un Chef Styliste d'atelier (role==stylist) créé par un
  /// Chef d'Entreprise (role==companyOwner), `companyId` pointe vers l'UID
  /// du propriétaire. Null si l'atelier est indépendant (Gratuit/Starter/Pro).
  final String? companyId;
  final String? photoUrl;
  final SubscriptionPlan plan;
  final DateTime? planExpiresAt;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? createdAt;

  bool get isAdmin => role == UserRole.admin;

  /// Permissions RÉELLEMENT actives pour ce compte, en tenant compte de
  /// l'expiration de l'abonnement. C'est LE point d'entrée à utiliser partout
  /// dans l'UI pour savoir ce que cet utilisateur a le droit de faire.
  /// Si le plan payant a expiré, retombe automatiquement sur les droits
  /// du plan Gratuit (sans jamais toucher aux données déjà créées).
  PlanPermissions get permissions =>
      PlanPermissions.forUser(plan: plan, planExpiresAt: planExpiresAt);
  bool get isCompanyOwner => role == UserRole.companyOwner;
  bool get isStylist => role == UserRole.stylist || role == UserRole.companyOwner;
  bool get isTailor => role == UserRole.tailor;

  /// True si ce styliste gère un atelier rattaché à une Entreprise
  bool get belongsToCompany => companyId != null;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  /// Prénom uniquement, pour les salutations ("Bonjour, {firstName}").
  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    String? atelierId,
    String? atelierName,
    String? companyId,
    String? photoUrl,
    SubscriptionPlan? plan,
    DateTime? planExpiresAt,
    bool? isActive,
    bool? mustChangePassword,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      atelierId: atelierId ?? this.atelierId,
      atelierName: atelierName ?? this.atelierName,
      companyId: companyId ?? this.companyId,
      photoUrl: photoUrl ?? this.photoUrl,
      plan: plan ?? this.plan,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.stylist,
      ),
      atelierId: map['atelierId'] as String?,
      atelierName: map['atelierName'] as String?,
      companyId: map['companyId'] as String?,
      photoUrl: map['photoUrl'] as String?,
      plan: SubscriptionPlan.values.firstWhere(
        (p) => p.name == map['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      planExpiresAt: map['planExpiresAt'] != null
          ? DateTime.tryParse(map['planExpiresAt'] as String)
          : null,
      isActive: map['isActive'] as bool? ?? true,
      mustChangePassword: map['mustChangePassword'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.name,
      'atelierId': atelierId,
      'atelierName': atelierName,
      'companyId': companyId,
      'photoUrl': photoUrl,
      'plan': plan.name,
      'planExpiresAt': planExpiresAt?.toIso8601String(),
      'isActive': isActive,
      'mustChangePassword': mustChangePassword,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, email, role, plan];
}
