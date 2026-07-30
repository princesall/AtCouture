import 'package:flutter/material.dart';

/// Demande à l'utilisateur le nom d'une nouvelle mesure personnalisée
/// (ex: "Tour de bras"). Retourne `null` si annulé ou vide.
Future<String?> promptCustomMeasurementLabel(BuildContext context) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nouvelle mesure'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nom de la mesure',
          hintText: 'ex : Tour de bras',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final label = controller.text.trim();
            Navigator.pop(context, label.isEmpty ? null : label);
          },
          child: const Text('Ajouter'),
        ),
      ],
    ),
  );
}
