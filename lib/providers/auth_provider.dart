import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  AppUser? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isDemoMode => _authService.isDemoMode;

  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // Sur web, le SDK Firebase peut mettre plusieurs secondes à charger ses
      // scripts. Sans borne, un réseau lent laissait l'application sur un
      // écran blanc indéfiniment. Au-delà du délai, on retombe proprement sur
      // l'état « non connecté » : l'utilisateur voit l'écran de connexion et
      // peut réessayer, au lieu d'attendre un Future qui ne se termine jamais.
      await _authService.initialize().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage =
          'La connexion au serveur a expiré. Vérifiez votre réseau.';
      notifyListeners();
      return;
    }

    final current = _authService.currentUser;
    if (current != null) {
      _user = current;
      _status = AuthStatus.authenticated;
      _watchOwnUser();
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Connexion email/mot de passe.
  ///
  /// [requireAdmin] est utilisé par la console web : si le compte n'a pas le
  /// rôle admin, la session est immédiatement fermée AVANT de publier l'état
  /// authentifié. Sans cela, le router admin verrait brièvement une session
  /// valide et redirigerait vers l'écran « accès refusé », puis la
  /// déconnexion ramènerait à la page de connexion — un aller-retour inutile.
  Future<bool> signIn(
    String email,
    String password, {
    bool requireAdmin = false,
  }) async {
    _setLoading();
    try {
      final user = await _authService
          .signIn(email: email, password: password)
          .timeout(const Duration(seconds: 25));
      if (requireAdmin && !user.isAdmin) {
        await _authService.signOut();
        _setError('Ce compte n\'a pas les droits administrateur.');
        return false;
      }
      _user = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _watchOwnUser();
      notifyListeners();
      return true;
    } on TimeoutException {
      _setError('La connexion au serveur a expiré. Vérifiez votre réseau.');
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Une erreur est survenue. Réessayez.');
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String atelierName,
    required String email,
    required String phone,
    required String password,
    XFile? logoFile,
  }) async {
    _setLoading();
    try {
      _user = await _authService.registerStylist(
        fullName: fullName,
        atelierName: atelierName,
        email: email,
        phone: phone,
        password: password,
        logoFile: logoFile,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _watchOwnUser();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Inscription impossible. Réessayez.');
      return false;
    }
  }

  /// Connexion/inscription via Google. Retourne le résultat brut pour que
  /// l'écran appelant décide quoi faire : GoogleSignInExisting signifie que
  /// la connexion est déjà terminée (isAuthenticated devient true) ;
  /// GoogleSignInNeedsProfile signifie qu'il faut rediriger vers l'écran de
  /// complétion de profil avant de pouvoir finaliser le compte. Retourne
  /// null en cas d'échec (voir errorMessage).
  Future<GoogleSignInResult?> signInWithGoogle() async {
    _setLoading();
    try {
      // Borne volontairement large : le temps que l'utilisateur choisisse son
      // compte et saisisse son mot de passe dans la fenêtre Google. Sans
      // borne, un popup resté ouvert/bloqué laissait l'écran de connexion en
      // « chargement » indéfiniment.
      final result = await _authService.signInWithGoogle().timeout(
        const Duration(minutes: 2),
      );
      if (result is GoogleSignInExisting) {
        _user = result.user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        _watchOwnUser();
      } else {
        // Compte Firebase Auth créé mais profil pas encore complété — pas
        // encore "authentifié" au sens de l'app tant que users/{uid} n'existe pas.
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      }
      notifyListeners();
      return result;
    } on TimeoutException {
      _setError('La fenêtre Google ne répond pas. Fermez-la puis réessayez.');
      return null;
    } on AuthException catch (e) {
      _setError(e.message);
      return null;
    } catch (_) {
      _setError('Connexion Google impossible. Réessayez.');
      return null;
    }
  }

  /// Termine la création d'un compte démarré via Google (voir
  /// signInWithGoogle / GoogleSignInNeedsProfile) une fois que le styliste a
  /// renseigné le nom de son atelier et son téléphone.
  Future<bool> completeGoogleSignUp({
    required String uid,
    required String email,
    required String fullName,
    required String atelierName,
    required String phone,
    XFile? logoFile,
    String? photoUrl,
  }) async {
    _setLoading();
    try {
      _user = await _authService.completeGoogleSignUp(
        uid: uid,
        email: email,
        fullName: fullName,
        atelierName: atelierName,
        phone: phone,
        logoFile: logoFile,
        photoUrl: photoUrl,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _watchOwnUser();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Impossible de finaliser votre compte. Réessayez.');
      return false;
    }
  }

  bool _isUpdatingLogo = false;
  bool get isUpdatingLogo => _isUpdatingLogo;

  /// Met à jour le logo de l'atelier / la photo de profil du compte connecté.
  /// [file] null supprime le logo existant.
  ///
  /// N'utilise PAS _setLoading() : changer de logo ne doit jamais repasser
  /// AuthStatus à `loading`, sinon AppRouter.redirect renvoie l'utilisateur à
  /// l'écran de connexion en pleine action (même raison que changePassword).
  Future<bool> updateLogo(XFile? file) async {
    if (_user == null) return false;
    _isUpdatingLogo = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.updateProfilePhoto(
        userId: _user!.id,
        photoFile: file,
      );
      _isUpdatingLogo = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isUpdatingLogo = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _isUpdatingLogo = false;
      _errorMessage = 'Impossible de mettre à jour le logo. Réessayez.';
      notifyListeners();
      return false;
    }
  }

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  /// Change le mot de passe de l'utilisateur connecté. Ne passe PAS par
  /// _setLoading()/_setError() : ces méthodes changent _status, or
  /// AppRouter.redirect renvoie vers /auth/login dès que _status n'est plus
  /// AuthStatus.authenticated — ça déconnecterait l'utilisateur en pleine
  /// saisie. On garde donc un état de chargement local et indépendant.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) return false;
    _isChangingPassword = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.changePassword(
        email: _user!.email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isChangingPassword = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isChangingPassword = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _isChangingPassword = false;
      _errorMessage = 'Une erreur est survenue. Réessayez.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading();
    try {
      await _authService.sendPasswordResetEmail(email);
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Impossible d\'envoyer l\'email. Réessayez.');
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Démarre la surveillance temps réel du compte connecté (voir
  /// AuthService.watchOwnUserDoc) : si un admin le suspend pendant que la
  /// session est déjà ouverte, force une déconnexion immédiate au lieu
  /// d'attendre la prochaine connexion ; sinon, tient `user` à jour en
  /// permanence (ex: un upgrade de plan approuvé par l'admin en session
  /// débloque désormais les fonctionnalités immédiatement, sans reconnexion).
  void _watchOwnUser() {
    _authService.watchOwnUserDoc((updatedUser) {
      if (!updatedUser.isActive) {
        _authService.signOut();
        _user = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Votre compte a été suspendu par un administrateur.';
        notifyListeners();
        return;
      }
      _user = updatedUser;
      notifyListeners();
    });
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_user != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Rafraîchit l'utilisateur connecté depuis AuthService (après une action
  /// admin, ex: approbation d'abonnement). En mode Firebase, relit Firestore.
  Future<void> refreshUser() async {
    if (_user == null) return;
    final updatedUser = await _authService.getUserById(_user!.id);
    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
    }
  }
}
