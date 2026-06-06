// lib/screens/aeps/aeps_receipt_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class AepsReceiptScreen extends StatefulWidget {
  final String txnRefId;
  final Map<String, dynamic> transactionData;

  const AepsReceiptScreen({
    Key? key,
    required this.txnRefId,
    required this.transactionData,
  }) : super(key: key);

  @override
  State<AepsReceiptScreen> createState() => _AepsReceiptScreenState();
}

class _AepsReceiptScreenState extends State<AepsReceiptScreen> {
  bool _isSaving = false;

  String get _txnTypeLabel {
    final t = (widget.transactionData['transactionType'] ?? '').toString();
    switch (t.toUpperCase()) {
      case 'CASH_WITHDRAWAL': return 'Cash Withdrawal';
      case 'BALANCE_ENQUIRY': return 'Balance Enquiry';
      case 'MINI_STATEMENT':  return 'Mini Statement';
      default: return 'AEPS Transaction';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PDF Generation
  // ─────────────────────────────────────────────────────────────
  Future<Uint8List> _generatePdf() async {
    final pdf  = pw.Document();
    final tx   = widget.transactionData;

    // Load logo from assets
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/logo_white.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    // Receipt-sized page: ~80mm wide thermal receipt style
    final receiptFormat = PdfPageFormat(
      226 * PdfPageFormat.point, // 80mm ≈ 226pt
      double.infinity,
      marginAll: 12 * PdfPageFormat.point,
    );

    // Color theme
    const primaryColor  = PdfColor.fromInt(0xFF0D6B4F);
    const accentColor   = PdfColor.fromInt(0xFF1A9970);
    const darkText      = PdfColor.fromInt(0xFF1A1A1A);
    const greyText      = PdfColor.fromInt(0xFF6B7280);

    pdf.addPage(
      pw.Page(
        pageFormat: receiptFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ── Header ────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: const pw.BoxDecoration(color: primaryColor),
                child: pw.Column(
                  children: [
                    if (logoImage != null)
                      pw.Image(logoImage, width: 90, height: 30, fit: pw.BoxFit.contain)
                    else
                      pw.Text('NEOFYN BHARATH',
                        style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorised AEPS Service Point',
                      style:  pw.TextStyle(fontSize: 8, color: PdfColors.white)),
                    pw.Text('AEPS Transaction Receipt',
                      style:  pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // ── Status Badge ──────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFECFDF5),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('✓ TRANSACTION SUCCESSFUL',
                      style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor,
                      )),
                    pw.SizedBox(height: 4),
                    pw.Text(_txnTypeLabel,
                      style: const pw.TextStyle(fontSize: 9, color: greyText)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // ── Amount (only for Cash Withdrawal) ─────────────
              if (tx['amount'] != null) ...[
                pw.Text('₹${tx['amount']}',
                  style: pw.TextStyle(
                    fontSize: 32, fontWeight: pw.FontWeight.bold, color: primaryColor,
                  )),
                pw.SizedBox(height: 2),
                pw.Text('Amount Withdrawn',
                  style: const pw.TextStyle(fontSize: 9, color: greyText)),
                pw.SizedBox(height: 14),
              ],

              // ── Dashed Divider ─────────────────────────────────
              pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.5),
              pw.SizedBox(height: 10),

              // ── Transaction Details ────────────────────────────
              _pdfSectionTitle('Transaction Details', primaryColor),
              pw.SizedBox(height: 6),
              _pdfRow('Ref ID',     tx['txnRefId'] ?? tx['merchantRefId'] ?? 'N/A', darkText, greyText),
              _pdfRow('RRN',        tx['rrn'] ?? 'N/A',                             darkText, greyText),
              _pdfRow('STAN',       tx['stan'] ?? 'N/A',                            darkText, greyText),
              _pdfRow('Date/Time',  _formatDate(tx['createdAt'] ?? tx['timestamp']), darkText, greyText),
              _pdfRow('Status',     'SUCCESS',                                       primaryColor, greyText),

              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.5),
              pw.SizedBox(height: 10),

              // ── Customer Details ───────────────────────────────
              _pdfSectionTitle('Customer Details', primaryColor),
              pw.SizedBox(height: 6),
              _pdfRow('Aadhaar',    _maskAadhaar(tx['aadhaarLast4'] ?? tx['maskedAadhaar']), darkText, greyText),
              _pdfRow('Bank',       tx['bankName'] ?? tx['bankIin'] ?? 'N/A',                darkText, greyText),
              _pdfRow('Mobile',     tx['mobileNumber'] ?? tx['mobile'] ?? 'N/A',             darkText, greyText),

              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.5),
              pw.SizedBox(height: 10),

              // ── Agent Details ──────────────────────────────────
              _pdfSectionTitle('Agent Details', primaryColor),
              pw.SizedBox(height: 6),
              _pdfRow('Merchant ID', tx['merchantId'] ?? 'N/A', darkText, greyText),
              _pdfRow('Terminal ID', tx['terminalId'] ?? 'N/A', darkText, greyText),

              pw.SizedBox(height: 14),
              pw.Divider(borderStyle: pw.BorderStyle.dashed, thickness: 0.5),
              pw.SizedBox(height: 10),

              // ── Footer ────────────────────────────────────────
              pw.Text('This is a computer generated receipt',
                style: const pw.TextStyle(fontSize: 7, color: greyText)),
              pw.Text('No signature required',
                style: const pw.TextStyle(fontSize: 7, color: greyText)),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text('NEOFYN BHARATH',
                  style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold, color: accentColor,
                  )),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfSectionTitle(String title, PdfColor color) {
    return pw.Align(
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(title,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
    );
  }

  pw.Widget _pdfRow(String label, String value, PdfColor valueColor, PdfColor labelColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: labelColor)),
          pw.Flexible(
            child: pw.Text(value,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: valueColor),
              textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Download / Share
  // ─────────────────────────────────────────────────────────────
  Future<void> _downloadPdf() async {
    setState(() => _isSaving = true);
    try {
      final bytes    = await _generatePdf();
      final fileName = 'AEPS_Receipt_${widget.txnRefId}.pdf';

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final file = File('${dir!.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt saved: $fileName'),
            backgroundColor: const Color(0xFF0D6B4F),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => Printing.sharePdf(bytes: bytes, filename: fileName),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sharePdf() async {
    final bytes = await _generatePdf();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'AEPS_Receipt_${widget.txnRefId}.pdf',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('AEPS Receipt'),
        backgroundColor: const Color(0xFF0D6B4F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _sharePdf,
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── On-screen Receipt Card ─────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Header strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D6B4F), Color(0xFF1A9970)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        // Logo
                        Image.asset(
                          'assets/logo_white.png',
                          height: 40,
                          errorBuilder: (_, __, ___) => const Text(
                            'NEOFYN BHARATH',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Authorised AEPS Service Point',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Success badge
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D6B4F).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, color: Color(0xFF0D6B4F), size: 40),
                        ),
                        const SizedBox(height: 10),
                        const Text('TRANSACTION SUCCESSFUL',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D6B4F))),
                        const SizedBox(height: 4),
                        Text(_txnTypeLabel,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),

                  // Amount (cash withdrawal only)
                  if (widget.transactionData['amount'] != null) ...[
                    Text(
                      '₹${widget.transactionData['amount']}',
                      style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0D6B4F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Amount', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                  ],

                  // Divider
                  _dashedDivider(),
                  const SizedBox(height: 16),

                  // Detail rows
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('TRANSACTION DETAILS'),
                        const SizedBox(height: 8),
                        _uiRow('Reference ID', widget.transactionData['txnRefId'] ?? widget.transactionData['merchantRefId'] ?? 'N/A', copyable: true),
                        _uiRow('RRN',          widget.transactionData['rrn'] ?? 'N/A'),
                        _uiRow('STAN',         widget.transactionData['stan'] ?? 'N/A'),
                        _uiRow('Date & Time',  _formatDate(widget.transactionData['createdAt'] ?? widget.transactionData['timestamp'])),
                        _uiRow('Status',       'SUCCESS', isSuccess: true),

                        const SizedBox(height: 16),
                        _dashedDivider(),
                        const SizedBox(height: 16),

                        _sectionLabel('CUSTOMER DETAILS'),
                        const SizedBox(height: 8),
                        _uiRow('Aadhaar',   _maskAadhaar(widget.transactionData['aadhaarLast4'] ?? widget.transactionData['maskedAadhaar'])),
                        _uiRow('Bank',      widget.transactionData['bankName'] ?? widget.transactionData['bankIin'] ?? 'N/A'),
                        _uiRow('Mobile',    widget.transactionData['mobileNumber'] ?? widget.transactionData['mobile'] ?? 'N/A'),

                        const SizedBox(height: 16),
                        _dashedDivider(),
                        const SizedBox(height: 16),

                        _sectionLabel('AGENT DETAILS'),
                        const SizedBox(height: 8),
                        _uiRow('Merchant ID', widget.transactionData['merchantId'] ?? 'N/A'),
                        _uiRow('Terminal ID', widget.transactionData['terminalId'] ?? 'N/A'),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0FAF5),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        const Text('Computer Generated Receipt · No Signature Required',
                          style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        const Text('NEOFYN BHARATH',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D6B4F))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action Buttons ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Printing.layoutPdf(onLayout: (_) => _generatePdf()),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6B4F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _downloadPdf,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Save PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A9970),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(builder: (context, constraints) {
      final count = (constraints.maxWidth / 6).floor();
      return Row(
        children: List.generate(count, (i) => Expanded(
          child: Container(
            height: 1,
            color: i % 2 == 0 ? Colors.grey.shade300 : Colors.transparent,
          ),
        )),
      );
    });
  }

  Widget _sectionLabel(String label) {
    return Text(label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0D6B4F), letterSpacing: 1.2));
  }

  Widget _uiRow(String label, String value, {bool copyable = false, bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: isSuccess
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6B4F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('SUCCESS',
                      style: TextStyle(color: Color(0xFF0D6B4F), fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(value,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                      ),
                      if (copyable)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: value));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                            );
                          },
                          child: const Icon(Icons.copy, size: 14, color: Color(0xFF0D6B4F)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _maskAadhaar(dynamic raw) {
    if (raw == null) return 'XXXX XXXX XXXX';
    final s = raw.toString();
    if (s.length == 4) return 'XXXX XXXX $s';
    if (s.contains('X') || s.contains('*')) return s;
    return s;
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return dateTime.toString();
    }
  }
}