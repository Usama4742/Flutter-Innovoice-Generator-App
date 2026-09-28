import 'package:flutter/material.dart';
import 'package:innvoice_generator/core/services/vendor_services.dart';
import 'package:innvoice_generator/widgets/theme.dart';
import 'package:provider/provider.dart';
import '../../models/invoice_model.dart';
import '../../provider/invoice_provider.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  // Vendor
  final companyNameController = TextEditingController();
  final vendorNameController = TextEditingController();
  final vendorEmailController = TextEditingController();
  final vendorPhoneController = TextEditingController();
  final vendorAddressController = TextEditingController();

  // Customer
  final customerNameController = TextEditingController();
  final customerEmailController = TextEditingController();
  final customerPhoneController = TextEditingController();

  // Tax / Discount
  final taxController = TextEditingController(text: '5');
  final discountController = TextEditingController(text: '0');

  // ============================================================
  // STATE
  // ============================================================

  DateTime invoiceDate = DateTime.now();

  String paymentStatus = 'Pending';

  String invoiceNumber = 'Loading...';

  bool isSaving = false;
  bool isLoadingVendorSettings = true;

  final List<InvoiceItemForm> items = [InvoiceItemForm()];

  // ============================================================
  // COLORS
  // ============================================================

  Color get primaryColor => AppTheme.primaryBlue;

  Color get backgroundColor {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color get cardColor {
    final theme = Theme.of(context);

    if (theme.brightness == Brightness.dark) {
      return const Color(0xFF1E1E1E);
    }

    return Colors.white;
  }

  Color get fieldBackgroundColor {
    final theme = Theme.of(context);

    if (theme.brightness == Brightness.dark) {
      return const Color(0xFF252525);
    }

    return const Color(0xFFF8FAFC);
  }

  Color get softPrimaryColor {
    return primaryColor.withOpacity(
      Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.08,
    );
  }

  Color get borderColor {
    final theme = Theme.of(context);

    if (theme.brightness == Brightness.dark) {
      return Colors.white.withOpacity(0.10);
    }

    return const Color(0xFFE2E8F0);
  }

  Color get secondaryTextColor {
    final theme = Theme.of(context);

    if (theme.brightness == Brightness.dark) {
      return Colors.white.withOpacity(0.65);
    }

    return const Color(0xFF64748B);
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNextInvoiceNumber();
      _loadVendorSettings();
    });
  }

  @override
  void dispose() {
    companyNameController.dispose();
    vendorNameController.dispose();
    vendorEmailController.dispose();
    vendorPhoneController.dispose();
    vendorAddressController.dispose();

    customerNameController.dispose();
    customerEmailController.dispose();
    customerPhoneController.dispose();

    taxController.dispose();
    discountController.dispose();

    for (final item in items) {
      item.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // LOAD NEXT NUMBER
  // ============================================================

  Future<void> _loadNextInvoiceNumber() async {
    try {
      final provider = context.read<InvoiceProvider>();

      final number = await provider.getNextInvoiceNumber();

      if (!mounted) return;

      setState(() {
        invoiceNumber = number;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        invoiceNumber = 'INV-001';
      });
    }
  }

  // ============================================================
  // LOAD VENDOR SETTINGS
  // ============================================================

  Future<void> _loadVendorSettings() async {
    try {
      final settings = await VendorSettingsService.getVendorSettings();

      if (!mounted) return;

      setState(() {
        companyNameController.text = settings['companyName'] ?? '';

        vendorNameController.text = settings['vendorName'] ?? '';

        vendorEmailController.text = settings['email'] ?? '';

        vendorPhoneController.text = settings['phone'] ?? '';

        vendorAddressController.text = settings['address'] ?? '';

        isLoadingVendorSettings = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingVendorSettings = false;
      });
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    setState(() {
      invoiceDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        invoiceDate.hour,
        invoiceDate.minute,
      );
    });
  }

  // ============================================================
  // TIME
  // ============================================================

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(invoiceDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      invoiceDate = DateTime(
        invoiceDate.year,
        invoiceDate.month,
        invoiceDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================

  double get subtotal {
    double value = 0;

    for (final item in items) {
      value += item.total;
    }

    return value;
  }

  double get tax {
    final percentage = double.tryParse(taxController.text) ?? 0;

    if (percentage < 0) return 0;

    return subtotal * percentage / 100;
  }

  double get discount {
    final value = double.tryParse(discountController.text) ?? 0;

    if (value < 0) return 0;

    return value;
  }

  double get total {
    final calculatedTotal = subtotal + tax - discount;

    return calculatedTotal < 0 ? 0 : calculatedTotal;
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validateInvoice() {
    if (customerNameController.text.trim().isEmpty) {
      _showMessage('Please enter customer name.');
      return false;
    }

    final taxValue = double.tryParse(taxController.text.trim());

    if (taxValue == null || taxValue < 0) {
      _showMessage('Please enter a valid tax percentage.');
      return false;
    }

    final discountValue = double.tryParse(discountController.text.trim());

    if (discountValue == null || discountValue < 0) {
      _showMessage('Please enter a valid discount.');
      return false;
    }

    bool hasValidItem = false;

    for (final item in items) {
      final name = item.nameController.text.trim();

      final quantity = double.tryParse(item.quantityController.text.trim());

      final price = double.tryParse(item.priceController.text.trim());

      if (name.isNotEmpty &&
          quantity != null &&
          quantity > 0 &&
          price != null &&
          price >= 0) {
        hasValidItem = true;
        break;
      }
    }

    if (!hasValidItem) {
      _showMessage('Please add at least one valid invoice item.');
      return false;
    }

    return true;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveInvoice() async {
    if (isSaving || isLoadingVendorSettings) return;

    if (companyNameController.text.trim().isEmpty ||
        vendorNameController.text.trim().isEmpty) {
      _showMessage(
        'Please complete Company Settings before creating an invoice.',
      );
      return;
    }

    if (customerNameController.text.trim().isEmpty) {
      _showMessage('Please enter customer name.');
      return;
    }

    if (!_validateInvoice()) return;

    setState(() {
      isSaving = true;
    });

    try {
      final provider = context.read<InvoiceProvider>();

      final finalInvoiceNumber = await provider.getNextInvoiceNumber();

      final validItems = items.where((item) {
        final name = item.nameController.text.trim();

        final quantity = double.tryParse(item.quantityController.text.trim());

        final price = double.tryParse(item.priceController.text.trim());

        return name.isNotEmpty &&
            quantity != null &&
            quantity > 0 &&
            price != null &&
            price >= 0;
      }).toList();

      final invoiceItems = validItems.map((item) {
        final quantity =
            double.tryParse(item.quantityController.text.trim()) ?? 0;

        final price = double.tryParse(item.priceController.text.trim()) ?? 0;

        return InvoiceItem(
          name: item.nameController.text.trim(),
          quantity: quantity,
          price: price,
          total: quantity * price,
        );
      }).toList();

      // Calculate values from the actual valid items.
      final calculatedSubtotal = invoiceItems.fold<double>(
        0,
        (sum, item) => sum + item.total,
      );

      final taxPercentage = double.tryParse(taxController.text.trim()) ?? 0;

      final calculatedTax = calculatedSubtotal * taxPercentage / 100;

      final calculatedDiscount =
          double.tryParse(discountController.text.trim()) ?? 0;

      final calculatedTotal =
          (calculatedSubtotal + calculatedTax - calculatedDiscount)
              .clamp(0, double.infinity)
              .toDouble();

      final invoice = Invoice(
        invoiceNumber: finalInvoiceNumber,

        // Vendor
        vendorCompanyName: companyNameController.text.trim(),
        vendorName: vendorNameController.text.trim(),
        vendorEmail: vendorEmailController.text.trim(),
        vendorPhone: vendorPhoneController.text.trim(),
        vendorAddress: vendorAddressController.text.trim(),

        // Customer
        customerName: customerNameController.text.trim(),
        customerEmail: customerEmailController.text.trim(),
        customerPhone: customerPhoneController.text.trim(),

        // Date + Time
        invoiceDate: invoiceDate,

        // Financial
        subtotal: calculatedSubtotal,
        tax: calculatedTax,
        discount: calculatedDiscount,
        total: calculatedTotal,

        // Status
        status: paymentStatus,

        // Items
        items: invoiceItems,
      );

      await provider.addInvoice(invoice);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$finalInvoiceNumber created successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to save invoice: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text(
          'Create Invoice',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        titleSpacing: 20,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Invoice Information'),

            _invoiceInformationCard(),

            // const SizedBox(height: 15),

            // _sectionTitle('Vendor / Company'),

            // _vendorCard(),
            const SizedBox(height: 22),

            _sectionTitle('Customer'),

            _customerCard(),

            const SizedBox(height: 22),

            _sectionTitle('Invoice Items'),

            _itemsCard(),

            const SizedBox(height: 22),

            _sectionTitle('Tax & Discount'),

            _taxDiscountCard(),

            const SizedBox(height: 22),

            _sectionTitle('Payment Status'),

            _paymentStatusCard(),

            const SizedBox(height: 22),

            _totalCard(),

            const SizedBox(height: 24),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveInvoice,
                icon: isSaving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 21),
                label: Text(
                  isSaving ? 'Saving...' : 'Save Invoice',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  // ============================================================
  // INVOICE INFORMATION
  // ============================================================

  Widget _invoiceInformationCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoBox(
                  'Invoice Number',
                  invoiceNumber,
                  Icons.receipt_long,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _infoBox('Status', paymentStatus, Icons.payment_rounded),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _dateButton()),

              const SizedBox(width: 12),

              Expanded(child: _timeButton()),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE BUTTON
  // ============================================================

  Widget _dateButton() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: softPrimaryColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _formatDate(invoiceDate),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIME BUTTON
  // ============================================================

  Widget _timeButton() {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: softPrimaryColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.access_time_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _formatTime(invoiceDate),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VENDOR
  // ============================================================

  // Widget _vendorCard() {
  //   return _card(
  //     child: Column(
  //       children: [
  //         _textField(
  //           controller: companyNameController,
  //           label: 'Company Name',
  //           icon: Icons.business_rounded,
  //         ),
  //
  //         const SizedBox(height: 12),
  //
  //         _textField(
  //           controller: vendorNameController,
  //           label: 'Vendor / Owner Name',
  //           icon: Icons.person_rounded,
  //         ),
  //
  //         const SizedBox(height: 12),
  //
  //         _textField(
  //           controller: vendorEmailController,
  //           label: 'Vendor Email',
  //           icon: Icons.email_rounded,
  //           keyboardType: TextInputType.emailAddress,
  //         ),
  //
  //         const SizedBox(height: 12),
  //
  //         _textField(
  //           controller: vendorPhoneController,
  //           label: 'Vendor Phone',
  //           icon: Icons.phone_rounded,
  //           keyboardType: TextInputType.phone,
  //         ),
  //
  //         const SizedBox(height: 12),
  //
  //         _textField(
  //           controller: vendorAddressController,
  //           label: 'Company Address',
  //           icon: Icons.location_on_rounded,
  //           maxLines: 2,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ============================================================
  // CUSTOMER
  // ============================================================

  Widget _customerCard() {
    return _card(
      child: Column(
        children: [
          _textField(
            controller: customerNameController,
            label: 'Customer Name',
            icon: Icons.person_rounded,
          ),

          const SizedBox(height: 12),

          _textField(
            controller: customerEmailController,
            label: 'Customer Email',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 12),

          _textField(
            controller: customerPhoneController,
            label: 'Customer Phone',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEMS
  // ============================================================

  Widget _itemsCard() {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _itemCard(item, index),
          );
        }),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                items.add(InvoiceItemForm());
              });
            },
            icon: Icon(Icons.add_rounded, color: primaryColor),
            label: Text(
              'Add Item',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryColor.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemCard(InvoiceItemForm item, int index) {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: softPrimaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const Spacer(),

              if (items.length > 1)
                IconButton(
                  onPressed: () {
                    _removeItem(item);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.redAccent,
                  tooltip: 'Remove item',
                ),
            ],
          ),

          const SizedBox(height: 12),

          _textField(
            controller: item.nameController,
            label: 'Item Name',
            icon: Icons.inventory_2_rounded,
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: item.quantityController,
                  label: 'Quantity',
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _numberField(
                  controller: item.priceController,
                  label: 'Price',
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: softPrimaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  'Item Total',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                Text(
                  'PKR ${item.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  void _removeItem(InvoiceItemForm item) {
    if (items.length <= 1) return;

    setState(() {
      items.remove(item);
    });

    item.dispose();
  }

  // ============================================================
  // TAX / DISCOUNT
  // ============================================================

  Widget _taxDiscountCard() {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: _numberField(
              controller: taxController,
              label: 'Tax %',
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _numberField(
              controller: discountController,
              label: 'Discount',
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT STATUS
  // ============================================================

  Widget _paymentStatusCard() {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: _statusButton('Pending', Icons.pending_actions_rounded),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _statusButton('Paid', Icons.check_circle_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(String status, IconData icon) {
    final selected = paymentStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          paymentStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? primaryColor : borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : secondaryTextColor),

            const SizedBox(width: 8),

            Text(
              status,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOTAL
  // ============================================================

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', subtotal),

          const SizedBox(height: 10),

          _totalRow('Tax', tax),

          const SizedBox(height: 10),

          _totalRow('Discount', -discount),

          const SizedBox(height: 12),

          Divider(color: borderColor, height: 1),

          const SizedBox(height: 14),

          Row(
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),

              const Spacer(),

              Text(
                'PKR ${total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String title, double amount) {
    final isDiscount = amount < 0;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        const Spacer(),

        Text(
          'PKR ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDiscount
                ? Colors.redAccent
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMMON CARD
  // ============================================================

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // INFO BOX
  // ============================================================

  Widget _infoBox(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: softPrimaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: primaryColor),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10, color: secondaryTextColor),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
        labelStyle: TextStyle(color: secondaryTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  // ============================================================
  // NUMBER FIELD
  // ============================================================

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
        labelStyle: TextStyle(color: secondaryTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

// ================================================================
// INVOICE ITEM FORM
// ================================================================

class InvoiceItemForm {
  final nameController = TextEditingController();

  final quantityController = TextEditingController(text: '1');

  final priceController = TextEditingController(text: '0');

  double get total {
    final quantity = double.tryParse(quantityController.text) ?? 0;

    final price = double.tryParse(priceController.text) ?? 0;

    return quantity * price;
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}
