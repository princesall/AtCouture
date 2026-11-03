import '../../firebase_options.dart';

/// Identifiants OAuth Google du projet Firebase `styleconnect-25e1c`.
///
/// Ce ne sont PAS des secrets : un client OAuth « public » (application
/// mobile / web) est de toute façon visible par quiconque inspecte l'app.
/// En revanche ils doivent rester alignés sur le projet Firebase, sinon
/// Google renvoie un `idToken` dont l'audience ne correspond pas à celle
/// attendue par Firebase Auth, et `signInWithCredential` échoue avec
/// `invalid-credential` / `audience mismatch`.
///
/// Pourquoi les déclarer explicitement plutôt que de compter sur les fichiers
/// natifs :
/// - Android : `google_sign_in` lit le client de type « Web » dans
///   `google-services.json`, mais seulement si le plugin y a accès. Le passer
///   explicitement évite l'erreur `serverClientId must be provided on Android`.
/// - iOS : il n'y a PAS de `GoogleService-Info.plist` dans le bundle (Firebase
///   est configuré via `DefaultFirebaseOptions`). Sans `clientId`, GIDSignIn ne
///   peut pas construire sa configuration : `GoogleSignIn.instance.initialize()`
///   échouait donc avant même d'afficher la fenêtre Google.
///
/// Voir `AuthService._ensureGoogleSignInInitialized`.
abstract final class GoogleAuthConfig {
  /// Client OAuth de type « Web » (`client_type: 3` dans
  /// `android/app/google-services.json`). Utilisé comme `serverClientId` :
  /// c'est l'audience que Firebase Auth attend dans l'`idToken`, sur Android
  /// comme sur iOS.
  static const String webClientId =
      '671589265068-p91e94hhi4b1av3v2rb7am68g32td077.apps.googleusercontent.com';

  /// Client OAuth iOS — même valeur que `iosClientId` dans
  /// `lib/firebase_options.dart`, dont le schéma d'URL inversé est déjà
  /// déclaré dans `ios/Runner/Info.plist` (CFBundleURLTypes).
  static String? get iosClientId => DefaultFirebaseOptions.ios.iosClientId;
}
