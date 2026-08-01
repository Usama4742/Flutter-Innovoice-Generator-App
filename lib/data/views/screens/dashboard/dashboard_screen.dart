import 'package:flutter/material.dart';
import 'package:innvoice_generator/data/views/screens/invoice/add_edit_invoice_screen.dart';
import 'package:innvoice_generator/data/views/screens/invoice/invoice_list_screen.dart';
import 'package:innvoice_generator/data/views/screens/setting/setting_screen.dart';
import 'package:innvoice_generator/providers/invoice_provider.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InvoiceViewModel>();

    final totalInvoices = vm.invoices.length;

    final paid = vm.invoices.where((i) => i.status == "Paid").length;

    final unpaid = vm.invoices.where((i) => i.status == "Unpaid").length;

    final revenue = vm.invoices
        .where((i) => i.status == "Paid")
        .fold(0.0, (sum, i) => sum + i.total);

    final recentInvoices = vm.invoices.reversed.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        shadowColor: Colors.black87,
        title: Row(
          children: [
            const Text(
              "Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),

            Spacer(),
            IconButton(
              onPressed: () {
                MaterialPageRoute(builder: (_) => const SettingsScreen());
              },
              icon: Icon(Icons.settings),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditInvoiceScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("New Invoice"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// SUMMARY CARDS
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    "Total",
                    totalInvoices.toString(),
                    Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCard(
                    context,
                    "Paid",
                    paid.toString(),
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    "Unpaid",
                    unpaid.toString(),
                    Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCard(
                    context,
                    "Revenue",
                    "\$${revenue.toStringAsFixed(2)}",
                    Icons.attach_money,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// VIEW ALL
            Card(
              elevation: 6,
              child: ListTile(
                title: const Text("View All Invoices"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InvoiceListScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /// RECENT
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Invoices",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            const SizedBox(height: 10),

            recentInvoices.isEmpty
                ? const Center(child: Text("No invoices yet"))
                : Column(
                    children: recentInvoices.map((invoice) {
                      return Card(
                        child: ListTile(
                          title: Text(invoice.invoiceNumber),
                          subtitle: Text(invoice.customer.name),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "\$${invoice.total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                invoice.status,
                                style: TextStyle(
                                  color: invoice.status == "Paid"
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color ?? Colors.black),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 5),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
