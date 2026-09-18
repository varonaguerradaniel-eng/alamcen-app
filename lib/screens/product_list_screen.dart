import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/language_switch_button.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String? initialFilter; // 'lowStock', 'inbound', 'outbound'
  const ProductListScreen({super.key, this.initialFilter});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _sortBy = 'name'; // name, quantity, updated

  String _filterTitle(AppLanguage language) {
    switch (widget.initialFilter) {
      case 'lowStock': return language.lowStockProducts;
      case 'inbound': return language.inboundProducts;
      case 'outbound': return language.outboundProducts;
      default: return language.productCatalog;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    _filtered = _products.where((p) {
      // Apply initial filter first
      if (widget.initialFilter == 'lowStock' && p.quantity > 25) return false;
      if (widget.initialFilter == 'outbound' && p.quantity == 0) return false;
      
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    switch (_sortBy) {
      case 'name':
        _filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'quantity':
        _filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'updated':
        _filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguage>();
    final fmt = NumberFormat('#,##0.00', language.isSpanish ? 'es' : 'en_US');
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true, floating: true,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.navyDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(language.appName, style: TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5)),
          actions: const [Padding(padding: EdgeInsets.only(right: 16), child: LanguageSwitchButton())],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: _buildSearchBar(language),
            ),
          ),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Text(_filterTitle(language), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primary)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(language.allProductsCount(_filtered.length),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              _buildSortButton(language),
            ]),
            const SizedBox(height: 16),
            // Stats row
            Row(children: [
              _miniStat(language.totalProducts, _products.length.toString(), Icons.inventory_2, AppColors.primary),
              const SizedBox(width: 12),
              _miniStat(language.lowStock, _products.where((p) => p.quantity <= 25).length.toString(), Icons.warning_amber, AppColors.error),
              const SizedBox(width: 12),
              _miniStat(language.outOfStock, _products.where((p) => p.quantity == 0).length.toString(), Icons.block, AppColors.tertiary),
            ]),
            const SizedBox(height: 24),
          ]),
        )),
        if (_loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_filtered.isEmpty)
          SliverFillRemaining(child: _buildEmptyState(language))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _filtered.length) return const SizedBox(height: 100);
                  return _buildProductCard(_filtered[index], fmt, language);
                },
                childCount: _filtered.length + 1,
              ),
            ),
          ),
      ]),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDim]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())).then((_) => _load()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(language.newProduct, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLanguage language) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() => _applyFilter()),
        decoration: InputDecoration(
          hintText: language.searchProductsHint,
          hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 22),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.onSurfaceVariant),
                  onPressed: () { _searchCtrl.clear(); setState(() => _applyFilter()); })
              : null,
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSortButton(AppLanguage language) {
    return PopupMenuButton<String>(
      onSelected: (v) => setState(() { _sortBy = v; _applyFilter(); }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.sort, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            _sortBy == 'name' ? language.sortByName : _sortBy == 'quantity' ? language.sortByStock : language.sortByUpdated,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
          ),
        ]),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'name', child: Text(language.sortByName)),
        PopupMenuItem(value: 'quantity', child: Text(language.sortByStock)),
        PopupMenuItem(value: 'updated', child: Text(language.sortByUpdated)),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color, letterSpacing: -1)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
      ]),
    ));
  }

  Widget _buildProductCard(Product p, NumberFormat fmt, AppLanguage language) {
    Color stockColor;
    String stockLabel;
    if (p.quantity == 0) {
      stockColor = AppColors.error;
      stockLabel = language.outOfStock.toUpperCase();
    } else if (p.quantity <= 25) {
      stockColor = const Color(0xFFe65100);
      stockLabel = language.lowStock.toUpperCase();
    } else {
      stockColor = AppColors.onSecondaryContainer;
      stockLabel = language.inStock;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: p),
      )).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.navyDark.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          // Product icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                child: Text(language.categoryName(p.category), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.qr_code, size: 12, color: AppColors.outline),
              const SizedBox(width: 2),
              Text(p.barcode.length > 10 ? '${p.barcode.substring(0, 10)}...' : p.barcode,
                style: const TextStyle(fontSize: 11, color: AppColors.outline)),
            ]),
          ])),
          const SizedBox(width: 12),
          // Right side: stock + price
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              Text('${p.quantity}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: stockColor)),
              Text(' ${language.units}', style: TextStyle(fontSize: 12, color: stockColor.withValues(alpha: 0.7))),
            ]),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(stockLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: stockColor)),
            ),
            if (p.salePrice > 0) ...[
              const SizedBox(height: 4),
              Text('₺${fmt.format(p.salePrice)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(AppLanguage language) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
        child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.outlineVariant),
      ),
      const SizedBox(height: 24),
      Text(language.noProductsYet, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
      const SizedBox(height: 8),
      Text(language.startAddingProducts, style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())).then((_) => _load()),
        icon: const Icon(Icons.add),
        label: Text(language.addProduct),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      ),
    ]));
  }
}







