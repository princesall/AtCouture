enum UserRole {
  /// Administrateur de la plateforme StyleConnect (gestion abonnements, comptes)
  admin('Administrateur'),

  /// Propriétaire d'une Entreprise multi-ateliers (plan Entreprise uniquement).
  /// Crée et supervise plusieurs Chefs d'atelier, vue consolidée sur tout.
  companyOwner('Chef d\'Entreprise'),

  /// Chef Styliste d'un atelier unique (plans Gratuit / Starter / Pro),
  /// ou Chef d'un atelier appartenant à une Entreprise (créé par companyOwner).
  stylist('Chef Styliste'),

  /// Couturier rattaché à un atelier précis.
  tailor('Couturier');

  const UserRole(this.label);
  final String label;

  bool get managesAtelier => this == stylist || this == companyOwner;
}
