import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/build_context_colors.dart';
import '../../../core/utils/firebase_error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/measurement_field_prompt.dart';
import '../../../core/utils/plan_permissions.dart';
import '../../../models/app_user.dart';
import '../../../models/client.dart';
import '../../../models/order.dart';
import '../../../services/company_service.dart';
import '../../../services/image_payload_service.dart';
import '../../../services/measurement_fields_service.dart';
import '../../../services/order_service.dart';
import 'order_list_widgets.dart';

typedef CreateOrderResult = ({
  Order order,
  bool isNewClient,
  Client? existingClient,
});

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
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final String _idempotencyKey = const Uuid().v4();
  AppUser? _selectedTailor;
  final List<XFile> _modelPhotos = [];
  final List<XFile> _fabricPhotos = [];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();

  final _epauleController = TextEditingController();
  final _poitrineController = TextEditingController();
  final _tailleController = TextEditingController();
  final _hancheController = TextEditingController();
  final _longueurController = TextEditingController();
  static const _standardMeasurementKeys = {
    'epaule',
    'poitrine',
    'taille',
    'hanche',
    'longueur',
  };

  /// Client retrouvé par téléphone / nom : sert uniquement à pré-remplir la
  /// fiche et à afficher un bandeau de confirmation. La commande reste liée à
  /// ce client via OrderService.createOrder (recherche serveur par téléphone).
  Client? _matchedClient;

  DateTime? _dueDate;

  late final Map<String, TextEditingController> _customMeasurementControllers =
      {
        for (final label in MeasurementFieldsService.instance.customFieldsFor(
          widget.user.atelierId!,
        ))
          label: TextEditingController(),
      };

  @override
  void initState() {
    super.initState();
    // Recalcule le résumé (total / acompte / reste à payer) à chaque frappe.
    _priceController.addListener(_refreshTotals);
    _depositController.addListener(_refreshTotals);
  }

  void _refreshTotals() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
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

  int? get _price => int.tryParse(_priceController.text.trim());
  int? get _deposit => int.tryParse(_depositController.text.trim());
  int? get _balance {
    final price = _price;
    if (price == null) return null;
    final deposit = _deposit ?? 0;
    return (price - deposit).clamp(0, price);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _searchExistingClient(PlanPermissions permissions) {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    if (phone.isEmpty && name.isEmpty) {
      _showMessage("Saisissez d'abord un téléphone ou un nom pour rechercher.");
      return;
    }

    final atelierId = widget.user.atelierId!;
    Client? existing;
    if (phone.isNotEmpty) {
      existing = OrderService.instance.findClientByPhone(phone, atelierId);
    }
    if (existing == null && name.isNotEmpty) {
      existing = OrderService.instance.findClientByName(name, atelierId);
    }

    if (existing == null) {
      setState(() => _matchedClient = null);
      _showMessage(
        'Aucun client trouvé. La commande créera une nouvelle fiche.',
      );
      return;
    }

    final saved = existing.savedMeasurements;
    final canPrefill =
        permissions.hasSavedMeasurements && saved != null && saved.isNotEmpty;

    setState(() {
      _matchedClient = existing;
      _nameController.text = existing!.fullName;
      _phoneController.text = existing.phone;
      if (existing.email != null && existing.email!.isNotEmpty) {
        _emailController.text = existing.email!;
      }
      if (canPrefill) {
        if (saved['epaule'] != null) {
          _epauleController.text = saved['epaule'].toString();
        }
        if (saved['poitrine'] != null) {
          _poitrineController.text = saved['poitrine'].toString();
        }
        if (saved['taille'] != null) {
          _tailleController.text = saved['taille'].toString();
        }
        if (saved['hanche'] != null) {
          _hancheController.text = saved['hanche'].toString();
        }
        if (saved['longueur'] != null) {
          _longueurController.text = saved['longueur'].toString();
        }
        // Mesures personnalisées déjà enregistrées pour ce client.
        for (final entry in saved.entries) {
          if (!_standardMeasurementKeys.contains(entry.key)) {
            _customMeasurementControllers
                .putIfAbsent(entry.key, () => TextEditingController())
                .text = entry.value
                .toString();
          }
        }
      }
    });

    _showMessage(
      canPrefill
          ? 'Client retrouvé : ${existing.fullName} — mesures pré-remplies.'
          : 'Client retrouvé : ${existing.fullName}.',
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5, 12, 31),
      locale: const Locale('fr'),
      helpText: 'Date de livraison',
      cancelText: 'Annuler',
      confirmText: 'Choisir',
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _submit(PlanPermissions permissions) async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    final price = _price;
    final deposit = _deposit;
    if (price != null && deposit != null && deposit > price) {
      _showMessage("L'acompte ne peut pas dépasser le prix total.");
      return;
    }

    // Validation des mesures AVANT tout envoi. Une saisie avec une virgule
    // décimale (« 92,5 ») est acceptée, mais tout le reste doit être un
    // nombre positif : sinon une mesure à 0 cm partait chez le couturier.
    (bool, double?) parseMeasurement(String raw) {
      final text = raw.trim().replaceAll(',', '.');
      if (text.isEmpty) return (true, null);
      final value = double.tryParse(text);
      if (value == null || value <= 0) return (false, null);
      return (true, value);
    }

    final measurementInputs = <String, double>{};
    if (permissions.hasSavedMeasurements) {
      final rawInputs = <String, String>{
        'epaule': _epauleController.text,
        'poitrine': _poitrineController.text,
        'taille': _tailleController.text,
        'hanche': _hancheController.text,
        'longueur': _longueurController.text,
        for (final entry in _customMeasurementControllers.entries)
          entry.key: entry.value.text,
      };
      for (final entry in rawInputs.entries) {
        final (isValid, value) = parseMeasurement(entry.value);
        if (!isValid) {
          _showMessage(
            'Mesure « ${entry.key} » invalide : indiquez un nombre en cm.',
          );
          return;
        }
        if (value != null) measurementInputs[entry.key] = value;
      }
    }
    final measurements = measurementInputs.isEmpty ? null : measurementInputs;

    setState(() => _isSubmitting = true);

    try {
      // Les photos sont envoyées AVANT la création de la commande : le
      // document doit contenir des références affichables partout (URL
      // Storage, ou data-URL base64 en repli), jamais un chemin local qui ne
      // désignerait un fichier que sur cet appareil.
      final (modelPhotos, fabricPhotos) = await _storePhotos();

      final result = await OrderService.instance.createOrder(
        clientName: _nameController.text.trim(),
        clientPhone: _phoneController.text.trim(),
        clientEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        tailorId: _selectedTailor?.id,
        atelierId: widget.user.atelierId!,
        atelierName: widget.user.atelierName!,
        measurements: measurements,
        modelPhotos: modelPhotos.isEmpty ? null : modelPhotos,
        fabricPhotos: fabricPhotos.isEmpty ? null : fabricPhotos,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        deposit: deposit,
        dueDate: _dueDate,
        createdByName: widget.user.fullName,
        idempotencyKey: _idempotencyKey,
      );

      if (!mounted) return;
      Navigator.pop(context, result);
    } on ImagePayloadException catch (e) {
      // Message déjà rédigé pour l'utilisateur : surtout ne pas le passer par
      // friendlyFirebaseError, qui le remplacerait par un texte générique.
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(friendlyFirebaseError(e));
    }
  }

  /// Envoie les photos choisies et retourne les références à enregistrer dans
  /// la commande : URL Firebase Storage, ou data-URL base64 quand Storage est
  /// indisponible (voir ImagePayloadService).
  ///
  /// Le budget de taille ne s'applique qu'au repli base64 : les photos vivent
  /// alors dans le document `orders/{id}`, plafonné à 1 Mio par Firestore.
  /// Avec Storage, chaque photo a son propre fichier et aucune limite de ce
  /// type ne s'applique.
  Future<(List<String>, List<String>)> _storePhotos() async {
    final atelierId = widget.user.atelierId!;
    var budget = ImagePayloadService.maxOrderPhotosLength;

    Future<List<String>> store(List<XFile> files, String kind) async {
      final refs = <String>[];
      for (var i = 0; i < files.length; i++) {
        final value = await ImagePayloadService.store(
          // L'idempotencyKey évite d'écraser les photos d'une autre commande
          // créée au même instant dans le même atelier.
          storagePath:
              'order_photos/$atelierId/${_idempotencyKey}_${kind}_$i.jpg',
          file: files[i],
        );
        if (ImagePayloadService.isDataUrl(value)) {
          budget -= value.length;
          if (budget < 0) {
            throw const ImagePayloadException(
              'Trop de photos (ou photos trop lourdes) pour être enregistrées '
              'sans Firebase Storage. Retirez quelques photos puis réessayez.',
            );
          }
        }
        refs.add(value);
      }
      return refs;
    }

    final modelPhotos = await store(_modelPhotos, 'modele');
    final fabricPhotos = await store(_fabricPhotos, 'tissu');
    return (modelPhotos, fabricPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.user.permissions;
    final c = context.colors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(c),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildClientSection(c, permissions),
                      const SizedBox(height: AppSpacing.md),
                      _buildProductionSection(c),
                      const SizedBox(height: AppSpacing.md),
                      _buildMeasurementsSection(c, permissions),
                      const SizedBox(height: AppSpacing.md),
                      _buildBudgetSection(c),
                      const SizedBox(height: AppSpacing.md),
                      _buildDeadlineSection(c),
                      const SizedBox(height: AppSpacing.md),
                      _buildPhotosSection(c, permissions),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(c, permissions),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorPalette c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: c.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_shopping_cart_rounded,
              color: c.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle commande',
                  style: AppTextStyles.titleMd.copyWith(color: c.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fiche client, mesures, budget et photos au même endroit.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close_rounded),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection(AppColorPalette c, PlanPermissions permissions) {
    return _SectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Client',
      subtitle:
          'Recherchez une fiche existante ou créez-en une automatiquement.',
      children: [
        _DialogField(
          controller: _nameController,
          label: 'Nom complet *',
          hint: 'Ex. Aïcha Traoré',
          icon: Icons.badge_outlined,
          textInputAction: TextInputAction.next,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Le nom est obligatoire.'
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _DialogField(
          controller: _phoneController,
          label: 'Téléphone *',
          hint: '70 00 00 00',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Le téléphone est obligatoire.'
              : null,
          onChanged: (value) {
            final matched = _matchedClient;
            if (matched != null && value.trim() != matched.phone) {
              setState(() => _matchedClient = null);
            }
          },
          suffix: IconButton(
            tooltip: 'Rechercher ce client',
            icon: const Icon(Icons.search_rounded, size: 20),
            onPressed: () => _searchExistingClient(permissions),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DialogField(
          controller: _emailController,
          label: 'Email (optionnel)',
          hint: 'client@email.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        if (_matchedClient != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _ExistingClientBanner(client: _matchedClient!),
        ],
      ],
    );
  }

  Widget _buildProductionSection(AppColorPalette c) {
    final tailors = CompanyService.instance.tailorsOfAtelier(
      widget.user.atelierId!,
    );
    return _SectionCard(
      icon: Icons.content_cut_rounded,
      title: 'Production',
      subtitle: 'Assignez la commande et décrivez le modèle attendu.',
      children: [
        if (tailors.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: c.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: c.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aucun couturier disponible pour le moment.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<AppUser>(
            initialValue: _selectedTailor,
            decoration: const InputDecoration(
              labelText: 'Couturier (optionnel)',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            items: tailors
                .map(
                  (tailor) => DropdownMenuItem(
                    value: tailor,
                    child: Text(tailor.fullName),
                  ),
                )
                .toList(),
            onChanged: (tailor) => setState(() => _selectedTailor = tailor),
          ),
        const SizedBox(height: AppSpacing.sm),
        _DialogField(
          controller: _descriptionController,
          label: 'Description du modèle',
          hint: 'Couleur, tissu, coupe, détails…',
          icon: Icons.description_outlined,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }

  Widget _buildMeasurementsSection(
    AppColorPalette c,
    PlanPermissions permissions,
  ) {
    if (!permissions.hasSavedMeasurements) {
      return _SectionCard(
        icon: Icons.straighten_rounded,
        title: 'Mesures',
        children: [
          _LockedInfo(
            message: permissions.measurementsLockedMessage,
            color: c.tertiary,
          ),
        ],
      );
    }

    return _SectionCard(
      icon: Icons.straighten_rounded,
      title: 'Mesures',
      subtitle: 'En centimètres — un champ vide est simplement ignoré.',
      children: [
        Row(
          children: [
            Expanded(
              child: _MeasurementField(
                controller: _epauleController,
                label: 'Épaule',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MeasurementField(
                controller: _poitrineController,
                label: 'Poitrine',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MeasurementField(
                controller: _tailleController,
                label: 'Taille',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MeasurementField(
                controller: _hancheController,
                label: 'Hanche',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _MeasurementField(controller: _longueurController, label: 'Longueur'),
        for (final entry in _customMeasurementControllers.entries) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MeasurementField(
                  controller: entry.value,
                  label: entry.key,
                ),
              ),
              IconButton(
                tooltip: 'Supprimer ce champ',
                onPressed: () async {
                  // Retire aussi du catalogue de l'atelier — même symétrie
                  // que le bouton « Ajouter une mesure ».
                  await MeasurementFieldsService.instance.removeCustomField(
                    widget.user.atelierId!,
                    entry.key,
                  );
                  setState(() {
                    _customMeasurementControllers.remove(entry.key)?.dispose();
                  });
                },
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final label = await promptCustomMeasurementLabel(context);
              if (label == null ||
                  _customMeasurementControllers.containsKey(label)) {
                return;
              }
              await MeasurementFieldsService.instance.addCustomField(
                widget.user.atelierId!,
                label,
              );
              setState(() {
                _customMeasurementControllers[label] = TextEditingController();
              });
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ajouter une mesure'),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection(AppColorPalette c) {
    return _SectionCard(
      icon: Icons.payments_outlined,
      title: 'Budget',
      subtitle: 'Le reste à payer est calculé automatiquement.',
      children: [
        Row(
          children: [
            Expanded(
              child: _DialogField(
                controller: _priceController,
                label: 'Prix total (${AppConstants.currency})',
                hint: '50 000',
                icon: Icons.sell_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _DialogField(
                controller: _depositController,
                label: 'Acompte (${AppConstants.currency})',
                hint: '20 000',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        if (_price != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: c.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Total',
                  value: Formatters.formatCurrency(_price!),
                ),
                const SizedBox(height: 4),
                _SummaryRow(
                  label: 'Acompte versé',
                  value: Formatters.formatCurrency(_deposit ?? 0),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Divider(
                    height: 1,
                    color: c.primary.withValues(alpha: 0.15),
                  ),
                ),
                _SummaryRow(
                  label: 'Reste à payer',
                  value: Formatters.formatCurrency(_balance ?? 0),
                  emphasized: true,
                  color: c.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeadlineSection(AppColorPalette c) {
    final now = DateTime.now();
    return _SectionCard(
      icon: Icons.event_outlined,
      title: 'Livraison',
      subtitle: 'Choisissez une date pour le rappel automatique.',
      children: [
        InkWell(
          onTap: _pickDueDate,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date de livraison',
              prefixIcon: const Icon(Icons.calendar_month_outlined),
              suffixIcon: _dueDate == null
                  ? const Icon(Icons.keyboard_arrow_down_rounded)
                  : IconButton(
                      tooltip: 'Retirer la date',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
            ),
            child: Text(
              _dueDate == null
                  ? 'Aucune date choisie'
                  : Formatters.date.format(_dueDate!),
              style: AppTextStyles.bodyLg.copyWith(
                color: _dueDate == null ? c.onSurfaceVariant : c.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in const [
              (label: 'Dans 1 semaine', days: 7),
              (label: 'Dans 2 semaines', days: 14),
              (label: 'Dans 1 mois', days: 30),
            ])
              ActionChip(
                label: Text(option.label),
                onPressed: () => setState(
                  () => _dueDate = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).add(Duration(days: option.days)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotosSection(AppColorPalette c, PlanPermissions permissions) {
    if (!permissions.canAddPhoto(0)) {
      return _SectionCard(
        icon: Icons.add_a_photo_outlined,
        title: 'Photos',
        children: [
          _LockedInfo(
            message: permissions.photosLockedMessage,
            color: c.tertiary,
          ),
        ],
      );
    }

    final remaining = permissions.isUnlimitedPhotos
        ? null
        : permissions.maxPhotosPerOrder -
              _modelPhotos.length -
              _fabricPhotos.length;

    return _SectionCard(
      icon: Icons.add_a_photo_outlined,
      title: 'Photos',
      subtitle: remaining == null
          ? 'Photos illimitées avec votre formule.'
          : '$remaining emplacement(s) restant(s) pour cette commande.',
      children: [
        PhotoPickerSection(
          label: 'Photos du modèle',
          photos: _modelPhotos,
          remainingSlots: remaining,
          onAdd: (picked) => setState(() => _modelPhotos.addAll(picked)),
          onRemove: (file) => setState(() => _modelPhotos.remove(file)),
        ),
        const SizedBox(height: AppSpacing.sm),
        PhotoPickerSection(
          label: 'Photos du tissu',
          photos: _fabricPhotos,
          remainingSlots: remaining,
          onAdd: (picked) => setState(() => _fabricPhotos.addAll(picked)),
          onRemove: (file) => setState(() => _fabricPhotos.remove(file)),
        ),
      ],
    );
  }

  Widget _buildFooter(AppColorPalette c, PlanPermissions permissions) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: c.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _submit(permissions),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(_isSubmitting ? 'Création…' : 'Créer la commande'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de section du formulaire : une icône, un titre et un contenu
/// regroupés visuellement, pour que la fiche reste lisible même avec beaucoup
/// de champs.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: c.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: c.primary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSm.copyWith(color: c.onSurface),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: AppTextStyles.bodySm.copyWith(
                color: c.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

/// Champ de formulaire compact et homogène (icône, label, hint).
class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        suffixIcon: suffix,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: 'cm'),
    );
  }
}

class _LockedInfo extends StatelessWidget {
  const _LockedInfo({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingClientBanner extends StatelessWidget {
  const _ExistingClientBanner({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: c.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, size: 18, color: c.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Client existant : ${client.fullName}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${client.orderCount} commande(s) · ${client.phone}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = emphasized
        ? AppTextStyles.titleSm.copyWith(color: color ?? c.primary)
        : AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant);
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}
