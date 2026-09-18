import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/language_switch_button.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';
import 'barcode_scanner_screen.dart';

class ActionSelectionScreen extends StatelessWidget {
  final String barcode;
  final Product? product;

  const ActionSelectionScreen({
    super.key,
    required this.barcode,
    this.product,
  });

  void _handleAction(BuildContext context, String actionType) {
    final language = context.read<AppLanguage>();
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language.productNotFoundAdd),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: language.addProductAction,
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddProductScreen(initialBarcode: barcode),
              ));
            },
          ),
        ),
      );
      return;
    }

    if (actionType == 'anlik_stok' || actionType == 'fiyat') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product!,
          initialTab: actionType == 'fiyat' ? 'price' : 'stock',
        ),
      ));
      return;
    }

    _showMovementDialog(context, actionType);
  }

  void _showMovementDialog(BuildContext context, String type) {
    final language = context.read<AppLanguage>();
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String title;
    Color accent;
    IconData icon;

    switch (type) {
      case 'mal_kabul':
        title = language.stockInTitle;
        accent = AppColors.secondary;
        icon = Icons.downloading;
        break;
      case 'sevkiyat':
        title = language.stockOutTitle;
        accent = AppColors.primary;
        icon = Icons.local_shipping;
        break;
      case 'sayim':
        title = language.countTitle;
        accent = AppColors.primary;
        icon = Icons.calculate;
        break;
      case 'fire_iade':
        title = language.wasteReturnTitle;
        accent = AppColors.tertiary;
        icon = Icons.recycling;
        break;
      default:
        title = language.operation;
        accent = AppColors.primary;
        icon = Icons.edit;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accent, size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                Text(product!.name, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
              ])),
            ]),
            const SizedBox(height: 24),
            Text(type == 'sayim' ? language.newStockQuantity : language.quantity, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(controller: qtyCtrl, autofocus: true, keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.onSurface),
              decoration: InputDecoration(hintText: '0', hintStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.outlineVariant),
                filled: true, fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))),
            const SizedBox(height: 16),
            TextField(controller: noteCtrl, decoration: InputDecoration(hintText: language.addNoteOptional, hintStyle: const TextStyle(color: AppColors.outlineVariant),
              filled: true, fillColor: AppColors.surfaceContainerHigh,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            if (type != 'sayim') ...[
              const SizedBox(height: 8),
              Text(language.currentStock(product!.quantity), style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
            ],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text);
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(language.validQuantityError)));
                  return;
                }
                await DatabaseHelper.instance.processStockMovement(product: product!, type: type, quantity: qty,
                  note: noteCtrl.text.isEmpty ? null : noteCtrl.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(language.savedOperation(title)),
                    backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              child: Text(language.saveOperation),
            )),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguage>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true, backgroundColor: AppColors.surface, surfaceTintColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.navyDark), onPressed: () => Navigator.pop(context)),
          title: Text(language.appName, style: TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5)),
          actions: const [Padding(padding: EdgeInsets.only(right: 16), child: LanguageSwitchButton())],
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            // Scanned Item Header
            _buildHeader(language),
            const SizedBox(height: 24),

            // ACTION GRID - matching original design
            // Mal Kabul (secondary-container)
            _actionCard(
              context: context,
              title: language.stockIn,
              subtitle: language.stockInSubtitle,
              icon: Icons.downloading,
              bgIcon: Icons.input,
              bgColor: AppColors.secondaryContainer,
              textColor: AppColors.onSecondaryContainer,
              onTap: () => _handleAction(context, 'mal_kabul'),
            ),
            const SizedBox(height: 16),

            // Sevkiyat (primary-container)
            _actionCard(
              context: context,
              title: language.dispatch,
              subtitle: language.dispatchSubtitle,
              icon: Icons.local_shipping,
              bgIcon: Icons.output,
              bgColor: AppColors.primaryContainer,
              textColor: AppColors.onPrimaryContainer,
              onTap: () => _handleAction(context, 'sevkiyat'),
            ),
            const SizedBox(height: 16),

            // Sayım (white, bordered)
            _actionCard(
              context: context,
              title: language.count,
              subtitle: language.countSubtitle,
              icon: Icons.calculate,
              bgIcon: Icons.inventory,
              bgColor: AppColors.surfaceContainerLowest,
              textColor: AppColors.onSurface,
              iconContainerColor: AppColors.surfaceContainerLow,
              bordered: true,
              onTap: () => _handleAction(context, 'sayim'),
            ),
            const SizedBox(height: 16),

            // Fire/İade (tertiary-container, horizontal)
            _actionCardHorizontal(
              context: context,
              title: language.wasteReturn,
              subtitle: language.wasteReturnSubtitle,
              icon: Icons.recycling,
              bgIcon: Icons.assignment_return,
              bgColor: AppColors.tertiaryContainer,
              textColor: AppColors.onTertiaryContainer,
              onTap: () => _handleAction(context, 'fire_iade'),
            ),
            const SizedBox(height: 16),

            // Anlık Stok (dark inverse-surface)
            _actionCard(
              context: context,
              title: language.viewCurrentStock,
              subtitle: '',
              icon: Icons.visibility,
              bgIcon: Icons.bar_chart,
              bgColor: AppColors.inverseSurface,
              textColor: Colors.white,
              iconContainerColor: Colors.white.withValues(alpha: 0.1),
              bgIconOpacity: 0.05,
              smallTitle: true,
              onTap: () => _handleAction(context, 'anlik_stok'),
            ),
            const SizedBox(height: 16),

            // Fiyat Görüntüle (green)
            _actionCard(
              context: context,
              title: language.viewPrice,
              subtitle: language.priceSubtitle,
              icon: Icons.sell,
              bgIcon: Icons.analytics,
              bgColor: const Color(0xFFe8f5e9),
              textColor: const Color(0xFF1b5e20),
              onTap: () => _handleAction(context, 'fiyat'),
            ),
            const SizedBox(height: 32),

            // Bottom section
            if (product != null)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(language.warehouseLocation, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(product!.location.isEmpty ? language.notSpecified : product!.location,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                ]),
              ]),
            const SizedBox(height: 16),
            Row(children: [
              OutlinedButton(onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                child: Text(language.wrongBarcode, style: TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(width: 12),
              Expanded(child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDim]),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))]),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen())),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(language.newScan, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white))),
              )),
            ]),
            const SizedBox(height: 48),
          ]),
        )),
      ]),
    );
  }

  Widget _buildHeader(AppLanguage language) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.navyDark.withValues(alpha: 0.02), blurRadius: 24, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(language.activeScanSession, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(barcode, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: AppColors.onPrimaryContainer)),
        if (product != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
                child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(language.lastDetectedProduct, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(product!.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              ])),
            ]),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.errorContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(language.productNotFound, style: const TextStyle(fontSize: 13, color: AppColors.error))),
            ]),
          ),
        ],
      ]),
    );
  }

  // Vertical action card (like Mal Kabul, Sevkiyat, Sayım)
  Widget _actionCard({
    required BuildContext context, required String title, required String subtitle,
    required IconData icon, required IconData bgIcon, required Color bgColor,
    required Color textColor, required VoidCallback onTap,
    bool bordered = false, Color? iconContainerColor, double bgIconOpacity = 0.15,
    bool smallTitle = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: bordered ? Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconContainerColor ?? AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: textColor, size: 28)),
            Icon(bgIcon, size: 56, color: textColor.withValues(alpha: bgIconOpacity)),
          ]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: smallTitle ? 16 : 22, fontWeight: FontWeight.w700, color: textColor)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.7))),
          ],
        ]),
      ),
    );
  }

  // Horizontal action card (like Fire/İade)
  Widget _actionCardHorizontal({
    required BuildContext context, required String title, required String subtitle,
    required IconData icon, required IconData bgIcon, required Color bgColor,
    required Color textColor, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLowest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: textColor, size: 28)),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.7))),
          ])),
          Icon(bgIcon, size: 72, color: textColor.withValues(alpha: 0.1)),
        ]),
      ),
    );
  }
}





