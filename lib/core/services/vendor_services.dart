import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VendorSettingsService {
  static const String companyNameKey = 'vendor_company_name';
  static const String vendorNameKey = 'vendor_name';
  static const String emailKey = 'vendor_email';
  static const String phoneKey = 'vendor_phone';
  static const String addressKey = 'vendor_address';

  // Company logo
  static const String companyLogoKey = 'vendor_company_logo';

  static Future<void> saveVendorSettings({
    required String companyName,
    required String vendorName,
    required String email,
    required String phone,
    required String address,
    String? companyLogoBase64,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(companyNameKey, companyName.trim());

    await prefs.setString(vendorNameKey, vendorName.trim());

    await prefs.setString(emailKey, email.trim());

    await prefs.setString(phoneKey, phone.trim());

    await prefs.setString(addressKey, address.trim());

    // Save logo if provided
    if (companyLogoBase64 != null && companyLogoBase64.isNotEmpty) {
      await prefs.setString(companyLogoKey, companyLogoBase64);
    }
  }

  static Future<Map<String, String>> getVendorSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'companyName': prefs.getString(companyNameKey) ?? '',
      'vendorName': prefs.getString(vendorNameKey) ?? '',
      'email': prefs.getString(emailKey) ?? '',
      'phone': prefs.getString(phoneKey) ?? '',
      'address': prefs.getString(addressKey) ?? '',
      'companyLogo': prefs.getString(companyLogoKey) ?? '',
    };
  }

  static Future<String?> getCompanyLogo() async {
    final prefs = await SharedPreferences.getInstance();

    final logo = prefs.getString(companyLogoKey);

    if (logo == null || logo.isEmpty) {
      return null;
    }

    return logo;
  }

  static Future<void> deleteCompanyLogo() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(companyLogoKey);
  }

  static Future<bool> isSettingsConfigured() async {
    final settings = await getVendorSettings();

    return settings['companyName']!.trim().isNotEmpty &&
        settings['vendorName']!.trim().isNotEmpty;
  }
}
