import 'package:flutter/widgets.dart';

class InvoiceItemData {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController quantityController = TextEditingController(
    text: '',
  );

  final TextEditingController priceController = TextEditingController(
    text: '',
  );

  double get quantity {
    return double.tryParse(quantityController.text) ?? 0;
  }

  double get price {
    return double.tryParse(priceController.text) ?? 0;
  }

  double get total {
    return quantity * price;
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}
