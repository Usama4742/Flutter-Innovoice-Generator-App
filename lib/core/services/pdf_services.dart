import 'dart:convert';
import 'dart:typed_data';
import 'package:innvoice_generator/models/invoice_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePdfService {
  static Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    const primaryColor = PdfColor.fromInt(0xFF2563EB);
    const darkColor = PdfColor.fromInt(0xFF111827);
    const greyColor = PdfColor.fromInt(0xFF6B7280);
    const lightGrey = PdfColor.fromInt(0xFFF3F4F6);
    const greenColor = PdfColor.fromInt(0xFF16A34A);

    // QR DATA
    final qrData = _createQrData(invoice);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),

        header: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    invoice.vendorCompanyName.isNotEmpty
                        ? invoice.vendorCompanyName
                        : invoice.vendorName,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: greyColor,
                    ),
                  ),
                ],
              ),

              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  invoice.invoiceNumber,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: darkColor,
                  ),
                ),
              ),
            ],
          );
        },

        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated Invoice',
                  style: pw.TextStyle(fontSize: 8, color: greyColor),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: greyColor),
                ),
              ],
            ),
          );
        },

        build: (context) => [
          pw.SizedBox(height: 15),

          // INVOICE META
          _invoiceMeta(invoice, primaryColor, darkColor, greyColor, lightGrey),

          pw.SizedBox(height: 15),

          // CUSTOMER INFORMATION
          _partyInformation(
            invoice,
            primaryColor,
            darkColor,
            greyColor,
            lightGrey,
          ),

          pw.SizedBox(height: 18),

          // ITEMS
          _itemsTable(invoice, primaryColor, darkColor, greyColor, lightGrey),

          pw.SizedBox(height: 22),

          // SUMMARY
          _summary(invoice, primaryColor, darkColor, greyColor),
          pw.SizedBox(height: 15),

          // QR CODE
          _qrSection(
            invoice,
            qrData,
            primaryColor,
            darkColor,
            greyColor,
            lightGrey,
          ),
          pw.SizedBox(height: 15),

          // STATUS
          _paymentStatus(invoice, greenColor, darkColor),
        ],
      ),
    );

    return pdf.save();
  }

  // ------------------------------------------------------------
  // QR DATA
  // ------------------------------------------------------------

  static String _createQrData(Invoice invoice) {
    final Map<String, dynamic> data = {
      'type': 'invoice',
      'invoiceNumber': invoice.invoiceNumber,
      'invoiceId': invoice.id,
      'vendorCompanyName': invoice.vendorCompanyName,
      'vendorName': invoice.vendorName,
      'customerName': invoice.customerName,
      'customerEmail': invoice.customerEmail,
      'customerPhone': invoice.customerPhone,
      'invoiceDate': invoice.invoiceDate.toIso8601String(),
      'subtotal': invoice.subtotal,
      'tax': invoice.tax,
      'discount': invoice.discount,
      'total': invoice.total,
      'status': invoice.status,
    };

    return jsonEncode(data);
  }

  // ------------------------------------------------------------
  // QR SECTION
  // ------------------------------------------------------------

  static pw.Widget _qrSection(
    Invoice invoice,
    String qrData,
    PdfColor primaryColor,
    PdfColor darkColor,
    PdfColor greyColor,
    PdfColor lightGrey,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: lightGrey,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // pw.Text(
          //   'SCAN INVOICE',
          //   style: pw.TextStyle(
          //     fontSize: 15,
          //     fontWeight: pw.FontWeight.bold,
          //     color: primaryColor,
          //   ),
          // ),

          // pw.SizedBox(height: 6),
          pw.Text(
            'Scan this QR code to view invoice details',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 9, color: greyColor),
          ),

          pw.SizedBox(height: 10),

          // ACTUAL QR CODE
          pw.Container(
            width: 150,
            height: 150,
            padding: const pw.EdgeInsets.all(8),
            color: PdfColors.white,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrData,
              width: 164,
              height: 164,
            ),
          ),

          // pw.SizedBox(height: 12),

          // pw.Text(
          //   invoice.invoiceNumber,
          //   style: pw.TextStyle(
          //     fontSize: 12,
          //     fontWeight: pw.FontWeight.bold,
          //     color: darkColor,
          //   ),
          // ),

          // pw.SizedBox(height: 4),

          // pw.Text(
          //   'Invoice Number',
          //   style: pw.TextStyle(
          //     fontSize: 8,
          //     color: greyColor,
          //   ),
          // ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INVOICE META
  // ------------------------------------------------------------

  static pw.Widget _invoiceMeta(
    Invoice invoice,
    PdfColor primaryColor,
    PdfColor darkColor,
    PdfColor greyColor,
    PdfColor lightGrey,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: lightGrey,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _metaItem(
            'Invoice Number',
            invoice.invoiceNumber,
            darkColor,
            greyColor,
          ),
          _metaItem(
            'Date',
            _formatDate(invoice.invoiceDate),
            darkColor,
            greyColor,
          ),
          _metaItem(
            'Time',
            _formatTime(invoice.invoiceDate),
            darkColor,
            greyColor,
          ),
          // _metaItem(
          //   'Total',
          //   _formatCurrency(invoice.total),
          //   primaryColor,
          //   greyColor,
          // ),
        ],
      ),
    );
  }

  static pw.Widget _metaItem(
    String title,
    String value,
    PdfColor valueColor,
    PdfColor titleColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 8, color: titleColor)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // CUSTOMER INFORMATION
  // ------------------------------------------------------------

  static pw.Widget _partyInformation(
    Invoice invoice,
    PdfColor primaryColor,
    PdfColor darkColor,
    PdfColor greyColor,
    PdfColor lightGrey,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BILL TO',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),

          pw.SizedBox(height: 8),

          pw.Text(
            invoice.customerName,
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: darkColor,
            ),
          ),

          if (invoice.customerEmail.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              invoice.customerEmail,
              style: pw.TextStyle(fontSize: 12, color: darkColor),
            ),
          ],

          if (invoice.customerPhone.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              invoice.customerPhone,
              style: pw.TextStyle(fontSize: 12, color: darkColor),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ITEMS TABLE
  // ------------------------------------------------------------

  static pw.Widget _itemsTable(
    Invoice invoice,
    PdfColor primaryColor,
    PdfColor darkColor,
    PdfColor greyColor,
    PdfColor lightGrey,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: [
            _tableHeader('Item'),
            _tableHeader('Qty'),
            _tableHeader('Price'),
            _tableHeader('Total'),
          ],
        ),

        ...invoice.items.map((item) {
          return pw.TableRow(
            children: [
              _tableCell(item.name, darkColor),
              _tableCell(item.quantity.toString(), darkColor, center: true),
              _tableCell(_formatCurrency(item.price), darkColor, center: true),
              _tableCell(_formatCurrency(item.total), darkColor, center: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text,
    PdfColor color, {
    bool center = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(fontSize: 12, color: color),
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY
  // ------------------------------------------------------------

  static pw.Widget _summary(
    Invoice invoice,
    PdfColor primaryColor,
    PdfColor darkColor,
    PdfColor greyColor,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        child: pw.Column(
          children: [
            _summaryRow(
              'Subtotal',
              _formatCurrency(invoice.subtotal),
              darkColor,
              greyColor,
            ),
            _summaryRow(
              'Tax',
              _formatCurrency(invoice.tax),
              darkColor,
              greyColor,
            ),
            _summaryRow(
              'Discount',
              _formatCurrency(invoice.discount),
              darkColor,
              greyColor,
            ),

            pw.Divider(color: PdfColors.grey300),

            _summaryRow(
              'Grand Total',
              _formatCurrency(invoice.total),
              primaryColor,
              greyColor,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(
    String title,
    String value,
    PdfColor valueColor,
    PdfColor titleColor, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: bold ? 11 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: titleColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: bold ? 12 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PAYMENT STATUS
  // ------------------------------------------------------------

  static pw.Widget _paymentStatus(
    Invoice invoice,
    PdfColor greenColor,
    PdfColor darkColor,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Payment Status',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: darkColor,
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: greenColor,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              invoice.status,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FORMATTERS
  // ------------------------------------------------------------

  static String _formatCurrency(double value) {
    return 'Rs. ${value.toStringAsFixed(2)}';
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String _formatTime(DateTime date) {
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
