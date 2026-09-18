import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/language_switch_button.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../services/xlsx_import_service.dart';
import 'barcode_scanner_screen.dart';

class AddProductScreen extends StatefulWidget {
  final String? initialBarcode;
  const AddProductScreen({super.key, this.initialBarcode});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _costCtrl = TextEditingController(text: '0');
  final _saleCtrl = TextEditingController(text: '0');
  final _locationCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _category = 'Genel';
  bool _saving = false;

  final _categories = ['Genel', 'Elektronik', 'Donanım', 'Ham Madde', 'Güvenlik Ekipmanı', 'Gıda', 'Tekstil', 'Diğer'];

  @override
  void initState() {
    super.initState();
    if (widget.initialBarcode != null) _barcodeCtrl.text = widget.initialBarcode!;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _barcodeCtrl.dispose(); _qtyCtrl.dispose();
    _costCtrl.dispose(); _saleCtrl.dispose(); _locationCtrl.dispose(); _weightCtrl.dispose();
    super.dispose();
  }

  void _showErrorAlert(String title, String message) {
    final language = context.read<AppLanguage>();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppColors.errorContainer.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: const Icon(Icons.error_outline, color: AppColors.error, size: 32),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.onSurface)),
      content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
      actions: [
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Text(language.ok, style: TextStyle(fontWeight: FontWeight.w700)),
        )),
      ],
    ));
  }

  Future<void> _registerProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final product = Product(
        barcode: _barcodeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        category: _category,
        quantity: int.tryParse(_qtyCtrl.text) ?? 0,
        costPrice: double.tryParse(_costCtrl.text) ?? 0,
        salePrice: double.tryParse(_saleCtrl.text) ?? 0,
        location: _locationCtrl.text.trim(),
        weight: _weightCtrl.text.isNotEmpty ? double.tryParse(_weightCtrl.text) : null,
      );

      await DatabaseHelper.instance.insertProduct(product);
      debugPrint('Product added: ${product.name}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<AppLanguage>().productAdded(product.name)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Product add error: $e');
      if (mounted) {
        if (e.toString().contains('UNIQUE')) {
          final language = context.read<AppLanguage>();
          _showErrorAlert(language.barcodeAlreadyExists, language.barcodeAlreadyExistsMsg);
        } else {
          final language = context.read<AppLanguage>();
          _showErrorAlert(language.productNotSaved, language.productSaveError(e));
        }
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _importXlsx() async {
    final result = await XlsxImportService.importFromFile(languageCode: context.read<AppLanguage>().code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.primary : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _downloadTemplate() async {
    final path = await XlsxImportService.generateTemplate();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(path != null ? context.read<AppLanguage>().templateSaved(path) : context.read<AppLanguage>().templateNotCreated),
        backgroundColor: path != null ? AppColors.primary : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // Auto-select all text when tapping into a "0" field
  void _onTapSelectAll(TextEditingController ctrl) {
    if (ctrl.text == '0') {
      ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
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
            const SizedBox(height: 16),
            Text(language.inventoryManagement, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(language.addNewProduct, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            const SizedBox(height: 24),
            Form(key: _formKey, child: Column(children: [
              _buildField(language.productNameLabel, _nameCtrl, language.productNameHint,
                validator: (v) => v == null || v.isEmpty ? language.productNameRequired : null),
              const SizedBox(height: 20),
              _buildDropdown(language),
              const SizedBox(height: 20),
              _buildBarcodeField(language),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildField(language.initialQuantity, _qtyCtrl, '0',
                  type: TextInputType.number,
                  onTap: () => _onTapSelectAll(_qtyCtrl),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null; // 0 default
                    if (v.contains(',') || v.contains('.')) return language.fractionError;
                    final n = int.tryParse(v);
                    if (n == null) return language.validNumberError;
                    if (n < 0) return language.negativeQuantityError;
                    return null;
                  })),
                const SizedBox(width: 16),
                Expanded(child: _buildField(language.costPriceLabel, _costCtrl, '0',
                  type: const TextInputType.numberWithOptions(decimal: true),
                  onTap: () => _onTapSelectAll(_costCtrl))),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildField(language.salePriceLabel, _saleCtrl, '0',
                  type: const TextInputType.numberWithOptions(decimal: true),
                  onTap: () => _onTapSelectAll(_saleCtrl))),
                const SizedBox(width: 16),
                Expanded(child: _buildField(language.weightLabel, _weightCtrl, language.optional,
                  type: const TextInputType.numberWithOptions(decimal: true))),
              ]),
              const SizedBox(height: 20),
              _buildField(language.locationLabel, _locationCtrl, language.locationHint),
            ])),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 56, child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDim]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.navyDark.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 4))]),
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _registerProduct,
                icon: const Icon(Icons.add_circle, color: Colors.white),
                label: Text(_saving ? language.saving : language.saveProduct,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
            )),
            const SizedBox(height: 32),
            // Bulk Import Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(language.bulkAddProducts, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Text(language.bulkAddHelp,
                  style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2), width: 2, strokeAlign: BorderSide.strokeAlignInside)),
                  child: Column(children: [
                    Container(width: 64, height: 64,
                      decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                      child: const Icon(Icons.upload_file, size: 32, color: AppColors.onSecondaryContainer)),
                    const SizedBox(height: 16),
                    Text(language.acceptedFormat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.secondary)),
                    const SizedBox(height: 4),
                    const Text('Microsoft Excel (.xlsx)', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
                      onPressed: _importXlsx,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.onSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: Text(language.importXlsx, style: TextStyle(fontWeight: FontWeight.w700)))),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1)))),
                  child: GestureDetector(onTap: _downloadTemplate,
                    child: Row(children: [
                      const Icon(Icons.download, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(language.downloadExcelTemplate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ])),
                ),
              ]),
            ),
            const SizedBox(height: 48),
          ]),
        )),
      ]),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text, String? Function(String?)? validator, VoidCallback? onTap}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 8),
      TextFormField(controller: ctrl, keyboardType: type, validator: validator,
        onTap: onTap,
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.outlineVariant),
          filled: true, fillColor: AppColors.surfaceContainerHigh,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16))),
    ]);
  }

  Widget _buildDropdown(AppLanguage language) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(language.categoryLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onSurfaceVariant)),
    const SizedBox(height: 8),
    DropdownButtonFormField<String>(
      initialValue: _category,
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(language.categoryName(c)))).toList(),
      onChanged: (v) => setState(() => _category = v!),
      decoration: InputDecoration(filled: true, fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
    ),
  ]);

  Widget _buildBarcodeField(AppLanguage language) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(language.barcodeSku, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.onSurfaceVariant)),
    const SizedBox(height: 8),
    TextFormField(controller: _barcodeCtrl,
      validator: (v) => v == null || v.isEmpty ? language.barcodeRequired : null,
      decoration: InputDecoration(hintText: language.scanOrType, hintStyle: const TextStyle(color: AppColors.outlineVariant),
        filled: true, fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        suffixIcon: GestureDetector(
          onTap: () async {
            // Open scanner in barcode-only mode — returns just the string
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const BarcodeScannerScreen(returnBarcodeOnly: true)),
            );
            if (result != null) {
              setState(() => _barcodeCtrl.text = result);
            }
          },
          child: Container(margin: const EdgeInsets.all(8), width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
            child: const Icon(Icons.qr_code_scanner, color: AppColors.primary)),
        ),
      )),
  ]);
}











