import 'package:flutter/material.dart';
import 'package:innvoice_generator/core/services/pdf_service.dart';
import 'package:innvoice_generator/data/models/invoice_model.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         elevation: 6,
        shadowColor: Colors.black87,
        title:  Text(
          invoice.invoiceNumber,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await PdfService.generateAndOpen(invoice);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            /// HEADER
            Text("Invoice #${invoice.invoiceNumber}",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            Text("Customer: ${invoice.customer.name}"),
            Text("Email: ${invoice.customer.email}"),
            Text("Phone: ${invoice.customer.phone}"),

            const Divider(height: 30),

            /// ITEMS
            const Text("Items",
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            ...invoice.items.map((item) {
              return ListTile(
                title: Text(item.name),
                subtitle:
                    Text("${item.quantity} x \$${item.price}"),
                trailing: Text(
                    "\$${item.total.toStringAsFixed(2)}"),
              );
            }),

            const Divider(),

            /// TOTALS
            _row("Subtotal", invoice.subtotal),
            _row("Tax", invoice.tax),
            _row("Total", invoice.total, isBold: true),

            const SizedBox(height: 20),

            Text("Status: ${invoice.status}",
                style: TextStyle(
                    color: _statusColor(invoice.status))),

            if (invoice.notes.isNotEmpty)
              Text("Notes: ${invoice.notes}"),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, double value,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal)),
        Text("\$${value.toStringAsFixed(2)}",
            style: TextStyle(
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Paid":
        return Colors.green;
      case "Unpaid":
        return Colors.orange;
      case "Overdue":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}