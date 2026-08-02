import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import 'app_color_palette.dart';

/// `context.colors.primary` — palette réactive au thème courant (clair/sombre).
/// À utiliser à la place de `AppColors.xxx` (statique, toujours clair) dans
/// tout écran migré vers le support du mode sombre.
extension BuildContextColors on BuildContext {
  AppColorPalette get colors => watch<ThemeProvider>().colors;
}
