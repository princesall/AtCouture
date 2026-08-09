import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/firebase_error_messages.dart';
import '../../core/widgets/voice_note_player.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

/// Ouvre le dialog de signalement de problème pour `order` — remplace
/// l'ancien tap direct sur OrderStatus.problem, qui changeait le statut sans
/// aucune explication (ni pour la styliste, ni pour l'entreprise). Beaucoup
/// de couturiers n'écrivent pas facilement ou n'ont pas le temps : le mémo
/// vocal est donc une alternative au texte, pas un complément obligatoire.
/// Retourne true si le signalement a été envoyé, false/null sinon.
Future<bool?> showReportProblemDialog(BuildContext context, Order order) {
  return showDialog<bool>(
    context: context,
    builder: (_) => ReportProblemDialog(order: order),
  );
}

class ReportProblemDialog extends StatefulWidget {
  const ReportProblemDialog({super.key, required this.order});
  final Order order;

  @override
  State<ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<ReportProblemDialog> {
  final _noteController = TextEditingController();
  final _recorder = AudioRecorder();
  Timer? _ticker;

  bool _isRecording = false;
  String? _recordedPath;
  Duration _recordDuration = Duration.zero;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _ticker?.cancel();
    _noteController.dispose();
    _recorder.dispose();
    // Nettoie le fichier temporaire s'il n'a pas déjà été supprimé via
    // _discardRecording — couvre l'annulation du dialog (bouton Annuler,
    // tap en dehors, retour arrière) avec un mémo déjà enregistré mais
    // jamais envoyé. Après un envoi réussi, le fichier a déjà été lu en
    // entier par uploadVoiceNote() : le supprimer ici est sans risque.
    if (_recordedPath != null) {
      File(_recordedPath!).delete().ignore();
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      setState(() => _error = 'Autorisation micro refusée. Active-la dans les réglages du téléphone.');
      return;
    }
    // Fichier jetable : uploadVoiceNote() lit ce chemin puis c'est terminé,
    // rien d'autre n'en dépend une fois le signalement envoyé.
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/issue_${widget.order.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordedPath = null;
      _recordDuration = Duration.zero;
      _error = null;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordedPath = path;
    });
  }

  void _discardRecording() {
    final path = _recordedPath;
    setState(() => _recordedPath = null);
    if (path != null) {
      File(path).delete().ignore();
    }
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (note.isEmpty && _recordedPath == null) {
      setState(() => _error = 'Décris le problème par écrit ou enregistre un mémo vocal.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final changedBy = context.read<AuthProvider>().user!.fullName;
      String? voiceNoteUrl;
      if (_recordedPath != null) {
        voiceNoteUrl = await OrderService.instance.uploadVoiceNote(widget.order.id, _recordedPath!);
      }
      await OrderService.instance.updateOrderStatus(
        widget.order.id,
        OrderStatus.problem,
        changedByName: changedBy,
        note: note.isEmpty ? null : note,
        voiceNoteUrl: voiceNoteUrl,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = friendlyFirebaseError(e);
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      backgroundColor: c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Signaler un problème', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Décris le problème par écrit ou enregistre un mémo vocal (au moins l\'un des deux).',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 3,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                hintText: 'Ex: Tissu insuffisant pour finir la commande…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            _buildRecorder(c),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: AppTextStyles.bodySm.copyWith(color: c.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _isRecording ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: c.error, foregroundColor: Colors.white),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }

  Widget _buildRecorder(AppColorPalette c) {
    if (_recordedPath != null) {
      return Row(
        children: [
          VoiceNotePlayer(source: _recordedPath!),
          const Spacer(),
          IconButton(
            onPressed: _isSubmitting ? null : _discardRecording,
            icon: Icon(Icons.delete_outline_rounded, color: c.onSurfaceVariant),
            tooltip: 'Supprimer',
          ),
        ],
      );
    }
    return OutlinedButton.icon(
      onPressed: _isSubmitting ? null : (_isRecording ? _stopRecording : _startRecording),
      icon: Icon(
        _isRecording ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
        color: _isRecording ? c.error : c.primary,
      ),
      label: Text(
        _isRecording ? 'Arrêter (${_formatDuration(_recordDuration)})' : 'Enregistrer un mémo vocal',
        style: AppTextStyles.labelCaps.copyWith(color: _isRecording ? c.error : c.primary),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _isRecording ? c.error : c.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
