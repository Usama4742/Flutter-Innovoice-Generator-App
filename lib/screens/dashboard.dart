import 'package:flutter/material.dart';
import 'package:innvoice_generator/models/invoice_model.dart';
import 'package:innvoice_generator/provider/invoice_provider.dart';
import 'package:innvoice_generator/screens/invoice/create_invoice.dart';
import 'package:innvoice_generator/screens/invoice/invoice_details.dart';
import 'package:innvoice_generator/screens/invoice/invoice_list.dart';
import 'package:innvoice_generator/screens/invoice/scanner_screen.dart';
import 'package:innvoice_generator/widgets/drawer.dart';
import 'package:innvoice_generator/widgets/theme.dart';
import 'package:provider/provider.dart';
import 'package:innvoice_generator/core/services/vendor_services.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedPeriod = 0;

  final List<String> periods = ['Week', 'Month', 'Year'];

  String companyName = '';

  @override
  void initState() {
    super.initState();
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    final settings = await VendorSettingsService.getVendorSettings();

    if (!mounted) return;

    setState(() {
      companyName = settings['companyName']?.trim() ?? '';
    });
  }

  // ================================================================
  // REVENUE CHART DATA
  // ================================================================

  List<double> _getRevenueChartData(List<Invoice> invoices) {
    final now = DateTime.now();

    switch (selectedPeriod) {
      // ------------------------------------------------------------
      // WEEK - LAST 7 DAYS
      // ------------------------------------------------------------
      case 0:
        final values = List<double>.filled(7, 0);

        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        for (final invoice in invoices) {
          final date = invoice.invoiceDate;

          final invoiceDay = DateTime(
            date.year,
            date.month,
            date.day,
          );

          final difference = today.difference(invoiceDay).inDays;

          if (difference >= 0 && difference < 7) {
            final index = 6 - difference;

            values[index] += invoice.total;
          }
        }

        return values;

      // ------------------------------------------------------------
      // MONTH - 5 PERIODS
      // ------------------------------------------------------------
      case 1:
        final values = List<double>.filled(5, 0);

        for (final invoice in invoices) {
          final date = invoice.invoiceDate;

          if (date.year == now.year && date.month == now.month) {
            final day = date.day;

            int index;

            if (day <= 7) {
              index = 0;
            } else if (day <= 14) {
              index = 1;
            } else if (day <= 21) {
              index = 2;
            } else if (day <= 28) {
              index = 3;
            } else {
              index = 4;
            }

            values[index] += invoice.total;
          }
        }

        return values;

      // ------------------------------------------------------------
      // YEAR - 12 MONTHS
      // ------------------------------------------------------------
      case 2:
        final values = List<double>.filled(12, 0);

        for (final invoice in invoices) {
          final date = invoice.invoiceDate;

          if (date.year == now.year) {
            final index = date.month - 1;

            values[index] += invoice.total;
          }
        }

        return values;

      default:
        return List<double>.filled(7, 0);
    }
  }

  // ================================================================
  // REVENUE CHART LABELS
  // ================================================================

  List<String> _getChartLabels() {
    switch (selectedPeriod) {
      // ------------------------------------------------------------
      // WEEK
      // ------------------------------------------------------------
      case 0:
        final now = DateTime.now();

        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        const days = [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ];

        return List.generate(7, (index) {
          final date = today.subtract(
            Duration(days: 6 - index),
          );

          return days[date.weekday - 1];
        });

      // ------------------------------------------------------------
      // MONTH
      // ------------------------------------------------------------
      case 1:
        return [
          '1-7',
          '8-14',
          '15-21',
          '22-28',
          '29-31',
        ];

      // ------------------------------------------------------------
      // YEAR
      // ------------------------------------------------------------
      case 2:
        return [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

      default:
        return [];
    }
  }

  // ================================================================
  // FORMAT CHART VALUE
  // ================================================================

  String _formatChartValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();

    final theme = Theme.of(context);

    final invoices = invoiceProvider.invoices;

    final filteredInvoices = _getFilteredInvoices(invoices);

    final revenue = filteredInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.total,
    );

    final paidCount = invoices
        .where(
          (invoice) =>
              invoice.status.toLowerCase() == 'paid',
        )
        .length;

    final pendingCount = invoices
        .where(
          (invoice) =>
              invoice.status.toLowerCase() == 'pending',
        )
        .length;

    final recentInvoices = invoices.take(5).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      drawer: const AppDrawer(),

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 8,
        titleSpacing: 20,
        shadowColor: Colors.white.withOpacity(0.20),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              companyName.isNotEmpty
                  ? companyName
                  : 'Dashboard',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),

        actions: [
          // QR SCANNER
          _appBarButton(
            context,
            icon: Icons.qr_code_scanner_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScanInvoiceScreen(),
                ),
              );
            },
          ),

          const SizedBox(width: 6),

          // SEARCH
          _appBarButton(
            context,
            icon: Icons.search_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InvoiceListScreen(),
                ),
              );
            },
          ),

          const SizedBox(width: 6),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: invoiceProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryBlue,
                ),
              )
            : RefreshIndicator(
                onRefresh: invoiceProvider.loadInvoices,
                color: AppTheme.primaryBlue,

                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),

                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    120,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // REVENUE CARD
                      // ==================================================

                      _buildRevenueCard(
                        context,
                        revenue: revenue,
                        invoices: filteredInvoices,
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // STATISTICS
                      // ==================================================

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.receipt_long_rounded,
                              title: 'Invoices',
                              value: invoiceProvider
                                  .totalInvoices
                                  .toString(),
                              subtitle: 'Total invoices',
                              iconColor:
                                  AppTheme.primaryBlue,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon:
                                  Icons.check_circle_outline_rounded,
                              title: 'Paid',
                              value: paidCount.toString(),
                              subtitle: 'Paid invoices',
                              iconColor: Colors.green,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon:
                                  Icons.pending_actions_rounded,
                              title: 'Pending',
                              value:
                                  pendingCount.toString(),
                              subtitle: 'Need attention',
                              iconColor: Colors.orange,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.payments_rounded,
                              title: 'Paid Revenue',
                              value: _formatCurrency(
                                invoiceProvider.paidRevenue,
                              ),
                              subtitle: 'Total collected',
                              iconColor: Colors.purple,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // QUICK ACTIONS
                      // ==================================================

                      _sectionHeader(
                        context,
                        title: 'Quick Actions',
                        subtitle:
                            'Manage your invoices faster',
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAction(
                              context,
                              icon:
                                  Icons.add_circle_outline_rounded,
                              title: 'New Invoice',
                              color:
                                  AppTheme.primaryBlue,
                              onTap: () {
                                _openCreateInvoice(
                                  context,
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _buildQuickAction(
                              context,
                              icon:
                                  Icons.qr_code_scanner_rounded,
                              title: 'Scan Invoice',
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ScanInvoiceScreen(),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _buildQuickAction(
                              context,
                              icon:
                                  Icons.picture_as_pdf_rounded,
                              title: 'Invoices',
                              color: Colors.redAccent,
                              onTap: () {
                                _openInvoiceList(
                                  context,
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // RECENT INVOICES
                      // ==================================================

                      _sectionHeader(
                        context,
                        title: 'Recent Invoices',
                        subtitle:
                            'Your latest transactions',
                        actionText: 'View All',
                        onActionTap: () {
                          _openInvoiceList(context);
                        },
                      ),

                      const SizedBox(height: 14),

                      if (recentInvoices.isEmpty)
                        _buildEmptyInvoices(context)
                      else
                        ...recentInvoices.map(
                          (invoice) => Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _buildInvoiceCard(
                              context,
                              invoice: invoice,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),

      // ============================================================
      // FLOATING ACTION BUTTON
      // ============================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          _openCreateInvoice(context);
        },

        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,

        icon: const Icon(Icons.create),

        label: const Text(
          'Create Invoice',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ================================================================
  // FILTER INVOICES BY PERIOD
  // ================================================================

  List<Invoice> _getFilteredInvoices(
    List<Invoice> invoices,
  ) {
    final now = DateTime.now();

    late DateTime startDate;

    switch (selectedPeriod) {
      case 0:
        // Last 7 calendar days
        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        startDate = today.subtract(
          const Duration(days: 6),
        );

        break;

      case 1:
        // Current month
        startDate = DateTime(
          now.year,
          now.month,
          1,
        );

        break;

      case 2:
        // Current year
        startDate = DateTime(
          now.year,
          1,
          1,
        );

        break;

      default:
        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        startDate = today.subtract(
          const Duration(days: 6),
        );
    }

    return invoices.where((invoice) {
      final date = invoice.invoiceDate;

      return date.isAfter(startDate) ||
          date.isAtSameMomentAs(startDate);
    }).toList();
  }

  // ================================================================
  // REVENUE CARD
  // ================================================================

  Widget _buildRevenueCard(
    BuildContext context, {
    required double revenue,
    required List<Invoice> invoices,
  }) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    final growth = _calculateGrowth(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: isDark
              ? const [
                  Color(0xFF102B4A),
                  Color(0xFF0B1D32),
                ]
              : const [
                  Color(0xFFE8F3FF),
                  Color(0xFFF7FBFF),
                ],
        ),

        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(
            isDark ? 0.18 : 0.10,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ========================================================
          // HEADER
          // ========================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue
                          .withOpacity(0.15),

                      borderRadius:
                          BorderRadius.circular(12),
                    ),

                    child: const Icon(
                      Icons
                          .account_balance_wallet_rounded,
                      color:
                          AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Total Revenue',
                    style: TextStyle(
                      color: theme
                          .colorScheme
                          .onSurface
                          .withOpacity(0.65),

                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // ====================================================
              // PERIOD SELECTOR
              // ====================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: theme
                      .colorScheme
                      .onSurface
                      .withOpacity(0.06),

                  borderRadius:
                      BorderRadius.circular(10),
                ),

                child: Row(
                  children:
                      List.generate(
                    periods.length,
                    (index) {
                      final selected =
                          selectedPeriod ==
                              index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedPeriod =
                                index;
                          });
                        },

                        child:
                            AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds: 200,
                          ),

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),

                          decoration:
                              BoxDecoration(
                            color: selected
                                ? AppTheme
                                    .primaryBlue
                                : Colors
                                    .transparent,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              7,
                            ),
                          ),

                          child: Text(
                            periods[index],

                            style: TextStyle(
                              fontSize: 11,

                              fontWeight:
                                  FontWeight
                                      .w600,

                              color: selected
                                  ? Colors.white
                                  : theme
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(
                                        0.55,
                                      ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ========================================================
          // REVENUE
          // ========================================================

          Text(
            _formatCurrency(revenue),

            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color:
                  theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 10),

          // ========================================================
          // GROWTH
          // ========================================================

          Row(
            children: [
              if (growth != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),

                  decoration:
                      BoxDecoration(
                    color: growth >= 0
                        ? Colors.green
                            .withOpacity(0.12)
                        : Colors.red
                            .withOpacity(0.12),

                    borderRadius:
                        BorderRadius.circular(8),
                  ),

                  child: Row(
                    children: [
                      Icon(
                        growth >= 0
                            ? Icons
                                .arrow_upward_rounded
                            : Icons
                                .arrow_downward_rounded,

                        size: 13,

                        color: growth >= 0
                            ? Colors.green
                            : Colors.red,
                      ),

                      const SizedBox(width: 2),

                      Text(
                        '${growth.abs().toStringAsFixed(1)}%',

                        style: TextStyle(
                          color: growth >= 0
                              ? Colors.green
                              : Colors.red,

                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

              if (growth != null)
                const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'compared to previous period',

                  style: TextStyle(
                    fontSize: 12,
                    color: theme
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ========================================================
          // LABELED REVENUE CHART
          // ========================================================

          _buildRevenueChart(
            context,
            values:
                _getRevenueChartData(invoices),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // REVENUE BAR CHART
  // ================================================================

  Widget _buildRevenueChart(
    BuildContext context, {
    required List<double> values,
  }) {
    final theme = Theme.of(context);

    final labels = _getChartLabels();

    double maxValue = 0;

    for (final value in values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }

    if (maxValue <= 0) {
      maxValue = 1;
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(
        8,
        12,
        8,
        10,
      ),

      decoration: BoxDecoration(
        color: AppTheme.primaryBlue
            .withOpacity(0.06),

        borderRadius:
            BorderRadius.circular(14),
      ),

      child: SizedBox(
        height: selectedPeriod == 2
            ? 150
            : 135,

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: List.generate(
            values.length,
            (index) {
              final value = values[index];

              final double barHeight;

              if (value <= 0) {
                barHeight = 4;
              } else {
                barHeight =
                    ((value / maxValue) * 78)
                        .clamp(4.0, 78.0);
              }

              return Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 2,
                  ),

                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.end,

                    children: [
                      // ==================================================
                      // VALUE ABOVE BAR
                      // ==================================================

                      SizedBox(
                        height: 18,

                        child: value > 0
                            ? Text(
                                _formatChartValue(
                                  value,
                                ),

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                textAlign:
                                    TextAlign.center,

                                style: TextStyle(
                                  fontSize:
                                      selectedPeriod ==
                                              2
                                          ? 7
                                          : 8,

                                  fontWeight:
                                      FontWeight
                                          .w700,

                                  color: theme
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(
                                        0.55,
                                      ),
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(height: 4),

                      // ==================================================
                      // BAR
                      // ==================================================

                      AnimatedContainer(
                        duration:
                            const Duration(
                          milliseconds: 350,
                        ),

                        curve:
                            Curves.easeOutCubic,

                        width: double.infinity,

                        height: barHeight,

                        decoration:
                            BoxDecoration(
                          color:
                              AppTheme.primaryBlue,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==================================================
                      // LABEL
                      // ==================================================

                      SizedBox(
                        height: 18,

                        child: Text(
                          labels[index],

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            fontSize:
                                selectedPeriod ==
                                        2
                                    ? 8
                                    : 9,

                            fontWeight:
                                FontWeight.w600,

                            color: theme
                                .colorScheme
                                .onSurface
                                .withOpacity(
                                  0.55,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CALCULATE GROWTH
  // ================================================================

  double? _calculateGrowth(
    BuildContext context,
  ) {
    final provider =
        context.read<InvoiceProvider>();

    final invoices = provider.invoices;

    if (invoices.isEmpty) {
      return null;
    }

    final now = DateTime.now();

    late DateTime currentStart;
    late DateTime previousStart;
    late DateTime previousEnd;

    switch (selectedPeriod) {
      case 0:
        // Current 7 days vs previous 7 days

        final today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        currentStart = today.subtract(
          const Duration(days: 6),
        );

        previousStart = today.subtract(
          const Duration(days: 13),
        );

        previousEnd = currentStart;

        break;

      case 1:
        // Current month vs previous month

        currentStart = DateTime(
          now.year,
          now.month,
          1,
        );

        previousStart = DateTime(
          now.year,
          now.month - 1,
          1,
        );

        previousEnd = currentStart;

        break;

      case 2:
        // Current year vs previous year

        currentStart = DateTime(
          now.year,
          1,
          1,
        );

        previousStart = DateTime(
          now.year - 1,
          1,
          1,
        );

        previousEnd = currentStart;

        break;

      default:
        return null;
    }

    double currentRevenue = 0;

    double previousRevenue = 0;

    for (final invoice in invoices) {
      final date = invoice.invoiceDate;

      // CURRENT PERIOD
      if (date.isAfter(currentStart) ||
          date.isAtSameMomentAs(
            currentStart,
          )) {
        currentRevenue += invoice.total;
      }

      // PREVIOUS PERIOD
      if ((date.isAfter(previousStart) ||
              date.isAtSameMomentAs(
                previousStart,
              )) &&
          date.isBefore(previousEnd)) {
        previousRevenue += invoice.total;
      }
    }

    if (previousRevenue == 0) {
      return null;
    }

    return ((currentRevenue - previousRevenue) /
            previousRevenue) *
        100;
  }

  // ================================================================
  // STAT CARD
  // ================================================================

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: theme.cardTheme.color,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: theme.dividerColor
              .withOpacity(0.25),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            padding:
                const EdgeInsets.all(9),

            decoration: BoxDecoration(
              color:
                  iconColor.withOpacity(0.12),

              borderRadius:
                  BorderRadius.circular(11),
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            value,

            maxLines: 1,

            overflow:
                TextOverflow.ellipsis,

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color:
                  theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,

            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme
                  .colorScheme
                  .onSurface
                  .withOpacity(0.65),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            subtitle,

            style: TextStyle(
              fontSize: 10,
              color: theme
                  .colorScheme
                  .onSurface
                  .withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // QUICK ACTION
  // ================================================================

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 15,
        ),

        decoration: BoxDecoration(
          color: theme.cardTheme.color,

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: theme.dividerColor
                .withOpacity(0.25),
          ),
        ),

        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(11),

              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.12),

                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              title,

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                color: theme
                    .colorScheme
                    .onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DYNAMIC INVOICE CARD
  // ================================================================

  Widget _buildInvoiceCard(
    BuildContext context, {
    required Invoice invoice,
  }) {
    final theme = Theme.of(context);

    final bool isPaid =
        invoice.status.toLowerCase() ==
            'paid';

    final Color statusColor =
        isPaid ? Colors.green : Colors.orange;

    final DateTime invoiceDate =
        invoice.invoiceDate;

    return InkWell(
      borderRadius:
          BorderRadius.circular(18),

      onTap: () {
        if (invoice.id == null) {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                InvoiceDetailsScreen(
              invoiceId: invoice.id!,
            ),
          ),
        );
      },

      child: Container(
        padding:
            const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: theme.cardTheme.color,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: theme.dividerColor
                .withOpacity(0.25),
          ),
        ),

        child: Row(
          children: [
            // ======================================================
            // ICON
            // ======================================================

            Container(
              height: 48,
              width: 48,

              decoration: BoxDecoration(
                color: AppTheme.primaryBlue
                    .withOpacity(0.10),

                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: const Icon(
                Icons.receipt_long_rounded,
                color:
                    AppTheme.primaryBlue,
                size: 22,
              ),
            ),

            const SizedBox(width: 13),

            // ======================================================
            // INFORMATION
            // ======================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          invoice.invoiceNumber,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                            color: theme
                                .colorScheme
                                .onSurface,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),

                        decoration:
                            BoxDecoration(
                          color: statusColor
                              .withOpacity(
                            0.10,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            6,
                          ),
                        ),

                        child: Text(
                          invoice.status,

                          style: TextStyle(
                            color:
                                statusColor,
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    invoice.customerName,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w500,
                      color: theme
                          .colorScheme
                          .onSurface
                          .withOpacity(0.65),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // DATE
                  Row(
                    children: [
                      Icon(
                        Icons
                            .calendar_today_rounded,
                        size: 10,
                        color: theme
                            .colorScheme
                            .onSurface
                            .withOpacity(
                              0.40,
                            ),
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          _formatDate(
                            invoiceDate,
                          ),

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style: TextStyle(
                            fontSize: 10,
                            color: theme
                                .colorScheme
                                .onSurface
                                .withOpacity(
                                  0.40,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // TIME
                  Row(
                    children: [
                      Icon(
                        Icons
                            .access_time_rounded,
                        size: 10,
                        color: theme
                            .colorScheme
                            .onSurface
                            .withOpacity(
                              0.40,
                            ),
                      ),

                      const SizedBox(width: 4),

                      Text(
                        _formatTime(
                          invoiceDate,
                        ),

                        style: TextStyle(
                          fontSize: 10,
                          color: theme
                              .colorScheme
                              .onSurface
                              .withOpacity(
                                0.40,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ======================================================
            // AMOUNT
            // ======================================================

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,

              children: [
                Text(
                  _formatCurrency(
                    invoice.total,
                  ),

                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                    color: theme
                        .colorScheme
                        .onSurface,
                  ),
                ),

                const SizedBox(height: 5),

                Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 12,
                  color: theme
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY INVOICES
  // ================================================================

  Widget _buildEmptyInvoices(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 35,
      ),

      decoration: BoxDecoration(
        color: theme.cardTheme.color,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: theme.dividerColor
              .withOpacity(0.25),
        ),
      ),

      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.all(15),

            decoration: BoxDecoration(
              color: AppTheme.primaryBlue
                  .withOpacity(0.10),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.receipt_long_outlined,
              size: 30,
              color:
                  AppTheme.primaryBlue,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            'No invoices yet',

            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
              color: theme
                  .colorScheme
                  .onSurface,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Create your first invoice and it will appear here.',

            textAlign:
                TextAlign.center,

            style: TextStyle(
              fontSize: 12,
              color: theme
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5),
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: () {
              _openCreateInvoice(
                context,
              );
            },

            icon:
                const Icon(Icons.add_rounded),

            label: const Text(
              'Create Invoice',
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SECTION HEADER
  // ================================================================

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,

      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                  color: theme
                      .colorScheme
                      .onSurface,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,

                style: TextStyle(
                  fontSize: 11,
                  color: theme
                      .colorScheme
                      .onSurface
                      .withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),

        if (actionText != null)
          GestureDetector(
            onTap: onActionTap,

            child: Text(
              actionText,

              style: const TextStyle(
                color:
                    AppTheme.primaryBlue,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ================================================================
  // APP BAR BUTTON
  // ================================================================

  Widget _appBarButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(12),

      child: Container(
        height: 40,
        width: 40,

        decoration: BoxDecoration(
          color: theme.cardTheme.color,

          borderRadius:
              BorderRadius.circular(12),

          border: Border.all(
            color: theme.dividerColor
                .withOpacity(0.25),
          ),
        ),

        child: Icon(
          icon,
          size: 20,
          color:
              theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // ================================================================
  // NAVIGATION
  // ================================================================

  void _openCreateInvoice(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const CreateInvoiceScreen(),
      ),
    );
  }

  void _openInvoiceList(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const InvoiceListScreen(),
      ),
    );
  }

  // ================================================================
  // GREETING
  // ================================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning 👋';
    }

    if (hour < 17) {
      return 'Good afternoon 👋';
    }

    return 'Good evening 👋';
  }

  // ================================================================
  // CURRENCY
  // ================================================================

  String _formatCurrency(
    double amount,
  ) {
    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  // ================================================================
  // DATE
  // ================================================================

  String _formatDate(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ================================================================
  // TIME
  // ================================================================

  String _formatTime(
    DateTime date,
  ) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}