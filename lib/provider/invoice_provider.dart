import 'package:flutter/foundation.dart';
import 'package:innvoice_generator/models/invoice_model.dart';

import '../core/database/database_helper.dart';

class InvoiceProvider extends ChangeNotifier {
  final DatabaseHelper _database = DatabaseHelper();

  List<Invoice> _invoices = [];

  bool _isLoading = false;

  List<Invoice> get invoices => _invoices;

  bool get isLoading => _isLoading;

  // ============================================================
  // LOAD ALL INVOICES
  // ============================================================

  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _invoices = await _database.getInvoices();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // GET NEXT INVOICE NUMBER
  // ============================================================

  Future<String> getNextInvoiceNumber() async {
    return await _database.getNextInvoiceNumber();
  }

  // ============================================================
  // ADD INVOICE
  // ============================================================

  Future<void> addInvoice(Invoice invoice) async {
    await _database.insertInvoice(invoice);

    await loadInvoices();
  }
  // ============================================================
  // EDIT INVOICE
  // ============================================================

  Future<void> updateInvoice(Invoice invoice) async {
    await _database.updateInvoice(invoice);
    await loadInvoices();
  }
  // ============================================================
  // DELETE INVOICE
  // ============================================================

  Future<void> deleteInvoice(int id) async {
    await _database.deleteInvoice(id);

    await loadInvoices();
  }

  // ============================================================
  // GET SINGLE INVOICE
  // ============================================================

  Future<Invoice?> getInvoiceById(int id) async {
    return await _database.getInvoiceById(id);
  }

  // ============================================================
  // GET BY INVOICE NUMBER
  // ============================================================

  Future<Invoice?> findByInvoiceNumber(String invoiceNumber) async {
    return await _database.getInvoiceByNumber(invoiceNumber);
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  int get totalInvoices {
    return _invoices.length;
  }

  int get paidInvoices {
    return _invoices.where((invoice) => invoice.status == 'Paid').length;
  }

  int get pendingInvoices {
    return _invoices.where((invoice) => invoice.status == 'Pending').length;
  }

  double get totalRevenue {
    return _invoices.fold(0, (sum, invoice) => sum + invoice.total);
  }

  double get paidRevenue {
    return _invoices
        .where((invoice) => invoice.status == 'Paid')
        .fold(0, (sum, invoice) => sum + invoice.total);
  }

  double get pendingRevenue {
    return _invoices
        .where((invoice) => invoice.status == 'Pending')
        .fold(0, (sum, invoice) => sum + invoice.total);
  }
}
