class InvoiceUtils {
  static int _counter = 1;

  static String generateInvoiceNumber({String prefix = "INV-"}) {
    final number = _counter.toString().padLeft(3, '0');
    _counter++;
    return "$prefix$number";
  }
}