import 'package:flutter/material.dart';
import 'theme.dart';

class VendorSettingsCard extends StatelessWidget {
  final Map<String, String> settings;
  final VoidCallback? onEdit;
  final bool showEditButton;

  const VendorSettingsCard({
    super.key,
    required this.settings,
    this.onEdit,
    this.showEditButton = false,
  });

  String _value(String key) {
    final value = settings[key]?.trim() ?? '';

    if (value.isEmpty) {
      return 'Not set';
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final companyName = _value('companyName');
    final vendorName = _value('vendorName');
    final email = _value('email');
    final phone = _value('phone');
    final address = _value('address');

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final cardColor =
        Theme.of(context).cardTheme.color ??
        (isDark
            ? const Color(0xFF1E1E1E)
            : Colors.white);

    final secondaryColor = isDark
        ? Colors.white70
        : const Color(0xFF64748B);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? 0.15 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue
                      .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: AppTheme.primaryBlue,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      vendorName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              if (showEditButton)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_rounded,
                  ),
                  color:
                      AppTheme.primaryBlue,
                  tooltip:
                      'Edit company settings',
                ),
            ],
          ),

          const SizedBox(height: 18),

          _infoRow(
            context,
            Icons.email_rounded,
            'Email',
            email,
          ),

          const SizedBox(height: 10),

          _infoRow(
            context,
            Icons.phone_rounded,
            'Phone',
            phone,
          ),

          const SizedBox(height: 10),

          _infoRow(
            context,
            Icons.location_on_rounded,
            'Address',
            address,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final secondaryColor = isDark
        ? Colors.white70
        : const Color(0xFF64748B);

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: AppTheme.primaryBlue,
        ),

        const SizedBox(width: 10),

        Text(
          '$title: ',
          style: TextStyle(
            color: secondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}