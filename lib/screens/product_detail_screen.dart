import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/language_switch_button.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String initialTab;
  const ProductDetailScreen({super.key, required this.product, this.initialTab = 'stock'});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  late TextEditingController _costCtrl, _saleCtrl, _qtyCtrl;
  final _fmt = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _costCtrl = TextEditingController(text: _fmt.format(_product.costPrice));
    _saleCtrl = TextEditingController(text: _fmt.format(_product.salePrice));
    _qtyCtrl = TextEditingController(text: _product.quantity.toString());
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    _saleCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  double _parse(String t) => double.tryParse(t.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  double get _cost => _parse(_costCtrl.text);
  double get _sale => _parse(_saleCtrl.text);
  double get _profit => _sale - _cost;
  double get _margin => _cost > 0 ? (_profit / _cost) * 100 : 0;

  void _adjustQty(int d) {
    int c = int.tryParse(_qtyCtrl.text) ?? 0;
    c += d;
    if (c < 0) c = 0;
    _qtyCtrl.text = c.toString();
    setState(() {});
  }

  Future<void> _save() async {
    _product = _product.copyWith(
      quantity: int.tryParse(_qtyCtrl.text) ?? _product.quantity,
      costPrice: _cost.isFinite ? _cost : _product.costPrice,
      salePrice: _sale.isFinite ? _sale : _product.salePrice,
      updatedAt: DateTime.now(),
    );
    await DatabaseHelper.instance.updateProduct(_product);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.read<AppLanguage>().productUpdated),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      setState(() {});
    }
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
          title: Text(language.appName, style: TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.w700, fontSize: 20)),
          actions: const [Padding(padding: EdgeInsets.only(right: 16), child: LanguageSwitchButton())],
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            // Identity
            Text('SKU-${_product.id ?? "00000"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.outline)),
            const SizedBox(height: 4),
            Text(_product.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1, color: AppColors.onSurface, height: 1.1)),
            const SizedBox(height: 12),
            _locationAndStatus(language),
            const SizedBox(height: 32),
            _productInfoCard(language),
            const SizedBox(height: 24),
            _priceModule(language),
            const SizedBox(height: 24),
            _inventoryPanel(language),
            const SizedBox(height: 48),
          ]),
        )),
      ]),
    );
  }

  Widget _locationAndStatus(AppLanguage language) => Row(children: [
    const Icon(Icons.location_on, color: AppColors.outline, size: 16), const SizedBox(width: 4),
    Text(_product.location.isEmpty ? language.locationNotSpecified : _product.location.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onSurfaceVariant)),
    const Spacer(),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(_product.quantity > 0 ? Icons.check_circle : Icons.warning, size: 16,
          color: _product.quantity > 0 ? AppColors.onSecondaryContainer : AppColors.error),
        const SizedBox(width: 4),
        Text(_product.quantity > 0 ? language.inStock : language.outOfStock.toUpperCase(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            color: _product.quantity > 0 ? AppColors.onSecondaryContainer : AppColors.error)),
      ]),
    ),
  ]);

  Widget _productInfoCard(AppLanguage language) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppColors.navyDark.withValues(alpha: 0.06), blurRadius: 48, offset: const Offset(0, 24))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(language.barcodeNo), const SizedBox(height: 4),
      Row(children: [const Icon(Icons.qr_code, color: AppColors.primary, size: 22), const SizedBox(width: 8),
        Text(_product.barcode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.onSurface))]),
      const SizedBox(height: 16), Container(height: 1, color: AppColors.surfaceContainerHigh), const SizedBox(height: 16),
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(language.category), const SizedBox(height: 4),
        Text(language.categoryName(_product.category), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
      ])), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(language.weight), const SizedBox(height: 4),
        Text(_product.weight != null ? '${_product.weight} kg' : language.none, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
      ]))]),
    ]),
  );

  Widget _priceModule(AppLanguage language) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
    child: Column(children: [
      _priceInput(language.companyCostPrice, _costCtrl, Icons.payments, AppColors.secondary),
      const SizedBox(height: 16),
      _priceInput(language.salePrice, _saleCtrl, Icons.sell, AppColors.primary),
      const SizedBox(height: 16),
      _profitCard(language),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () => setState(() {}), icon: const Icon(Icons.calculate, size: 18),
        label: Text(language.recalculateProfit),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant,
          backgroundColor: Colors.white.withValues(alpha: 0.6), side: BorderSide(color: AppColors.surfaceContainerHigh),
          padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      )),
    ]),
  );

  Widget _profitCard(AppLanguage language) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFe8f5e9), Color(0xFFc8e6c9)]),
      borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFa5d6a7).withValues(alpha: 0.5))),
    child: Stack(children: [
      Positioned(right: -8, top: -8, child: Icon(Icons.trending_up, size: 80, color: const Color(0xFF1b5e20).withValues(alpha: 0.1))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [const Icon(Icons.analytics, color: Color(0xFF2e7d32), size: 22), const SizedBox(width: 8),
            Text(language.profitAnalysis, style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1b5e20)))]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF2e7d32), borderRadius: BorderRadius.circular(999)),
            child: Text(language.automatic, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(language.netProfit, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: const Color(0xFF1b5e20).withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Text('₺${_fmt.format(_profit)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Color(0xFF1b5e20))),
          ])),
          Container(width: 1, height: 40, color: const Color(0xFF1b5e20).withValues(alpha: 0.1)),
          const SizedBox(width: 24),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(language.profitRate, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: const Color(0xFF1b5e20).withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Row(children: [
              Text('%${_margin.toStringAsFixed(1)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Color(0xFF1b5e20))),
              const SizedBox(width: 4),
              Icon(_profit >= 0 ? Icons.north_east : Icons.south_east, color: const Color(0xFF2e7d32), size: 20),
            ]),
          ])),
        ]),
      ]),
    ]),
  );

  Widget _inventoryPanel(AppLanguage language) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(language.adjustStock, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
      const SizedBox(height: 4),
      Text(language.adjustStockHelp, style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 24),
      // Hero number
      Container(width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)]),
        child: Column(children: [
          _label(language.currentStockLabel), const SizedBox(height: 8),
          Text(_qtyCtrl.text, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700, letterSpacing: -3, color: AppColors.onPrimaryContainer)),
          Text(language.availableUnits, style: TextStyle(fontSize: 13, color: AppColors.secondaryDim)),
        ]),
      ),
      const SizedBox(height: 16),
      // Stepper
      Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5))),
        child: Row(children: [
          _stepBtn(Icons.remove, () => _adjustQty(-1), false),
          Expanded(child: TextField(controller: _qtyCtrl, textAlign: TextAlign.center, keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            decoration: const InputDecoration(border: InputBorder.none, filled: false))),
          _stepBtn(Icons.add, () => _adjustQty(1), true),
        ]),
      ),
      const SizedBox(height: 12),
      // Presets
      Row(children: [
        _preset('+10', () => _adjustQty(10)), const SizedBox(width: 8),
        _preset('+50', () => _adjustQty(50)), const SizedBox(width: 8),
        _preset(language.max, () { _qtyCtrl.text = '9999'; setState(() {}); }),
      ]),
      const SizedBox(height: 24),
      // Save
      SizedBox(width: double.infinity, height: 56, child: DecoratedBox(
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDim]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 12))]),
        child: ElevatedButton.icon(onPressed: _save,
          icon: const Icon(Icons.sync, color: Colors.white),
          label: Text(language.updateInventory, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
      )),
    ]),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.outline));

  Widget _priceInput(String label, TextEditingController ctrl, IconData icon, Color ic) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label), const SizedBox(height: 8),
      Row(children: [Icon(icon, color: ic, size: 24), const SizedBox(width: 12),
        Expanded(child: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface),
          decoration: const InputDecoration(border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero, isDense: true,
            prefixText: '₺', prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface)))),
      ]),
    ]),
  );

  Widget _stepBtn(IconData ic, VoidCallback fn, bool pr) => GestureDetector(onTap: fn, child: Container(
    width: 64, height: 64,
    decoration: BoxDecoration(color: pr ? AppColors.primary : AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(12),
      boxShadow: pr ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : null),
    child: Icon(ic, color: pr ? AppColors.onPrimary : AppColors.primary, size: 28),
  ));

  Widget _preset(String l, VoidCallback fn) => Expanded(child: GestureDetector(onTap: fn, child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceContainerHigh)),
    child: Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.onSurfaceVariant))),
  )));
}





