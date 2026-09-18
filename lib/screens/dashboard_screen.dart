import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../services/database_helper.dart';
import '../models/stock_movement.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/language_switch_button.dart';
import 'barcode_scanner_screen.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  Map<String, dynamic> _stats = {'inbound': 0, 'outbound': 0, 'lowStock': 0, 'totalProducts': 0};
  List<StockMovement> _recentMovements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await DatabaseHelper.instance.getTodayStats();
    final movements = await DatabaseHelper.instance.getRecentMovements(limit: 10);
    if (mounted) {
      setState(() {
        _stats = stats;
        _recentMovements = movements;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()))
        .then((_) => _loadData());
      return;
    }
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()))
        .then((_) => _loadData());
      return;
    }
    if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()))
        .then((_) => _loadData());
      return;
    }
    setState(() => _navIndex = index);
  }

  void _openFilteredList(String filterType) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProductListScreen(initialFilter: filterType),
    )).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguage>();
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true, floating: false,
                  backgroundColor: AppColors.surface, surfaceTintColor: Colors.transparent,
                  title: Text(language.appName),
                  leading: IconButton(icon: const Icon(Icons.menu, color: AppColors.navyDark), onPressed: () {}),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        LanguageSwitchButton(),
                        SizedBox(width: 10),
                        CircleAvatar(radius: 20, backgroundColor: AppColors.primaryContainer,
                          child: Icon(Icons.person, color: AppColors.onPrimaryContainer, size: 20)),
                      ]),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 16),
                      Text(language.welcome, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(language.operationalSummary, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, color: AppColors.onPrimaryContainer)),
                      const SizedBox(height: 24),

                      // Tappable stat cards
                      GestureDetector(
                        onTap: () => _openFilteredList('inbound'),
                        child: _buildStatCard(
                          icon: Icons.input, iconColor: AppColors.secondary,
                          title: language.todayInbound, value: NumberFormat('#,###').format(_stats['inbound']),
                          badgeText: language.goodsReceipt, badgeColor: AppColors.secondaryContainer,
                          badgeTextColor: AppColors.onSecondaryContainer, borderColor: AppColors.secondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _openFilteredList('outbound'),
                        child: _buildStatCard(
                          icon: Icons.output, iconColor: AppColors.primary,
                          title: language.todayOutbound, value: NumberFormat('#,###').format(_stats['outbound']),
                          badgeText: language.dispatch, badgeColor: AppColors.primaryContainer.withValues(alpha: 0.2),
                          badgeTextColor: AppColors.onPrimaryContainer, borderColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _openFilteredList('lowStock'),
                        child: _buildStatCard(
                          icon: Icons.warning_amber_rounded, iconColor: AppColors.error,
                          title: language.lowStockAlerts, value: _stats['lowStock'].toString(),
                          badgeText: language.critical, badgeColor: AppColors.errorContainer,
                          badgeTextColor: AppColors.onErrorContainer, borderColor: AppColors.error,
                          valueColor: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildQuickScanSection(language),
                      const SizedBox(height: 32),

                      _buildRecentActivity(language),
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomNavBar(currentIndex: _navIndex, onTap: _onNavTap),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon, required Color iconColor, required String title, required String value,
    required String badgeText, required Color badgeColor, required Color badgeTextColor,
    required Color borderColor, Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.navyDark.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: iconColor, size: 28),
          const Icon(Icons.chevron_right, color: AppColors.outlineVariant, size: 20),
        ]),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSecondaryContainer)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(value, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -2, color: valueColor ?? AppColors.onSurface)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(999)),
            child: Text(badgeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeTextColor)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildQuickScanSection(AppLanguage language) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(40)),
      child: Stack(children: [
        Positioned(top: -60, left: -40, child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.1)))),
        Positioned(bottom: -60, right: -40, child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary.withValues(alpha: 0.1)))),
        Column(children: [
          Text(language.quickCenter, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onPrimaryContainer)),
          const SizedBox(height: 8),
          Text(language.quickCenterHelp,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen())).then((_) => _loadData()),
            child: Column(children: [
              Container(width: 128, height: 128,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDim]),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 48, offset: const Offset(0, 24))]),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 56)),
              const SizedBox(height: 16),
              Text(language.quickBarcodeScan, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.onPrimaryContainer)),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildRecentActivity(AppLanguage language) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(language.recentMovements, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        TextButton(onPressed: () {}, child: Text(language.seeAll, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
        child: _recentMovements.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(language.noMovementsYet, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14))))
            : Column(children: _recentMovements.map((m) => _buildActivityItem(m, language)).toList()),
      ),
    ]);
  }

  Widget _buildActivityItem(StockMovement movement, AppLanguage language) {
    Color iconBg, quantityColor;
    String quantityText;
    IconData icon;

    switch (movement.type) {
      case 'mal_kabul':
        iconBg = AppColors.secondaryContainer; quantityColor = AppColors.primary;
        quantityText = '+${movement.quantity} ${language.units}'; icon = Icons.inventory_2;
        break;
      case 'sevkiyat':
        iconBg = AppColors.tertiaryContainer; quantityColor = AppColors.error;
        quantityText = '-${movement.quantity} ${language.units}'; icon = Icons.local_shipping;
        break;
      case 'fire_iade':
        iconBg = AppColors.tertiaryContainer; quantityColor = AppColors.error;
        quantityText = '-${movement.quantity} ${language.units}'; icon = Icons.recycling;
        break;
      case 'sayim':
        iconBg = AppColors.surfaceContainerHighest; quantityColor = AppColors.onSurfaceVariant;
        quantityText = '${movement.quantity} ${language.units}'; icon = Icons.calculate;
        break;
      default:
        iconBg = AppColors.surfaceContainerHighest; quantityColor = AppColors.onSurfaceVariant;
        quantityText = language.edited; icon = Icons.edit;
    }

    final timeStr = DateFormat('HH:mm').format(movement.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.onSecondaryContainer, size: 22)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(movement.productName ?? language.productFallback, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.onSurface)),
          const SizedBox(height: 2),
          Text(language.movementTypeLabel(movement.type), style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(quantityText, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: quantityColor)),
          const SizedBox(height: 2),
          Text(timeStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: -0.3, color: AppColors.onSurfaceVariant)),
        ]),
      ]),
    );
  }
}






