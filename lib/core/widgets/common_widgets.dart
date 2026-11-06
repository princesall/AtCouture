import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/build_context_colors.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.primaryFixed.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(icon, size: 32, color: c.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.headlineLgMobile,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTextStyles.bodySm.copyWith(
                  color: c.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMd),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle!, style: AppTextStyles.bodySm),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class PlanBadge extends StatelessWidget {
  const PlanBadge({super.key, required this.planName, this.compact = false});

  final String planName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: compact ? 2 : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        gradient: c.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        planName.toUpperCase(),
        style: AppTextStyles.labelCaps.copyWith(
          color: c.onTertiary,
          fontSize: compact ? 9 : 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Écran de confirmation après une création/modification réussie dans un
/// bottom sheet ou un dialog : icône de succès, titre, message, bouton
/// "FERMER" qui pop la route. Extrait pour remplacer les copier-coller
/// identiques répétés sur chaque écran de création (atelier, couturier,
/// client, plan admin...).
class SuccessConfirmationSheet extends StatelessWidget {
  const SuccessConfirmationSheet({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(PhosphorIconsRegular.checkCircle, color: c.statusDone, size: 52),
        const SizedBox(height: 16),
        Text(title, style: AppTextStyles.titleMd.copyWith(color: c.primary)),
        const SizedBox(height: 8),
        Text(message, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: Text('FERMER', style: AppTextStyles.labelCaps.copyWith(color: c.onPrimary)),
        )),
      ]),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.imageUrl,
    this.dark = false,
  });

  final String initials;
  final double size;
  final String? imageUrl;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final url = imageUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: dark ? c.heroGradient : c.goldGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: c.outlineVariant,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? Text(
              initials,
              style: AppTextStyles.labelCaps.copyWith(
                color: Colors.white,
                fontSize: size * 0.34,
              ),
            )
          : _AvatarImage(url: url, size: size),
    );
  }
}

/// Affiche l'image d'un avatar/logo depuis une URL réseau, une image encodée
/// en base64 (data-URL), ou un chemin de fichier local (celui renvoyé par
/// image_picker), avec repli discret sur l'icône d'atelier si le fichier
/// n'existe plus (ex : démo réinstallée, cache vidé).
class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.url, required this.size});
  final String url;
  final double size;

  /// Cache des images base64 déjà décodées, indexé par la data-URL complète.
  ///
  /// Sans lui, `Image.memory` recevrait un nouveau `Uint8List` à chaque
  /// reconstruction de l'avatar : `MemoryImage` ne reconnaîtrait pas l'image
  /// comme déjà chargée et la redécoderait à chaque fois. On garde les
  /// dernières entrées seulement (un écran n'affiche qu'un logo à la fois).
  static final Map<String, Uint8List> _decodedCache = <String, Uint8List>{};
  static const int _decodedCacheLimit = 8;

  static Uint8List? _decodeDataUrl(String url) {
    final cached = _decodedCache[url];
    if (cached != null) return cached;

    final comma = url.indexOf(',');
    if (comma == -1 || comma + 1 >= url.length) return null;

    try {
      final bytes = base64Decode(url.substring(comma + 1));
      if (bytes.isEmpty) return null;
      if (_decodedCache.length >= _decodedCacheLimit) {
        _decodedCache.remove(_decodedCache.keys.first);
      }
      _decodedCache[url] = bytes;
      return bytes;
    } catch (_) {
      // Data-URL corrompue : on retombe sur l'icône plutôt que de planter.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sur le web, image_picker renvoie une URL `blob:` (pas un vrai chemin de
    // fichier) : `dart:io File` n'y fonctionne pas et fait planter l'écran.
    final isRemote = kIsWeb ||
        url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('blob:');
    final errorFallback = Icon(PhosphorIconsRegular.storefront, color: Colors.white, size: size * 0.4);

    // Repli sans Firebase Storage : le logo est stocké en base64 dans
    // users.photoUrl (voir ProfileLogoService). `Image.file` ne saurait pas
    // l'ouvrir, il faut décoder les octets et passer par `Image.memory`.
    if (url.startsWith('data:')) {
      final bytes = _decodeDataUrl(url);
      if (bytes == null) return errorFallback;
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => errorFallback,
      );
    }

    if (isRemote) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => errorFallback,
      );
    }
    return Image.file(
      File(url),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => errorFallback,
    );
  }
}
