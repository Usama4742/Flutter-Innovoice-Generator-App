import 'package:flutter/material.dart';
import 'package:innvoice_generator/core/services/vendor_services.dart';
import 'package:innvoice_generator/screens/vendor_settings.dart';
import 'theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
  });

  @override
  State<AppDrawer> createState() =>
      _AppDrawerState();
}

class _AppDrawerState
    extends State<AppDrawer> {
  Map<String, String> vendorSettings = {
    'companyName': '',
    'vendorName': '',
    'email': '',
    'phone': '',
    'address': '',
  };

  bool isLoading = true;

  Color get primaryColor =>
      AppTheme.primaryBlue;

  Color get backgroundColor =>
      Theme.of(context)
          .scaffoldBackgroundColor;

  Color get mainTextColor =>
      Theme.of(context)
          .textTheme
          .bodyLarge
          ?.color ??
      Colors.black87;

  Color get secondaryTextColor {
    return Theme.of(context).brightness ==
            Brightness.dark
        ? Colors.white.withOpacity(0.65)
        : const Color(0xFF64748B);
  }

  @override
  void initState() {
    super.initState();

    _loadVendor();
  }

  Future<void> _loadVendor() async {
    final settings =
        await VendorSettingsService
            .getVendorSettings();

    if (!mounted) return;

    setState(() {
      vendorSettings = settings;
      isLoading = false;
    });
  }

  Future<void> _openSettings() async {
    final result =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const VendorSettingsScreen(),
      ),
    );

    if (result == true) {
      await _loadVendor();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _profileHeader(),

            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                children: [
                  _drawerItem(
                    icon:
                        Icons.dashboard_rounded,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                    },
                  ),

                  _drawerItem(
                    icon:
                        Icons.receipt_long_rounded,
                    title: 'Invoices',
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    child: Text(
                      'BUSINESS',
                      style: TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  _drawerItem(
                    icon:
                        Icons.business_rounded,
                    title:
                        'Company Settings',
                    onTap:
                        _openSettings,
                  ),
                ],
              ),
            ),

            _drawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() {
    final companyName =
        vendorSettings['companyName']
                ?.trim() ??
            '';

    final vendorName =
        vendorSettings['vendorName']
                ?.trim() ??
            '';

    final email =
        vendorSettings['email']
                ?.trim() ??
            '';

    final phone =
        vendorSettings['phone']
                ?.trim() ??
            '';

    final hasCompany =
        companyName.isNotEmpty;

    final hasVendor =
        vendorName.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: isLoading
          ? const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(20),
                child:
                    CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            )
          : Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            hasCompany
                                ? companyName
                                : 'Your Company',
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            hasVendor
                                ? vendorName
                                : 'Vendor / Owner',
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (email.isNotEmpty ||
                    phone.isNotEmpty) ...[
                  const SizedBox(height: 16),

                  Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (email.isNotEmpty)
                          _contactRow(
                            Icons.email_rounded,
                            email,
                          ),

                        if (email.isNotEmpty &&
                            phone.isNotEmpty)
                          const SizedBox(
                            height: 7,
                          ),

                        if (phone.isNotEmpty)
                          _contactRow(
                            Icons.phone_rounded,
                            phone,
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _openSettings,
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Edit Company Details',
                    ),
                    style: OutlinedButton
                        .styleFrom(
                      foregroundColor:
                          Colors.white,
                      side: BorderSide(
                        color: Colors.white
                            .withOpacity(0.35),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _contactRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.white70,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(13),
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: primaryColor
              .withOpacity(0.08),
          borderRadius:
              BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          color: primaryColor,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: mainTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: secondaryTextColor,
      ),
    );
  }

  Widget _drawerFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Invoice Generator',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: secondaryTextColor,
          fontSize: 11,
        ),
      ),
    );
  }
}