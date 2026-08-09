import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/build_context_colors.dart';

/// Bouton play/pause compact pour écouter un mémo vocal joint à un
/// signalement de problème (voir OrderStatusChange.voiceNoteUrl et
/// ReportProblemDialog). `source` est soit une URL Firebase Storage, soit un
/// chemin de fichier local en mode démo (voir OrderService.uploadVoiceNote).
class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({super.key, required this.source});
  final String source;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _stateSub;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    final isLocalFile = !widget.source.startsWith('http');
    await _player.play(isLocalFile ? DeviceFileSource(widget.source) : UrlSource(widget.source));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.statusProblemBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 16, color: c.statusProblem),
            const SizedBox(width: 4),
            Text(
              _playing ? 'Lecture…' : 'Mémo vocal',
              style: AppTextStyles.labelXs.copyWith(color: c.statusProblem, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
