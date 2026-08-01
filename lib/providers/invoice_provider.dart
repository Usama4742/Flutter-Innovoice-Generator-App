import '../core/services/storage_service.dart';

import 'package:flutter/material.dart';
import 'package:innvoice_generator/data/models/invoice_model.dart';
class InvoiceViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> get invoices => _invoices;

  InvoiceViewModel() {
    Future.microtask(() => loadInvoices()); // ✅ delay execution
  }

  void loadInvoices() {
    _invoices = _storage.getInvoices();
    notifyListeners();
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    await _storage.addInvoice(invoice);
    loadInvoices();
  }

  Future<void> deleteInvoice(String id) async {
    await _storage.deleteInvoice(id);
    loadInvoices();
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _storage.updateInvoice(invoice);
    loadInvoices();
  }

  void markAsPaid(String id) {
    final invoice = _invoices.firstWhere((i) => i.id == id);
    invoice.status = "Paid";
    updateInvoice(invoice);
  }
}