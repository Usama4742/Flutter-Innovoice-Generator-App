
class Invoice {
  final int? id;

  final String invoiceNumber;

  // Vendor / Company
  final String vendorCompanyName;
  final String vendorName;
  final String vendorEmail;
  final String vendorPhone;
  final String vendorAddress;

  // Customer
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  // Date + Time
  final DateTime invoiceDate;

  // Financial
  final double subtotal;
  final double tax;
  final double discount;
  final double total;

  final String status;

  final List<InvoiceItem> items;

  Invoice({
    this.id,
    required this.invoiceNumber,

    required this.vendorCompanyName,
    required this.vendorName,
    required this.vendorEmail,
    required this.vendorPhone,
    required this.vendorAddress,

    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,

    required this.invoiceDate,

    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,

    required this.status,

    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'invoice_number': invoiceNumber,

      // Vendor / Company
      'vendor_company_name': vendorCompanyName,
      'vendor_name': vendorName,
      'vendor_email': vendorEmail,
      'vendor_phone': vendorPhone,
      'vendor_address': vendorAddress,

      // Customer
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,

      // Complete date + time
      'invoice_date': invoiceDate.toIso8601String(),

      // Financial
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,

      'status': status,
    };
  }

  factory Invoice.fromMap(
    Map<String, dynamic> map, {
    List<InvoiceItem> items = const [],
  }) {
    return Invoice(
      id: map['id'] as int?,

      invoiceNumber:
          map['invoice_number']?.toString() ?? '',

      // Vendor / Company
      vendorCompanyName:
          map['vendor_company_name']?.toString() ?? '',
      vendorName:
          map['vendor_name']?.toString() ?? '',
      vendorEmail:
          map['vendor_email']?.toString() ?? '',
      vendorPhone:
          map['vendor_phone']?.toString() ?? '',
      vendorAddress:
          map['vendor_address']?.toString() ?? '',

      // Customer
      customerName:
          map['customer_name']?.toString() ?? '',
      customerEmail:
          map['customer_email']?.toString() ?? '',
      customerPhone:
          map['customer_phone']?.toString() ?? '',

      // Date + Time
      invoiceDate:
          DateTime.tryParse(
                map['invoice_date']?.toString() ?? '',
              ) ??
              DateTime.now(),

      // Financial
      subtotal:
          (map['subtotal'] as num?)?.toDouble() ?? 0,
      tax:
          (map['tax'] as num?)?.toDouble() ?? 0,
      discount:
          (map['discount'] as num?)?.toDouble() ?? 0,
      total:
          (map['total'] as num?)?.toDouble() ?? 0,

      status:
          map['status']?.toString() ?? 'Pending',

      items: items,
    );
  }
}

class InvoiceItem {
  final int? id;
  final int? invoiceId;

  final String name;
  final double quantity;
  final double price;
  final double total;

  InvoiceItem({
    this.id,
    this.invoiceId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      name: map['name']?.toString() ?? '',
      quantity:
          (map['quantity'] as num?)?.toDouble() ?? 0,
      price:
          (map['price'] as num?)?.toDouble() ?? 0,
      total:
          (map['total'] as num?)?.toDouble() ?? 0,
    );
  }
}