import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/invoice_model.dart';

class PdfService {
  static Future<void> generateAndOpen(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                pw.Text("INVOICE",
                    style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold)),

                pw.SizedBox(height: 10),

                pw.Text("Invoice #: ${invoice.invoiceNumber}"),
                pw.Text("Date: ${invoice.date}"),
                pw.Text("Due: ${invoice.dueDate}"),

                pw.SizedBox(height: 20),

                pw.Text("Bill To:",
                    style:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold)),

                pw.Text(invoice.customer.name),
                pw.Text(invoice.customer.email),

                pw.SizedBox(height: 20),

                /// TABLE
                pw.Table.fromTextArray(
                  headers: ["Item", "Qty", "Price", "Total"],
                  data: invoice.items.map((item) {
                    return [
                      item.name,
                      item.quantity.toString(),
                      "\$${item.price}",
                      "\$${item.total.toStringAsFixed(2)}",
                    ];
                  }).toList(),
                ),

                pw.SizedBox(height: 20),

                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Subtotal: \$${invoice.subtotal}"),
                      pw.Text("Tax: \$${invoice.tax}"),
                      pw.Text("Total: \$${invoice.total}",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/invoice.pdf");

    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}