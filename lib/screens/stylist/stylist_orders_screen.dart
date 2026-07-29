import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/order_pdf.dart';
import '../../core/utils/plan_guard.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';
import '../../services/order_service.dart';

class StylistOrdersScreen extends StatefulWidget {
  const StylistOrdersScreen({super.key});

  @override
  State<StylistOrdersScreen> createState() => _StylistOrdersScreenState();
}

class _StylistOrdersScreenState extends State<StylistOrdersScreen> {
  OrderStatus? _selectedStatus;
  AppUser? _selectedTailor;
  final List<XFile> _modelPhotos = [];
  final List<XFile> _fabricPhotos = [];

  List<Order> _getFilteredOrders(String atelierId) {
    final orders = OrderService.instance.ordersOfAtelier(atelierId);
    if (_selectedStatus == null) return orders;
    return orders.where((o) => o.status == _selectedStatus).toList();
  }

  void _showCreateOrderDialog() {
    final user = context.read<AuthProvider>().user!;
    final permissions = user.permissions;
    final currentOrders = OrderService.instance.ordersOfAtelier(user.atelierId!).length;
    
    // Vérifier si l'utilisateur peut créer des commandes
    if (!permissions.canAddOrder(currentOrders)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limite atteinte'),
          content: Text(permissions.canAddOrderMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Repart d'une liste de photos vide à chaque ouverture du dialogue
    // (sinon des photos annulées resteraient accrochées à la prochaine commande).
    _modelPhotos.clear();
    _fabricPhotos.clear();

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final depositController = TextEditingController();
    final dueDateController = TextEditingController();

    // Mesures
    final epauleController = TextEditingController();
    final poitrineController = TextEditingController();
    final tailleController = TextEditingController();
    final hancheController = TextEditingController();
    final longueurController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                      Text(
                        'Nouvelle commande',
                        style: AppTextStyles.headlineMd,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // Infos client
                  Text(
                    'Informations client',
                    style: AppTextStyles.titleSm,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du client *',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone *',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (optionnel)',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Assignation de couturier
                  Text(
                    'Assigner à un couturier (optionnel)',
                    style: AppTextStyles.titleSm,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FutureBuilder<List<AppUser>>(
                    future: Future.value(CompanyService.instance.tailorsOfAtelier(context.read<AuthProvider>().user!.atelierId!)),
                    builder: (context, snapshot) {
                      final tailors = snapshot.data ?? [];
                      if (tailors.isEmpty) {
                        return Text(
                          'Aucun couturier disponible',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        );
                      }
                      return DropdownButtonFormField<AppUser>(
                        decoration: const InputDecoration(
                          labelText: 'Couturier',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        initialValue: _selectedTailor,
                        items: tailors.map((tailor) {
                          return DropdownMenuItem(
                            value: tailor,
                            child: Text(tailor.fullName),
                          );
                        }).toList(),
                        onChanged: (tailor) {
                          setDialogState(() {
                            _selectedTailor = tailor;
                          });
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),

                  // Mesures — réservées aux plans qui incluent hasSavedMeasurements
                  Text(
                    'Mesures (optionnel)',
                    style: AppTextStyles.titleSm,
                  ),
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
                            controller: epauleController,
                            decoration: const InputDecoration(
                              labelText: 'Épaule (cm)',
                              suffixText: 'cm',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: poitrineController,
                            decoration: const InputDecoration(
                              labelText: 'Poitrine (cm)',
                              suffixText: 'cm',
                            ),
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
                            controller: tailleController,
                            decoration: const InputDecoration(
                              labelText: 'Taille (cm)',
                              suffixText: 'cm',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: hancheController,
                            decoration: const InputDecoration(
                              labelText: 'Hanche (cm)',
                              suffixText: 'cm',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: longueurController,
                      decoration: const InputDecoration(
                        labelText: 'Longueur (cm)',
                        suffixText: 'cm',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  
                  // Détails commande
                  Text(
                    'Détails de la commande',
                    style: AppTextStyles.titleSm,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: descriptionController,
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
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Prix total (FCFA)',
                            prefixText: 'FCFA ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: depositController,
                          decoration: const InputDecoration(
                            labelText: 'Acompte (FCFA)',
                            prefixText: 'FCFA ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: dueDateController,
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
                    _PhotoPickerSection(
                      label: 'Photos du modèle',
                      photos: _modelPhotos,
                      remainingSlots: permissions.isUnlimitedPhotos
                          ? null
                          : permissions.maxPhotosPerOrder - _modelPhotos.length - _fabricPhotos.length,
                      onAdd: (picked) => setDialogState(() => _modelPhotos.addAll(picked)),
                      onRemove: (file) => setDialogState(() => _modelPhotos.remove(file)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PhotoPickerSection(
                      label: 'Photos du tissu',
                      photos: _fabricPhotos,
                      remainingSlots: permissions.isUnlimitedPhotos
                          ? null
                          : permissions.maxPhotosPerOrder - _modelPhotos.length - _fabricPhotos.length,
                      onAdd: (picked) => setDialogState(() => _fabricPhotos.addAll(picked)),
                      onRemove: (file) => setDialogState(() => _fabricPhotos.remove(file)),
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
                          onPressed: () {
                            if (nameController.text.trim().isEmpty ||
                                phoneController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Veuillez remplir le nom et le téléphone'),
                                ),
                              );
                              return;
                            }
                            
                            final user = context.read<AuthProvider>().user!;
                            
                            // Parser les mesures (seulement si le plan le permet)
                            Map<String, double>? measurements;
                            if (permissions.hasSavedMeasurements && (
                                epauleController.text.isNotEmpty ||
                                poitrineController.text.isNotEmpty ||
                                tailleController.text.isNotEmpty ||
                                hancheController.text.isNotEmpty ||
                                longueurController.text.isNotEmpty)) {
                              measurements = {};
                              if (epauleController.text.isNotEmpty) {
                                measurements['epaule'] = double.tryParse(epauleController.text) ?? 0;
                              }
                              if (poitrineController.text.isNotEmpty) {
                                measurements['poitrine'] = double.tryParse(poitrineController.text) ?? 0;
                              }
                              if (tailleController.text.isNotEmpty) {
                                measurements['taille'] = double.tryParse(tailleController.text) ?? 0;
                              }
                              if (hancheController.text.isNotEmpty) {
                                measurements['hanche'] = double.tryParse(hancheController.text) ?? 0;
                              }
                              if (longueurController.text.isNotEmpty) {
                                measurements['longueur'] = double.tryParse(longueurController.text) ?? 0;
                              }
                            }
                            
                            // Parser la date
                            DateTime? dueDate;
                            if (dueDateController.text.isNotEmpty) {
                              // Format simple JJ/MM/AAAA
                              final parts = dueDateController.text.split('/');
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
                            
                            final result = OrderService.instance.createOrder(
                              clientName: nameController.text.trim(),
                              clientPhone: phoneController.text.trim(),
                              clientEmail: emailController.text.trim().isEmpty 
                                  ? null 
                                  : emailController.text.trim(),
                              tailorId: _selectedTailor?.id,
                              atelierId: user.atelierId!,
                              atelierName: user.atelierName!,
                              measurements: measurements,
                              modelPhotos: _modelPhotos.isEmpty ? null : _modelPhotos.map((f) => f.path).toList(),
                              fabricPhotos: _fabricPhotos.isEmpty ? null : _fabricPhotos.map((f) => f.path).toList(),
                              description: descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              price: priceController.text.trim().isEmpty
                                  ? null
                                  : int.tryParse(priceController.text.trim()),
                              deposit: depositController.text.trim().isEmpty
                                  ? null
                                  : int.tryParse(depositController.text.trim()),
                              dueDate: dueDate,
                            );

                            Navigator.pop(context);

                            // Réinitialiser le couturier sélectionné et les photos
                            setState(() {
                              _selectedTailor = null;
                              _modelPhotos.clear();
                              _fabricPhotos.clear();
                            });
                            
                            // Afficher un message selon si le client existait déjà
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.isNewClient
                                      ? 'Commande créée - Nouveau client ajouté'
                                      : 'Commande créée - Client existant réutilisé',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            
                            setState(() {}); // Refresh
                          },
                          child: const Text('Créer la commande'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      'Détails de la commande',
                      style: AppTextStyles.headlineMd,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Client info
                    _Section(
                      title: 'Client',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.clientName,
                            style: AppTextStyles.titleMd,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.clientPhone,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Statut
                    _Section(
                      title: 'Statut',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.statusLabel,
                              style: AppTextStyles.labelCaps.copyWith(
                                color: _getStatusColor(order.status),
                              ),
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<OrderStatus>(
                            value: order.status,
                            items: OrderStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              );
                            }).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                OrderService.instance.updateOrderStatus(order.id, newStatus);
                                Navigator.pop(context);
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Mesures
                    if (order.measurements != null && order.measurements!.isNotEmpty)
                      _Section(
                        title: 'Mesures',
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: order.measurements!.entries.map((entry) {
                            return Chip(
                              label: Text('${entry.key}: ${entry.value}cm'),
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            );
                          }).toList(),
                        ),
                      ),
                    
                    // Description
                    if (order.description != null)
                      _Section(
                        title: 'Description',
                        child: Text(order.description!),
                      ),
                    
                    // Prix
                    if (order.price != null) ...[
                      _Section(
                        title: 'Prix',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Formatters.formatCurrency(order.price!),
                              style: AppTextStyles.headlineSm.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            if (order.deposit != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Acompte: ${Formatters.formatCurrency(order.deposit!)}',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reste: ${Formatters.formatCurrency(order.price! - order.deposit!)}',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    
                    // Date de livraison
                    if (order.dueDate != null)
                      _Section(
                        title: 'Date de livraison',
                        child: Text(Formatters.date.format(order.dueDate!)),
                      ),
                    
                    // Date de création
                    if (order.createdAt != null)
                      _Section(
                        title: 'Créée le',
                        child: Text(Formatters.date.format(order.createdAt!)),
                      ),

                    // Actions — export PDF / devis (plan Pro et plus)
                    _Section(
                      title: 'Documents',
                      child: Builder(builder: (context) {
                        final permissions = context.read<AuthProvider>().user!.permissions;
                        final companyId = context.read<AuthProvider>().user!.companyId;
                        return Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _exportDocument(
                                context,
                                isAllowed: permissions.hasPdfExport,
                                lockedMessage: permissions.pdfExportLockedMessage,
                                generate: () => OrderPdf.shareInvoice(order, companyId: companyId),
                              ),
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                              label: const Text('Exporter PDF'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _exportDocument(
                                context,
                                isAllowed: permissions.hasQuotes,
                                lockedMessage: permissions.quotesLockedMessage,
                                generate: () => OrderPdf.shareQuote(order, companyId: companyId),
                              ),
                              icon: const Icon(Icons.request_quote_outlined, size: 18),
                              label: const Text('Créer un devis'),
                            ),
                          ),
                        ]);
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportDocument(
    BuildContext context, {
    required bool isAllowed,
    required String lockedMessage,
    required Future<void> Function() generate,
  }) {
    if (!PlanGuard.requireFeature(
      context: context,
      isAllowed: isAllowed,
      featureName: 'Documents PDF',
      lockedMessage: lockedMessage,
    )) {
      return;
    }
    generate();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.tertiary;
      case OrderStatus.inProgress:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.secondary;
      case OrderStatus.problem:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final orders = _getFilteredOrders(user.atelierId!);

    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Commandes',
                          style: AppTextStyles.headlineLgMobile,
                        ),
                        const Spacer(),
                        Text(
                          '${orders.length} commande${orders.length > 1 ? 's' : ''}',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Toutes',
                            isSelected: _selectedStatus == null,
                            onTap: () => setState(() => _selectedStatus = null),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ...OrderStatus.values.map((status) {
                            return Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: _FilterChip(
                                label: status.label,
                                isSelected: _selectedStatus == status,
                                onTap: () => setState(() => _selectedStatus = status),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Liste des commandes
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: EmptyState(
                          title: 'Aucune commande',
                          subtitle: _selectedStatus == null
                              ? 'Créez votre première commande'
                              : 'Aucune commande avec ce statut',
                          icon: Icons.receipt_long_outlined,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg).copyWith(bottom: 100),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _OrderCard(
                            order: order,
                            onTap: () => _showOrderDetails(order),
                          ).animate().fadeIn(delay: (index * 50).ms).slideY();
                        },
                      ),
              ),
            ],
          ),
        ),
        // FAB — bottom:92 pour rester au-dessus de la GlassNavBar flottante
        // (voir StylistShell) ; à bottom:20 le bouton était caché SOUS la
        // barre de navigation et donc impossible à toucher.
        Positioned(
          bottom: 92,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: _showCreateOrderDialog,
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.onSecondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.add),
            label: Text('Commande', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSecondary)),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: AppTextStyles.labelCaps.copyWith(
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  initials: order.clientName.split(' ').map((n) => n[0]).take(2).join().toUpperCase(),
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.clientName,
                        style: AppTextStyles.titleMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.clientPhone,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: AppTextStyles.labelXs.copyWith(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (order.description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                order.description!,
                style: AppTextStyles.bodySm,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (order.price != null) ...[
                  Text(
                    Formatters.formatCurrency(order.price!),
                    style: AppTextStyles.titleSm.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (order.createdAt != null)
                  Text(
                    Formatters.date.format(order.createdAt!),
                    style: AppTextStyles.labelXs.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.tertiary;
      case OrderStatus.inProgress:
        return AppColors.primary;
      case OrderStatus.completed:
        return AppColors.secondary;
      case OrderStatus.problem:
        return AppColors.success;
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

// ── Sélecteur de photos (modèle / tissu) ─────────────────────────────────────
// remainingSlots == null signifie "illimité" (plan Entreprise).
class _PhotoPickerSection extends StatelessWidget {
  const _PhotoPickerSection({
    required this.label,
    required this.photos,
    required this.remainingSlots,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<XFile> photos;
  final int? remainingSlots;
  final ValueChanged<List<XFile>> onAdd;
  final ValueChanged<XFile> onRemove;

  Future<void> _pick(BuildContext context) async {
    final limit = remainingSlots;
    if (limit != null && limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limite de photos par commande atteinte pour votre plan')),
      );
      return;
    }
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    onAdd(limit == null ? picked : picked.take(limit).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _pick(context),
            icon: const Icon(Icons.add_a_photo_outlined, size: 16),
            label: const Text('Ajouter'),
          ),
        ]),
        if (photos.isNotEmpty)
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final file = photos[i];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: _XFileThumbnail(file: file, size: 64),
                    ),
                    Positioned(
                      top: -6, right: -6,
                      child: GestureDetector(
                        onTap: () => onRemove(file),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Miniature d'une photo tout juste sélectionnée. Utilise `XFile.readAsBytes`
/// (au lieu de `dart:io File`) car sur le web, `File(path)` plante : le
/// chemin renvoyé par image_picker y est une URL `blob:`, pas un vrai fichier
/// sur disque.
class _XFileThumbnail extends StatelessWidget {
  const _XFileThumbnail({required this.file, required this.size});
  final XFile file;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: size,
            height: size,
            color: AppColors.surfaceContainerLow,
          );
        }
        return Image.memory(snapshot.data!, width: size, height: size, fit: BoxFit.cover);
      },
    );
  }
}
