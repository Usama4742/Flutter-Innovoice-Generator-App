import 'package:flutter/material.dart';
import 'package:innvoice_generator/core/utils/invoice_utils.dart';
import 'package:innvoice_generator/data/models/customer_model.dart';
import 'package:innvoice_generator/data/models/invoice_model.dart';
import 'package:innvoice_generator/data/models/item_model.dart';
import 'package:innvoice_generator/providers/invoice_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';


class AddEditInvoiceScreen extends StatefulWidget {
  const AddEditInvoiceScreen({super.key});

  @override
  State<AddEditInvoiceScreen> createState() =>
      _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState
    extends State<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();
  final taxController = TextEditingController(text: "0");

  DateTime invoiceDate = DateTime.now();
  DateTime dueDate = DateTime.now();

  List<ItemModel> items = [];

  void addItem() {
    setState(() {
      items.add(ItemModel(name: "", quantity: 1, price: 0));
    });
  }

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.total);

  double get tax =>
      subtotal * (double.tryParse(taxController.text) ?? 0) / 100;

  double get total => subtotal + tax;

  void saveInvoice() {
    if (!_formKey.currentState!.validate() || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields & add items")),
      );
      return;
    }

    final invoice = InvoiceModel(
      id: const Uuid().v4(),
      invoiceNumber: InvoiceUtils.generateInvoiceNumber(),
      date: invoiceDate,
      dueDate: dueDate,
      customer: CustomerModel(
        name: nameController.text,
        address: addressController.text,
        email: emailController.text,
        phone: phoneController.text,
      ),
      items: items,
      taxPercent: double.tryParse(taxController.text) ?? 0,
      notes: notesController.text,
    );

    Provider.of<InvoiceViewModel>(context, listen: false)
        .addInvoice(invoice);

    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    emailController.dispose();
    phoneController.dispose();
    notesController.dispose();
    taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Invoice"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveInvoice,
        child: const Icon(Icons.save),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            /// CUSTOMER INFO
            const Text("Customer Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),

            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Address"),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),

            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),

            const SizedBox(height: 20),

            /// ITEMS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Items",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: addItem,
                  icon: const Icon(Icons.add),
                )
              ],
            ),

            ...List.generate(items.length, (index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: "Item Name"),
                        onChanged: (v) => items[index].name = v,
                        validator: (v) =>
                            v!.isEmpty ? "Required" : null,
                      ),

                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: "Quantity"),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => items[index].quantity =
                            int.tryParse(v) ?? 1,
                      ),

                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: "Price"),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => items[index].price =
                            double.tryParse(v) ?? 0,
                      ),

                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: "Discount"),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => items[index].discount =
                            double.tryParse(v) ?? 0,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => removeItem(index),
                          icon: const Icon(Icons.delete),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            /// TAX
            TextFormField(
              controller: taxController,
              decoration:
                  const InputDecoration(labelText: "Tax (%)"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            /// TOTALS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _row("Subtotal", subtotal),
                    _row("Tax", tax),
                    _row("Total", total, isBold: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// NOTES
            TextFormField(
              controller: notesController,
              decoration:
                  const InputDecoration(labelText: "Notes"),
              maxLines: 3,
            ),
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
}