import 'package:flutter/foundation.dart';

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

    await _authService.initialize();

    final current = _authService.currentUser;
    if (current != null) {
      _user = current;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading();
    try {
      _user = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
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
    String? logoPath,
  }) async {
    _setLoading();
    try {
      _user = await _authService.registerStylist(
        fullName: fullName,
        atelierName: atelierName,
        email: email,
        phone: phone,
        password: password,
        logoPath: logoPath,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
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
      final result = await _authService.signInWithGoogle();
      if (result is GoogleSignInExisting) {
        _user = result.user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      } else {
        // Compte Firebase Auth créé mais profil pas encore complété — pas
        // encore "authentifié" au sens de l'app tant que users/{uid} n'existe pas.
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      }
      notifyListeners();
      return result;
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
        photoUrl: photoUrl,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
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
