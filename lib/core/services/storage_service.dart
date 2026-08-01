import 'package:hive/hive.dart';
import 'package:innvoice_generator/data/models/invoice_model.dart';

class StorageService {
  Box get _box => Hive.box('invoices'); // ✅ LAZY ACCESS

  List<InvoiceModel> getInvoices() {
    return _box.values
        .map((e) => InvoiceModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    await _box.put(invoice.id, invoice.toMap());
  }

  Future<void> deleteInvoice(String id) async {
    await _box.delete(id);
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _box.put(invoice.id, invoice.toMap());
  }
}