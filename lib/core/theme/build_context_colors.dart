import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import 'app_color_palette.dart';

/// `context.colors.primary` — palette réactive au thème courant (clair/sombre).
/// À utiliser à la place de `AppColors.xxx` (statique, toujours clair) dans
/// tout écran migré vers le support du mode sombre.
extension BuildContextColors on BuildContext {
  AppColorPalette get colors => watch<ThemeProvider>().colors;

  /// Même palette, mais SANS abonnement au provider.
  ///
  /// Obligatoire dès qu'on lit les couleurs hors d'un `build` — typiquement
  /// dans un callback (`onTap`, `onPressed`) ou après un `await` d'action
  /// admin. Un `watch` y déclenche en debug l'assertion « Tried to listen to a
  /// value exposed with provider, from outside of the widget tree », ce qui
  /// faisait échouer tout retour visuel (`showAdminSnack`, `adminConfirm`,
  /// `adminPickPlan`) appelé depuis un bouton.
  AppColorPalette get colorsRead => read<ThemeProvider>().colors;
}
