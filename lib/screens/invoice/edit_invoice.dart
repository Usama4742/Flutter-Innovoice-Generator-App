import 'package:flutter/material.dart';
import 'package:innvoice_generator/models/invoice_model.dart';
import 'package:innvoice_generator/provider/invoice_provider.dart';
import 'package:innvoice_generator/screens/vendor_settings.dart';
import 'package:innvoice_generator/widgets/theme.dart';
import 'package:provider/provider.dart';

class EditInvoiceScreen extends StatefulWidget {
  final Invoice invoice;

  const EditInvoiceScreen({super.key, required this.invoice});

  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController vendorCompanyController;
  late final TextEditingController vendorNameController;
  late final TextEditingController vendorEmailController;
  late final TextEditingController vendorPhoneController;
  late final TextEditingController vendorAddressController;

  late final TextEditingController customerNameController;
  late final TextEditingController customerEmailController;
  late final TextEditingController customerPhoneController;

  late DateTime selectedDateTime;
  late String selectedStatus;

  bool isSaving = false;

  // ============================================================
  // COLORS
  // ============================================================

  Color get primaryColor => const Color(0xFF2563EB);

  Color get mainTextColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

  Color get secondaryTextColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF64748B);
  }

  Color get borderColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE2E8F0);
  }

  Color get cardColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  Color get fieldColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? const Color(0xFF252525) : const Color(0xFFF8FAFC);
  }

  Color get softPrimaryColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return primaryColor.withOpacity(isDark ? 0.18 : 0.08);
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final invoice = widget.invoice;

    vendorCompanyController = TextEditingController(
      text: invoice.vendorCompanyName,
    );

    vendorNameController = TextEditingController(text: invoice.vendorName);

    vendorEmailController = TextEditingController(text: invoice.vendorEmail);

    vendorPhoneController = TextEditingController(text: invoice.vendorPhone);

    vendorAddressController = TextEditingController(
      text: invoice.vendorAddress,
    );

    customerNameController = TextEditingController(text: invoice.customerName);

    customerEmailController = TextEditingController(
      text: invoice.customerEmail,
    );

    customerPhoneController = TextEditingController(
      text: invoice.customerPhone,
    );

    selectedDateTime = invoice.invoiceDate;

    selectedStatus = invoice.status;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    vendorCompanyController.dispose();
    vendorNameController.dispose();
    vendorEmailController.dispose();
    vendorPhoneController.dispose();
    vendorAddressController.dispose();

    customerNameController.dispose();
    customerEmailController.dispose();
    customerPhoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
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
      selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        selectedDateTime.hour,
        selectedDateTime.minute,
      );
    });
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
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
      selectedDateTime = DateTime(
        selectedDateTime.year,
        selectedDateTime.month,
        selectedDateTime.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _updateInvoice() async {
    if (widget.invoice.id == null) {
      _showMessage('Invoice ID is missing.', isError: true);
      return;
    }

    if (customerNameController.text.trim().isEmpty) {
      _showMessage('Customer name is required.', isError: true);
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final updatedMap = Map<String, dynamic>.from(widget.invoice.toMap());

      updatedMap['id'] = widget.invoice.id;

      updatedMap['invoice_number'] = widget.invoice.invoiceNumber;

      updatedMap['vendor_company_name'] = vendorCompanyController.text.trim();

      updatedMap['vendor_name'] = vendorNameController.text.trim();

      updatedMap['vendor_email'] = vendorEmailController.text.trim();

      updatedMap['vendor_phone'] = vendorPhoneController.text.trim();

      updatedMap['vendor_address'] = vendorAddressController.text.trim();

      updatedMap['customer_name'] = customerNameController.text.trim();

      updatedMap['customer_email'] = customerEmailController.text.trim();

      updatedMap['customer_phone'] = customerPhoneController.text.trim();

      updatedMap['invoice_date'] = selectedDateTime.toIso8601String();

      updatedMap['status'] = selectedStatus;

      final updatedInvoice = Invoice.fromMap(updatedMap);

      await context.read<InvoiceProvider>().updateInvoice(updatedInvoice);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage('Could not update invoice: $e', isError: true);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          'Edit Invoice',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 8,
        titleSpacing: 20,
        shadowColor: Colors.white.withOpacity(0.20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _invoiceNumberCard(),

            const SizedBox(height: 16),

            // _vendorSection(),
            _card(
              child: Row(
                children: [
                  Text(
                    'To Update the Company / Vendors. \nPlease Go to Settings',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VendorSettingsScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey.shade600,),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _customerSection(),

            const SizedBox(height: 16),

            _dateTimeSection(),

            const SizedBox(height: 16),

            _statusSection(),

            const SizedBox(height: 25),

            _updateButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INVOICE NUMBER
  // ============================================================

  Widget _invoiceNumberCard() {
    return _card(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: softPrimaryColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: primaryColor,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice Number',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.invoice.invoiceNumber,
                  style: TextStyle(
                    color: mainTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Fixed',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VENDOR
  // ============================================================

  // Widget _vendorSection() {
  //   return _section(
  //     title: 'Vendor / Company',
  //     icon: Icons.business_rounded,
  //     children: [
  //       _textField(
  //         controller: vendorCompanyController,
  //         label: 'Company Name',
  //         icon: Icons.business_rounded,
  //       ),

  //       const SizedBox(height: 12),

  //       _textField(
  //         controller: vendorNameController,
  //         label: 'Vendor / Owner Name',
  //         icon: Icons.person_outline_rounded,
  //       ),

  //       const SizedBox(height: 12),

  //       _textField(
  //         controller: vendorEmailController,
  //         label: 'Email',
  //         icon: Icons.email_outlined,
  //         keyboardType: TextInputType.emailAddress,
  //       ),

  //       const SizedBox(height: 12),

  //       _textField(
  //         controller: vendorPhoneController,
  //         label: 'Phone',
  //         icon: Icons.phone_outlined,
  //         keyboardType: TextInputType.phone,
  //       ),

  //       const SizedBox(height: 12),

  //       _textField(
  //         controller: vendorAddressController,
  //         label: 'Address',
  //         icon: Icons.location_on_outlined,
  //         maxLines: 2,
  //       ),
  //     ],
  //   );
  // }

  // ============================================================
  // CUSTOMER
  // ============================================================

  Widget _customerSection() {
    return _section(
      title: 'Customer',
      icon: Icons.person_rounded,
      children: [
        _textField(
          controller: customerNameController,
          label: 'Customer Name',
          icon: Icons.person_outline_rounded,
        ),

        const SizedBox(height: 12),

        _textField(
          controller: customerEmailController,
          label: 'Customer Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 12),

        _textField(
          controller: customerPhoneController,
          label: 'Customer Phone',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  Widget _dateTimeSection() {
    return _section(
      title: 'Date & Time',
      icon: Icons.calendar_month_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: _dateTimeButton(
                icon: Icons.calendar_today_rounded,
                title: 'Date',
                value: _formatDate(selectedDateTime),
                onTap: _selectDate,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _dateTimeButton(
                icon: Icons.access_time_rounded,
                title: 'Time',
                value: _formatTime(selectedDateTime),
                onTap: _selectTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusSection() {
    return _section(
      title: 'Payment Status',
      icon: Icons.payments_rounded,
      children: [
        DropdownButtonFormField<String>(
          value: selectedStatus,
          dropdownColor: Theme.of(context).cardTheme.color,
          decoration: InputDecoration(
            labelText: 'Payment Status',
            prefixIcon: Icon(Icons.payments_outlined, color: primaryColor),
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'Paid', child: Text('Paid')),
            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
            DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
            DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedStatus = value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // DATE/TIME BUTTON
  // ============================================================

  Widget _dateTimeButton({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: secondaryTextColor, fontSize: 10),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    value,
                    style: TextStyle(
                      color: mainTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: secondaryTextColor),
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: softPrimaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryColor, size: 19),
              ),

              const SizedBox(width: 9),

              Text(
                title,
                style: TextStyle(
                  color: mainTextColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // CARD
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
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // UPDATE BUTTON
  // ============================================================

  Widget _updateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : _updateInvoice,
        icon: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          isSaving ? 'Updating...' : 'Update Invoice',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // FORMAT TIME
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
