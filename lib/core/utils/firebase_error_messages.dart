import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';

/// Traduit une exception Firebase (Auth ou Firestore) en message utilisateur
/// clair, pour les flux de création de compte/donnée (Chef d'atelier,
/// Couturier, Client...) — sans ça, l'utilisateur voit des messages bruts
/// type "[firebase_auth/email-already-in-use] The email address is already
/// in use by another account." au lieu d'une phrase compréhensible. Voir
/// AuthService._firebaseAuthErrorMessage pour l'équivalent côté connexion
/// (messages différents : ici on crée un compte, pas on s'y connecte).
String friendlyFirebaseError(Object error) {
  if (error is fb_auth.FirebaseAuthException) {
    return switch (error.code) {
      'email-already-in-use' => 'Un compte existe déjà avec cet email.',
      'invalid-email' => 'Adresse email invalide.',
      'weak-password' => 'Mot de passe trop faible.',
      'network-request-failed' => 'Problème de connexion réseau. Réessayez.',
      'too-many-requests' => 'Trop de tentatives. Réessayez dans quelques minutes.',
      _ => 'Une erreur est survenue. Réessayez.',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Vous n\'avez pas les droits nécessaires pour cette action.',
      'unavailable' => 'Problème de connexion réseau. Réessayez.',
      _ => 'Une erreur est survenue. Réessayez.',
    };
  }
  return 'Une erreur est survenue. Réessayez.';
}
