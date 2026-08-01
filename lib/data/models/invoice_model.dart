import 'item_model.dart';
import 'customer_model.dart';

class InvoiceModel {
  String id;
  String invoiceNumber;
  DateTime date;
  DateTime dueDate;
  CustomerModel customer;
  List<ItemModel> items;
  double taxPercent;
  String status; // Paid, Unpaid, Overdue
  String notes;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.customer,
    required this.items,
    this.taxPercent = 0,
    this.status = "Unpaid",
    this.notes = "",
  });

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.total);

  double get tax =>
      subtotal * taxPercent / 100;

  double get total =>
      subtotal + tax;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'customer': customer.toMap(),
      'items': items.map((e) => e.toMap()).toList(),
      'taxPercent': taxPercent,
      'status': status,
      'notes': notes,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      date: DateTime.parse(map['date']),
      dueDate: DateTime.parse(map['dueDate']),
      customer: CustomerModel.fromMap(map['customer']),
      items: (map['items'] as List)
          .map((e) => ItemModel.fromMap(e))
          .toList(),
      taxPercent: map['taxPercent'],
      status: map['status'],
      notes: map['notes'],
    );
  }
}