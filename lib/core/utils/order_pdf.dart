import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/order.dart';
import '../../services/company_customization_service.dart';
import 'formatters.dart';

/// Génère et partage un PDF (facture ou devis) pour une commande —
/// plan Pro et plus (permissions.hasPdfExport / hasQuotes).
///
/// Si le compte est une Entreprise ayant personnalisé sa marque
/// (permissions.hasCustomization), le nom et la couleur choisis sont
/// appliqués à l'en-tête du document généré.
abstract final class OrderPdf {
  static Future<void> shareInvoice(Order order, {String? companyId}) =>
      _generateAndShare(order, title: 'Facture', filenamePrefix: 'commande', companyId: companyId);

  static Future<void> shareQuote(Order order, {String? companyId}) =>
      _generateAndShare(order, title: 'Devis', filenamePrefix: 'devis', companyId: companyId);

  static Future<void> _generateAndShare(
    Order order, {
    required String title,
    required String filenamePrefix,
    String? companyId,
  }) async {
    final branding = await CompanyCustomizationService.instance.brandingFor(companyId);
    final brandName = branding.brandName ?? 'StyleConnect';
    final accent = branding.accentColor == null
        ? PdfColors.indigo
        : PdfColor.fromInt(branding.accentColor!.toARGB32());

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(brandName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: accent)),
                pw.Text(title, style: pw.TextStyle(fontSize: 18, color: accent)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(order.atelierName, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Divider(height: 24),
            pw.Text('Client', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent)),
            pw.SizedBox(height: 4),
            pw.Text(order.clientName),
            pw.Text(order.clientPhone),
            if (order.clientEmail != null) pw.Text(order.clientEmail!),
            pw.SizedBox(height: 16),
            pw.Text('Détails de la commande', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent)),
            pw.SizedBox(height: 4),
            pw.Text(order.description ?? 'Sans description'),
            if (order.dueDate != null) ...[
              pw.SizedBox(height: 4),
              pw.Text('Livraison prévue : ${Formatters.date.format(order.dueDate!)}'),
            ],
            if (order.measurements != null && order.measurements!.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text('Mesures', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent)),
              pw.SizedBox(height: 4),
              pw.Wrap(
                spacing: 12,
                children: order.measurements!.entries
                    .map((e) => pw.Text('${e.key} : ${e.value} cm'))
                    .toList(),
              ),
            ],
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Prix total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(Formatters.formatCurrency(order.price ?? 0)),
              ],
            ),
            if (order.deposit != null) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Acompte versé'),
                  pw.Text(Formatters.formatCurrency(order.deposit!)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Solde restant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent)),
                  pw.Text(Formatters.formatCurrency((order.price ?? 0) - order.deposit!)),
                ],
              ),
            ],
            pw.SizedBox(height: 32),
            pw.Text(
              'Document généré le ${Formatters.date.format(DateTime.now())} — Commande #${order.id}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: '${filenamePrefix}_${order.id}.pdf');
  }
}
