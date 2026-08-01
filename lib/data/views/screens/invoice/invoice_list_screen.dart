import 'package:flutter/material.dart';
import 'package:innvoice_generator/data/models/invoice_model.dart';
import 'package:innvoice_generator/data/views/screens/invoice/invoice_detail_scree.dart';
import 'package:innvoice_generator/providers/invoice_provider.dart';
import 'package:provider/provider.dart';
import 'add_edit_invoice_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvoiceViewModel>(context);

    final invoices = vm.invoices.where((inv) {
      return inv.invoiceNumber.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          inv.customer.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        shadowColor: Colors.black87,
        title: const Text(
          "Invoices",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditInvoiceScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by Invoice # or Customer",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() => searchQuery = v);
              },
            ),
          ),

          /// 📭 EMPTY STATE
          if (invoices.isEmpty)
            const Expanded(child: Center(child: Text("No invoices found")))
          else
            Expanded(
              child: ListView.builder(
                itemCount: invoices.length,
                itemBuilder: (_, index) {
                  final invoice = invoices[index];
                  return _invoiceCard(context, vm, invoice);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _invoiceCard(
    BuildContext context,
    InvoiceViewModel vm,
    InvoiceModel invoice,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(invoice.invoiceNumber),
        subtitle: Text(invoice.customer.name),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "\$${invoice.total.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              invoice.status,
              style: TextStyle(color: _statusColor(invoice.status)),
            ),
          ],
        ),
        onTap: () {
          _showOptions(context, vm, invoice);
        },
      ),
    );
  }

  void _showOptions(
    BuildContext context,
    InvoiceViewModel vm,
    InvoiceModel invoice,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text("View"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailScreen(invoice: invoice),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditInvoiceScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("Duplicate"),
              onTap: () {
                Navigator.pop(context);
                final newInvoice = InvoiceModel(
                  id: DateTime.now().toString(),
                  invoiceNumber: invoice.invoiceNumber + "-COPY",
                  date: DateTime.now(),
                  dueDate: invoice.dueDate,
                  customer: invoice.customer,
                  items: invoice.items,
                  taxPercent: invoice.taxPercent,
                  notes: invoice.notes,
                );
                vm.addInvoice(newInvoice);
              },
            ),

            ListTile(
              leading: const Icon(Icons.check),
              title: const Text("Mark as Paid"),
              onTap: () {
                Navigator.pop(context);
                vm.markAsPaid(invoice.id);
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Delete"),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, vm, invoice.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, InvoiceViewModel vm, String id) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Invoice"),
          content: const Text("Are you sure you want to delete?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                vm.deleteInvoice(id);
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
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
