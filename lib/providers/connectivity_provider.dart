import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Suit l'état de connexion réseau de l'appareil, pour afficher un bandeau
/// "hors ligne" dans les tableaux de bord. Ne bloque rien : Firestore
/// continue de fonctionner en local pendant une coupure (lecture depuis le
/// cache, écritures mises en file d'attente puis rejouées au retour du
/// réseau, voir OrderService/CompanyService) — ce provider sert uniquement
/// à informer l'utilisateur de son état de connexion.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    _subscription = Connectivity().onConnectivityChanged.listen(_update);
    Connectivity().checkConnectivity().then(_update);
  }

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  void _update(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (offline != _isOffline) {
      _isOffline = offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
