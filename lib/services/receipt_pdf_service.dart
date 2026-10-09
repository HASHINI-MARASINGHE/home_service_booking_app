import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/receipt.dart';
import '../utils/formatters.dart';

/// Renders a [Receipt] as an A4 PDF and hands it to the platform's
/// save/print or share sheet.
class ReceiptPdfService {
  static const _teal = PdfColor.fromInt(0xFF134A96);
  static const _navy = PdfColor.fromInt(0xFF101B2B);
  static const _muted = PdfColor.fromInt(0xFF3F4D5E);
  static const _tint = PdfColor.fromInt(0xFFEEF4FB);

  String fileName(Receipt receipt) =>
      'HomeCare-${receipt.receiptNumber.isEmpty ? receipt.bookingId : receipt.receiptNumber}.pdf';

  /// The built-in PDF fonts are Latin-1 only; swap typographic characters.
  static String _plain(String text) => text
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('•', '-')
      .replaceAll('×', 'x')
      .replaceAll('µ', 'u')
      .replaceAll(RegExp(r'[^\x00-\xFF]'), '');

  Future<Uint8List> build(Receipt receipt) async {
    final doc = pw.Document(
      title: 'Receipt ${receipt.receiptNumber}',
      author: 'HomeCare',
    );
    pw.Widget label(String text) => pw.Text(
      _plain(text).toUpperCase(),
      style: const pw.TextStyle(color: _muted, fontSize: 8, letterSpacing: 1),
    );
    pw.Widget value(String text, {bool bold = false, double size = 11}) =>
        pw.Text(
          _plain(text),
          style: pw.TextStyle(
            color: _navy,
            fontSize: size,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        );
    final date = receipt.serviceDate ?? receipt.issuedAt;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'HomeCare',
                  style: pw.TextStyle(
                    color: _teal,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    label('Receipt no.'),
                    value(receipt.receiptNumber, bold: true, size: 14),
                    pw.SizedBox(height: 4),
                    label('Booking ref'),
                    value('#${receipt.bookingReference}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            if (receipt.signedOffAt != null)
              value(
                'Job completed and signed off on '
                '${Formatters.shortDate(receipt.signedOffAt!)}, '
                '${Formatters.clock(receipt.signedOffAt!)}',
                size: 10,
              ),
            pw.Divider(color: _tint, thickness: 2, height: 28),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      label('Service provider'),
                      value(receipt.providerName, bold: true),
                      value(receipt.providerTitle, size: 10),
                      if (receipt.licenseNumber.isNotEmpty)
                        value('Licence ${receipt.licenseNumber}', size: 10),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      label('Billed & serviced at'),
                      value(receipt.customerName, bold: true),
                      value(receipt.serviceAddress, size: 10),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      label('Service date'),
                      if (date != null) value(Formatters.shortDate(date)),
                      if (receipt.startTime.isNotEmpty)
                        value(
                          Formatters.timeRange(
                            receipt.startTime,
                            receipt.endTime,
                          ),
                          size: 10,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Details', 'Amount'],
              data: [
                for (final item in receipt.lineItems)
                  [
                    _plain(item.label),
                    _plain(item.detail),
                    Formatters.lkr(item.amount),
                  ],
              ],
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: _teal),
              cellStyle: const pw.TextStyle(color: _navy, fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
              },
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(2),
              },
              border: null,
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _tint)),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              color: _tint,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  value('Total paid', bold: true, size: 13),
                  pw.Text(
                    Formatters.lkr(receipt.totalAmount),
                    style: pw.TextStyle(
                      color: _teal,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            label('Payment'),
            value(
              [
                receipt.paymentMethod.toUpperCase(),
                if (receipt.cardLast4 != null) 'ending in ${receipt.cardLast4}',
                if (receipt.paymentStatus.isNotEmpty)
                  '(${receipt.paymentStatus})',
              ].join(' '),
            ),
            if (receipt.paymentNote.isNotEmpty)
              value(receipt.paymentNote, size: 10),
            pw.Spacer(),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: receipt.verificationPayload,
                  width: 80,
                  height: 80,
                  color: _navy,
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Text(
                    'Scan to verify this receipt with HomeCare. '
                    'Keep it for your warranty and records.',
                    style: const pw.TextStyle(color: _muted, fontSize: 9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Opens the system print / "Save as PDF" dialog.
  Future<void> download(Receipt receipt) async {
    final bytes = await build(receipt);
    await Printing.layoutPdf(
      name: fileName(receipt),
      onLayout: (_) async => bytes,
    );
  }

  Future<void> share(Receipt receipt) async {
    final bytes = await build(receipt);
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName(receipt),
      subject: 'HomeCare receipt ${receipt.receiptNumber}',
    );
  }
}
