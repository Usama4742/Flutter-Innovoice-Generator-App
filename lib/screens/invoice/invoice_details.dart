import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:innvoice_generator/core/services/pdf_services.dart';
import 'package:innvoice_generator/screens/invoice/edit_invoice.dart';
import 'package:innvoice_generator/widgets/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/invoice_model.dart';
import '../../provider/invoice_provider.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  Invoice? invoice;
  bool isLoading = true;

  // ============================================================
  // COLORS
  // ============================================================

  Color get primaryColor => AppTheme.primaryBlue;

  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get cardColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  Color get fieldColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? const Color(0xFF252525) : const Color(0xFFF8FAFC);
  }

  Color get borderColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE2E8F0);
  }

  Color get secondaryTextColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF64748B);
  }

  Color get softPrimaryColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return primaryColor.withOpacity(isDark ? 0.18 : 0.08);
  }

  Color get mainTextColor {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadInvoice() async {
    final provider = context.read<InvoiceProvider>();

    final result = await provider.getInvoiceById(widget.invoiceId);

    if (!mounted) return;

    setState(() {
      invoice = result;
      isLoading = false;
    });
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteInvoice() async {
    if (invoice?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Delete Invoice',
            style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to delete '
            '${invoice!.invoiceNumber}?',
            style: TextStyle(color: secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await context.read<InvoiceProvider>().deleteInvoice(invoice!.id!);

    if (!mounted) return;

    Navigator.pop(context);
  }

  // ============================================================
  // SHARE
  // ============================================================

  Future<void> _shareInvoice() async {
    if (invoice == null) return;
    try {
      final Uint8List pdfBytes = await InvoicePdfService.generateInvoicePdf(
        invoice!,
      );
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${invoice!.invoiceNumber}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          title: 'Invoice ${invoice!.invoiceNumber}',
          subject: 'Invoice ${invoice!.invoiceNumber}',
          text:
              'Invoice ${invoice!.invoiceNumber} '
              'from ${invoice!.vendorCompanyName.isEmpty ? 'Invoice Generator' : invoice!.vendorCompanyName}',
          files: [XFile(file.path, mimeType: 'application/pdf')],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share PDF: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  // ============================================================
  // EDIT INVOICE
  // ============================================================

  Future<void> _editInvoice() async {
    if (invoice == null) return;

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditInvoiceScreen(invoice: invoice!)),
    );

    if (updated == true && mounted) {
      setState(() {
        isLoading = true;
      });

      await _loadInvoice();
    }
  }
  // ============================================================
  // PDF
  // ============================================================

  Future<void> _generatePdf() async {
    if (invoice == null) return;

    try {
      final Uint8List pdfBytes = await InvoicePdfService.generateInvoicePdf(
        invoice!,
      );

      final directory = await getApplicationDocumentsDirectory();

      final fileName = '${invoice!.invoiceNumber}.pdf';

      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes, flush: true);

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (format) async {
          return pdfBytes;
        },
        name: fileName,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text(
          'Invoice Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: mainTextColor,
        elevation: 5,
        shadowColor: Colors.white.withOpacity(0.20),
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new),
        ),

        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: mainTextColor),
            color: Theme.of(context).cardTheme.color,
            onSelected: (value) {
              if (value == 'share') {
                _shareInvoice();
              }

              if (value == 'delete') {
                _deleteInvoice();
              }

              if (value == 'edit') {
                _editInvoice();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: primaryColor),
                    const SizedBox(width: 10),
                    Text('Share', style: TextStyle(color: mainTextColor)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 10),
                    Text('Delete', style: TextStyle(color: mainTextColor)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text('Edit', style: TextStyle(color: mainTextColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : invoice == null
          ? _notFoundState()
          : _buildDetails(),
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Widget _buildDetails() {
    final currentInvoice = invoice!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      child: Column(
        children: [
          _headerCard(currentInvoice),

          const SizedBox(height: 14),

          _vendorCard(currentInvoice),

          const SizedBox(height: 14),

          _customerCard(currentInvoice),

          const SizedBox(height: 14),

          _itemsCard(currentInvoice),

          const SizedBox(height: 14),

          // _summaryCard(currentInvoice),
          const SizedBox(height: 14),

          _statusCard(currentInvoice),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareInvoice,
                  icon: Icon(Icons.share_rounded, color: primaryColor),
                  label: Text(
                    'Share',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text(
                    'PDF',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _headerCard(Invoice invoice) {
    final isPaid = invoice.status == 'Paid';

    return _card(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: softPrimaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: primaryColor,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: TextStyle(
                        color: mainTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      invoice.vendorCompanyName.isEmpty
                          ? 'Invoice'
                          : invoice.vendorCompanyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (invoice.customerName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'To: ${invoice.customerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _statusBadge(invoice.status, isPaid),
            ],
          ),

          const SizedBox(height: 18),

          Divider(height: 1, color: borderColor),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _detailInfo(
                  Icons.calendar_today_rounded,
                  'Date',
                  _formatDate(invoice.invoiceDate),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _detailInfo(
                  Icons.access_time_rounded,
                  'Time',
                  _formatTime(invoice.invoiceDate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: softPrimaryColor,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: primaryColor.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Text(
                  'Grand Total',
                  style: TextStyle(
                    color: mainTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Text(
                  _formatCurrency(invoice.total),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VENDOR
  // ============================================================

  Widget _vendorCard(Invoice invoice) {
    return _sectionCard(
      title: 'Vendor / Company',
      icon: Icons.business_rounded,
      child: Column(
        children: [
          if (invoice.vendorCompanyName.isNotEmpty)
            _infoRow(
              Icons.business_rounded,
              'Company',
              invoice.vendorCompanyName,
            ),

          if (invoice.vendorName.isNotEmpty)
            _infoRow(
              Icons.person_outline_rounded,
              'Owner / Vendor',
              invoice.vendorName,
            ),

          if (invoice.vendorEmail.isNotEmpty)
            _infoRow(Icons.email_outlined, 'Email', invoice.vendorEmail),

          if (invoice.vendorPhone.isNotEmpty)
            _infoRow(Icons.phone_outlined, 'Phone', invoice.vendorPhone),

          if (invoice.vendorAddress.isNotEmpty)
            _infoRow(
              Icons.location_on_outlined,
              'Address',
              invoice.vendorAddress,
            ),

          if (invoice.vendorCompanyName.isEmpty &&
              invoice.vendorName.isEmpty &&
              invoice.vendorEmail.isEmpty &&
              invoice.vendorPhone.isEmpty &&
              invoice.vendorAddress.isEmpty)
            _emptySectionText('No vendor information added.'),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER
  // ============================================================

  Widget _customerCard(Invoice invoice) {
    return _sectionCard(
      title: 'Customer',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          _infoRow(Icons.person_outline_rounded, 'Name', invoice.customerName),

          if (invoice.customerEmail.isNotEmpty)
            _infoRow(Icons.email_outlined, 'Email', invoice.customerEmail),

          if (invoice.customerPhone.isNotEmpty)
            _infoRow(Icons.phone_outlined, 'Phone', invoice.customerPhone),
        ],
      ),
    );
  }

  // ============================================================
  // ITEMS
  // ============================================================

  Widget _itemsCard(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),

      child: _sectionCard(
        title: 'Invoice Items',
        icon: Icons.shopping_cart_rounded,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Item',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      'Qty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      'Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            if (invoice.items.isEmpty)
              _emptySectionText('No invoice items added.')
            else
              ...invoice.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mainTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Text(
                          _formatNumber(item.quantity),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatCurrency(item.total),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: mainTextColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            _sectionCard(
              title: 'Summary',
              icon: Icons.calculate_rounded,
              child: Column(
                children: [
                  _summaryRow('Subtotal', invoice.subtotal),

                  const SizedBox(height: 11),

                  _summaryRow('Tax', invoice.tax),

                  const SizedBox(height: 11),

                  _summaryRow('Discount', -invoice.discount),

                  const SizedBox(height: 14),

                  Divider(height: 1, color: borderColor),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          color: mainTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        _formatCurrency(invoice.total),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  // Widget _summaryCard(Invoice invoice) {
  //   return
  // }

  Widget _summaryRow(String title, double value) {
    final isDiscount = value < 0;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        const Spacer(),

        Text(
          _formatCurrency(value),
          style: TextStyle(
            color: isDiscount ? Colors.green : mainTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusCard(Invoice invoice) {
    final isPaid = invoice.status == 'Paid';

    final statusColor = isPaid ? Colors.green : Colors.orange;

    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              color: statusColor,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Status',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  invoice.status,
                  style: TextStyle(
                    color: mainTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          _statusBadge(invoice.status, isPaid),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: softPrimaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryColor, size: 19),
              ),

              const SizedBox(width: 9),

              Text(
                title,
                style: TextStyle(
                  color: mainTextColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: softPrimaryColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: primaryColor),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                title,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                value,
                style: TextStyle(
                  color: mainTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL INFO
  // ============================================================

  Widget _detailInfo(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: softPrimaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: primaryColor),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: TextStyle(
                    color: mainTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status, bool isPaid) {
    final color = isPaid ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(width: 5),

          Text(
            status,
            style: TextStyle(
              color: isPaid ? Colors.green : Colors.orange.shade800,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY SECTION TEXT
  // ============================================================

  Widget _emptySectionText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(color: secondaryTextColor, fontSize: 13),
      ),
    );
  }

  // ============================================================
  // NOT FOUND
  // ============================================================

  Widget _notFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: softPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: primaryColor,
                size: 55,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Invoice not found',
              style: TextStyle(
                color: mainTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'The invoice you are looking for '
              'could not be found.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor, height: 1.4),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  String _formatCurrency(double amount) {
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  // ============================================================
  // NUMBER
  // ============================================================

  String _formatNumber(double number) {
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(2);
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
