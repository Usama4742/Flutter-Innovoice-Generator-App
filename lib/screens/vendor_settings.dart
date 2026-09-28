import 'package:flutter/material.dart';
import 'package:innvoice_generator/core/services/vendor_services.dart';
import 'package:innvoice_generator/widgets/vendor_setting_card.dart';
import '../widgets/theme.dart';

class VendorSettingsScreen extends StatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  final companyNameController = TextEditingController();

  final vendorNameController = TextEditingController();

  final emailController = TextEditingController();

  final phoneController = TextEditingController();

  final addressController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  Color get primaryColor => AppTheme.primaryBlue;

  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get fieldColor {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252525)
        : const Color(0xFFF8FAFC);
  }

  Color get borderColor {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.10)
        : const Color(0xFFE2E8F0);
  }

  Color get mainTextColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

  Color get secondaryTextColor {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.65)
        : const Color(0xFF64748B);
  }

  @override
  void initState() {
    super.initState();

    _loadSettings();

    companyNameController.addListener(_refreshPreview);

    vendorNameController.addListener(_refreshPreview);

    emailController.addListener(_refreshPreview);

    phoneController.addListener(_refreshPreview);

    addressController.addListener(_refreshPreview);
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    final settings = await VendorSettingsService.getVendorSettings();

    companyNameController.text = settings['companyName'] ?? '';

    vendorNameController.text = settings['vendorName'] ?? '';

    emailController.text = settings['email'] ?? '';

    phoneController.text = settings['phone'] ?? '';

    addressController.text = settings['address'] ?? '';

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final companyName = companyNameController.text.trim();

    final vendorName = vendorNameController.text.trim();

    if (companyName.isEmpty) {
      _showMessage('Please enter company name.', Colors.redAccent);
      return;
    }

    if (vendorName.isEmpty) {
      _showMessage('Please enter vendor / owner name.', Colors.redAccent);
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await VendorSettingsService.saveVendorSettings(
        companyName: companyName,
        vendorName: vendorName,
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage(
        'Company and vendor details saved successfully.',
        Colors.green,
      );

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage('Could not save settings: $e', Colors.redAccent);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Map<String, String> get _currentSettings {
    return {
      'companyName': companyNameController.text,
      'vendorName': vendorNameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'address': addressController.text,
    };
  }

  @override
  void dispose() {
    companyNameController.dispose();
    vendorNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 8,
        titleSpacing: 20,
        shadowColor: Colors.white.withOpacity(0.20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),

                  const SizedBox(height: 20),

                  _sectionTitle('Company Information'),

                  const SizedBox(height: 10),

                  _input(
                    controller: companyNameController,
                    label: 'Company Name',
                    hint: 'Enter company name',
                    icon: Icons.business_rounded,
                  ),

                  const SizedBox(height: 14),

                  _input(
                    controller: vendorNameController,
                    label: 'Vendor / Owner Name',
                    hint: 'Enter vendor or owner name',
                    icon: Icons.person_rounded,
                  ),

                  const SizedBox(height: 20),

                  _sectionTitle('Contact Information'),

                  const SizedBox(height: 10),

                  _input(
                    controller: emailController,
                    label: 'Email',
                    hint: 'Enter company email',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 14),

                  _input(
                    controller: phoneController,
                    label: 'Phone',
                    hint: 'Enter phone number',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 14),

                  _input(
                    controller: addressController,
                    label: 'Address',
                    hint: 'Enter company address',
                    icon: Icons.location_on_rounded,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 28),

                  _sectionTitle('Business Preview'),

                  const SizedBox(height: 10),

                  VendorSettingsCard(settings: _currentSettings),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _saveSettings,
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
                        isSaving ? 'Saving...' : 'Save Company Details',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryColor.withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'These details will automatically be used as the default vendor information when creating a new invoice.',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Set the information that appears on your invoices.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: mainTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: mainTextColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: secondaryTextColor),
        hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        // fillColor: fieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }
}
