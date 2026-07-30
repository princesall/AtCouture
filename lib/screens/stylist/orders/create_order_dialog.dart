import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/measurement_field_prompt.dart';
import '../../../core/utils/plan_permissions.dart';
import '../../../models/app_user.dart';
import '../../../models/client.dart';
import '../../../models/order.dart';
import '../../../services/company_service.dart';
import '../../../services/measurement_fields_service.dart';
import '../../../services/order_service.dart';
import 'order_list_widgets.dart';

typedef CreateOrderResult = ({Order order, bool isNewClient, Client? existingClient});

/// Dialogue de création d'une commande. Retourne le [CreateOrderResult] via
/// `Navigator.pop(context, result)` quand la commande est créée, ou `null`
/// si l'utilisateur annule — au caller de rafraîchir la liste et d'afficher
/// la confirmation.
class CreateOrderDialog extends StatefulWidget {
  const CreateOrderDialog({super.key, required this.user});

  final AppUser user;

  @override
  State<CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<CreateOrderDialog> {
  AppUser? _selectedTailor;
  final List<XFile> _modelPhotos = [];
  final List<XFile> _fabricPhotos = [];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _dueDateController = TextEditingController();

  final _epauleController = TextEditingController();
  final _poitrineController = TextEditingController();
  final _tailleController = TextEditingController();
  final _hancheController = TextEditingController();
  final _longueurController = TextEditingController();
  static const _standardMeasurementKeys = {'epaule', 'poitrine', 'taille', 'hanche', 'longueur'};

  late final Map<String, TextEditingController> _customMeasurementControllers = {
    for (final label in MeasurementFieldsService.instance.customFieldsFor(widget.user.atelierId!))
      label: TextEditingController(),
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _dueDateController.dispose();
    _epauleController.dispose();
    _poitrineController.dispose();
    _tailleController.dispose();
    _hancheController.dispose();
    _longueurController.dispose();
    for (final controller in _customMeasurementControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _searchExistingClient(PlanPermissions permissions) {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    final existing = OrderService.instance.findClientByPhone(phone, widget.user.atelierId!);
    if (existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun client trouvé avec ce numéro')),
      );
      return;
    }
    final saved = existing.savedMeasurements;
    final prefilledMeasurements = permissions.hasSavedMeasurements && saved != null && saved.isNotEmpty;
    setState(() {
      _nameController.text = existing.fullName;
      if (existing.email != null) _emailController.text = existing.email!;
      if (prefilledMeasurements) {
        if (saved['epaule'] != null) _epauleController.text = saved['epaule'].toString();
        if (saved['poitrine'] != null) _poitrineController.text = saved['poitrine'].toString();
        if (saved['taille'] != null) _tailleController.text = saved['taille'].toString();
        if (saved['hanche'] != null) _hancheController.text = saved['hanche'].toString();
        if (saved['longueur'] != null) _longueurController.text = saved['longueur'].toString();
        // Mesures personnalisées déjà enregistrées pour ce client.
        for (final entry in saved.entries) {
          if (!_standardMeasurementKeys.contains(entry.key)) {
            _customMeasurementControllers
                .putIfAbsent(entry.key, () => TextEditingController())
                .text = entry.value.toString();
          }
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Client trouvé : ${existing.fullName}${prefilledMeasurements ? ' — mesures pré-remplies' : ''}')),
    );
  }

  Future<void> _submit(PlanPermissions permissions) async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir le nom et le téléphone')),
      );
      return;
    }

    // Parser les mesures (seulement si le plan le permet)
    Map<String, double>? measurements;
    if (permissions.hasSavedMeasurements && (
        _epauleController.text.isNotEmpty ||
        _poitrineController.text.isNotEmpty ||
        _tailleController.text.isNotEmpty ||
        _hancheController.text.isNotEmpty ||
        _longueurController.text.isNotEmpty)) {
      measurements = {};
      if (_epauleController.text.isNotEmpty) {
        measurements['epaule'] = double.tryParse(_epauleController.text) ?? 0;
      }
      if (_poitrineController.text.isNotEmpty) {
        measurements['poitrine'] = double.tryParse(_poitrineController.text) ?? 0;
      }
      if (_tailleController.text.isNotEmpty) {
        measurements['taille'] = double.tryParse(_tailleController.text) ?? 0;
      }
      if (_hancheController.text.isNotEmpty) {
        measurements['hanche'] = double.tryParse(_hancheController.text) ?? 0;
      }
      if (_longueurController.text.isNotEmpty) {
        measurements['longueur'] = double.tryParse(_longueurController.text) ?? 0;
      }
    }
    if (permissions.hasSavedMeasurements) {
      for (final entry in _customMeasurementControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          measurements ??= {};
          measurements[entry.key] = double.tryParse(entry.value.text) ?? 0;
        }
      }
    }

    // Parser la date
    DateTime? dueDate;
    if (_dueDateController.text.isNotEmpty) {
      // Format simple JJ/MM/AAAA
      final parts = _dueDateController.text.split('/');
      if (parts.length == 3) {
        try {
          dueDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } catch (_) {}
      }
    }

    final result = await OrderService.instance.createOrder(
      clientName: _nameController.text.trim(),
      clientPhone: _phoneController.text.trim(),
      clientEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      tailorId: _selectedTailor?.id,
      atelierId: widget.user.atelierId!,
      atelierName: widget.user.atelierName!,
      measurements: measurements,
      modelPhotos: _modelPhotos.isEmpty ? null : _modelPhotos.map((f) => f.path).toList(),
      fabricPhotos: _fabricPhotos.isEmpty ? null : _fabricPhotos.map((f) => f.path).toList(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      price: _priceController.text.trim().isEmpty ? null : int.tryParse(_priceController.text.trim()),
      deposit: _depositController.text.trim().isEmpty ? null : int.tryParse(_depositController.text.trim()),
      dueDate: dueDate,
      createdByName: widget.user.fullName,
    );

    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.user.permissions;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Nouvelle commande', style: AppTextStyles.headlineMd),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Infos client
              Text('Informations client', style: AppTextStyles.titleSm),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du client *',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Téléphone *',
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Rechercher un client existant',
                    onPressed: () => _searchExistingClient(permissions),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Assignation de couturier
              Text('Assigner à un couturier (optionnel)', style: AppTextStyles.titleSm),
              const SizedBox(height: AppSpacing.sm),
              Builder(builder: (context) {
                final tailors = CompanyService.instance.tailorsOfAtelier(widget.user.atelierId!);
                if (tailors.isEmpty) {
                  return Text(
                    'Aucun couturier disponible',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  );
                }
                return DropdownButtonFormField<AppUser>(
                  decoration: const InputDecoration(
                    labelText: 'Couturier',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  initialValue: _selectedTailor,
                  items: tailors.map((tailor) {
                    return DropdownMenuItem(value: tailor, child: Text(tailor.fullName));
                  }).toList(),
                  onChanged: (tailor) => setState(() => _selectedTailor = tailor),
                );
              }),

              const SizedBox(height: AppSpacing.lg),

              // Mesures — réservées aux plans qui incluent hasSavedMeasurements
              Text('Mesures (optionnel)', style: AppTextStyles.titleSm),
              const SizedBox(height: AppSpacing.sm),
              if (!permissions.hasSavedMeasurements)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(children: [
                    Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        permissions.measurementsLockedMessage,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.tertiary),
                      ),
                    ),
                  ]),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _epauleController,
                        decoration: const InputDecoration(labelText: 'Épaule (cm)', suffixText: 'cm'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _poitrineController,
                        decoration: const InputDecoration(labelText: 'Poitrine (cm)', suffixText: 'cm'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tailleController,
                        decoration: const InputDecoration(labelText: 'Taille (cm)', suffixText: 'cm'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _hancheController,
                        decoration: const InputDecoration(labelText: 'Hanche (cm)', suffixText: 'cm'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _longueurController,
                  decoration: const InputDecoration(labelText: 'Longueur (cm)', suffixText: 'cm'),
                  keyboardType: TextInputType.number,
                ),
                for (final entry in _customMeasurementControllers.entries) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: entry.value,
                    decoration: InputDecoration(labelText: '${entry.key} (cm)', suffixText: 'cm'),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final label = await promptCustomMeasurementLabel(context);
                      if (label == null || _customMeasurementControllers.containsKey(label)) return;
                      await MeasurementFieldsService.instance.addCustomField(widget.user.atelierId!, label);
                      setState(() {
                        _customMeasurementControllers[label] = TextEditingController();
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter une mesure'),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Détails commande
              Text('Détails de la commande', style: AppTextStyles.titleSm),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Prix total (FCFA)', prefixText: 'FCFA '),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _depositController,
                      decoration: const InputDecoration(labelText: 'Acompte (FCFA)', prefixText: 'FCFA '),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _dueDateController,
                decoration: const InputDecoration(
                  labelText: 'Date de livraison',
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'JJ/MM/AAAA',
                ),
                keyboardType: TextInputType.datetime,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Photos — réservées aux plans qui incluent au moins 1 photo/commande
              Text('Photos (optionnel)', style: AppTextStyles.titleSm),
              const SizedBox(height: AppSpacing.sm),
              if (!permissions.canAddPhoto(0))
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(children: [
                    Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        permissions.photosLockedMessage,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.tertiary),
                      ),
                    ),
                  ]),
                )
              else ...[
                PhotoPickerSection(
                  label: 'Photos du modèle',
                  photos: _modelPhotos,
                  remainingSlots: permissions.isUnlimitedPhotos
                      ? null
                      : permissions.maxPhotosPerOrder - _modelPhotos.length - _fabricPhotos.length,
                  onAdd: (picked) => setState(() => _modelPhotos.addAll(picked)),
                  onRemove: (file) => setState(() => _modelPhotos.remove(file)),
                ),
                const SizedBox(height: AppSpacing.sm),
                PhotoPickerSection(
                  label: 'Photos du tissu',
                  photos: _fabricPhotos,
                  remainingSlots: permissions.isUnlimitedPhotos
                      ? null
                      : permissions.maxPhotosPerOrder - _modelPhotos.length - _fabricPhotos.length,
                  onAdd: (picked) => setState(() => _fabricPhotos.addAll(picked)),
                  onRemove: (file) => setState(() => _fabricPhotos.remove(file)),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submit(permissions),
                      child: const Text('Créer la commande'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
