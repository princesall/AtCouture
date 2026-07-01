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
}
