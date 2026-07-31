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

    await Future<void>.delayed(const Duration(milliseconds: 400));

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
  }) async {
    _setLoading();
    try {
      _user = await _authService.registerStylist(
        fullName: fullName,
        atelierName: atelierName,
        email: email,
        phone: phone,
        password: password,
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
      await _authService.changePassword(
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

  /// Rafraîchit l'utilisateur connecté depuis les données AuthService (après mise à jour admin)
  void refreshUser() {
    if (_user != null) {
      // Récupérer l'utilisateur mis à jour depuis AuthService._demoUsers
      final updatedUser = _authService.getUserById(_user!.id);
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
      }
    }
  }
}
