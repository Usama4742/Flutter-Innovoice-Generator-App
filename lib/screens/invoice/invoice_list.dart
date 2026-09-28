import 'package:flutter/material.dart';
import 'package:innvoice_generator/widgets/theme.dart';
import 'package:provider/provider.dart';

import '../../models/invoice_model.dart';
import '../../provider/invoice_provider.dart';
import 'create_invoice.dart';
import 'invoice_details.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All';

  // ============================================================
  // COLORS
  // ============================================================

  Color get primaryColor => AppTheme.primaryBlue;

  Color get backgroundColor {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color get cardColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  Color get fieldColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? const Color(0xFF252525) : const Color(0xFFF8FAFC);
  }

  Color get borderColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE2E8F0);
  }

  Color get secondaryTextColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF64748B);
  }

  Color get softPrimaryColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return primaryColor.withOpacity(isDark ? 0.18 : 0.08);
  }

  Color get mainTextColor {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Invoice> _getFilteredInvoices(List<Invoice> invoices) {
    final search = searchController.text.trim().toLowerCase();

    return invoices.where((invoice) {
      final matchesSearch =
          invoice.invoiceNumber.toLowerCase().contains(search) ||
          invoice.customerName.toLowerCase().contains(search) ||
          invoice.customerEmail.toLowerCase().contains(search) ||
          invoice.customerPhone.toLowerCase().contains(search) ||
          invoice.vendorCompanyName.toLowerCase().contains(search);

      final matchesFilter =
          selectedFilter == 'All' || invoice.status == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
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
          'Invoices',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: mainTextColor,
        elevation: 8,
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: mainTextColor),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );

          if (!mounted) return;

          await context.read<InvoiceProvider>().loadInvoices();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Invoice',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.invoices.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final invoices = _getFilteredInvoices(provider.invoices);

          return Column(
            children: [
              SizedBox(height: 20),
              _topSection(provider),

              _searchBar(),

              _filterBar(),

              Expanded(
                child: invoices.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: provider.loadInvoices,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                          itemCount: invoices.length,
                          itemBuilder: (context, index) {
                            return _buildInvoiceCard(invoices[index], provider);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // TOP STAT SECTION
  // ============================================================

  Widget _topSection(InvoiceProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              'Total',
              provider.totalInvoices.toString(),
              Icons.receipt_long_rounded,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _statCard(
              'Paid',
              provider.paidInvoices.toString(),
              Icons.check_circle_rounded,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _statCard(
              'Pending',
              provider.pendingInvoices.toString(),
              Icons.pending_actions_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.035,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: softPrimaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),

          const SizedBox(height: 7),

          Text(
            value,
            style: TextStyle(
              color: mainTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: searchController,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search invoices...',
          hintStyle: TextStyle(color: secondaryTextColor),

          prefixIcon: Icon(Icons.search_rounded, color: primaryColor),

          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() {});
                  },
                  icon: Icon(Icons.clear_rounded, color: secondaryTextColor),
                )
              : null,

          filled: true,
          fillColor: Theme.of(context).cardTheme.color,

          contentPadding: const EdgeInsets.symmetric(vertical: 15),

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
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          _filterButton('All'),

          const SizedBox(width: 8),

          _filterButton('Paid'),

          const SizedBox(width: 8),

          _filterButton('Pending'),
        ],
      ),
    );
  }

  Widget _filterButton(String filter) {
    final selected = selectedFilter == filter;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? primaryColor :  Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: selected ? primaryColor : borderColor),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              filter,
              style: TextStyle(
                color: selected ? Colors.white : mainTextColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INVOICE CARD
  // ============================================================

  Widget _buildInvoiceCard(Invoice invoice, InvoiceProvider provider) {
    final isPaid = invoice.status == 'Paid';

    final statusColor = isPaid ? Colors.green : Colors.orange;

    return Dismissible(
      key: ValueKey(invoice.id),

      direction: DismissDirection.endToStart,

      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 25,
        ),
      ),

      confirmDismiss: (_) async {
        return await _confirmDelete(invoice);
      },

      onDismissed: (_) async {
        if (invoice.id != null) {
          await provider.deleteInvoice(invoice.id!);
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
           color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.035,
              ),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: InkWell(
          onTap: () {
            if (invoice.id == null) {
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceDetailsScreen(invoiceId: invoice.id!),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: TextStyle(
                              color: mainTextColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),

                          if (invoice.vendorCompanyName.isNotEmpty) ...[
                            const SizedBox(height: 3),

                            Text(
                              invoice.vendorCompanyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          const SizedBox(height: 3),

                          Text(
                            invoice.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // STATUS
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 5),

                          Text(
                            invoice.status,
                            style: TextStyle(
                              color: isPaid
                                  ? Colors.green
                                  : Colors.orange.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Divider(height: 1, color: borderColor),

                const SizedBox(height: 13),

                // ==================================================
                // DATE / TIME / TOTAL
                // ==================================================
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: primaryColor,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      _formatDate(invoice.invoiceDate),
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: primaryColor,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      _formatTime(invoice.invoiceDate),
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      'PKR ${invoice.total.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<bool> _confirmDelete(Invoice invoice) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: Text(
            'Delete Invoice',
            style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w800),
          ),

          content: Text(
            'Are you sure you want to delete '
            '${invoice.invoiceNumber}?',
            style: TextStyle(color: secondaryTextColor),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    final hasSearch = searchController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
      
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
      
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: softPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 55,
                  color: primaryColor,
                ),
              ),
      
              const SizedBox(height: 22),
      
              Text(
                hasSearch ? 'No matching invoices' : 'No invoices found',
                style: TextStyle(
                  color: mainTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
      
              const SizedBox(height: 8),
      
              Text(
                hasSearch
                    ? 'Try searching with a different invoice number or customer.'
                    : 'Create your invoice to see it here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryTextColor, height: 1.4),
              ),
      
              if (!hasSearch) ...[
                const SizedBox(height: 20),
      
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateInvoiceScreen(),
                      ),
                    );
      
                    if (!mounted) return;
      
                    context.read<InvoiceProvider>().loadInvoices();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // TIME
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
