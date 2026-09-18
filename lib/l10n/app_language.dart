import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppLanguage extends ChangeNotifier {
  static const String spanish = 'es';
  static const String english = 'en';

  String _code = spanish;

  String get code => _code;
  bool get isSpanish => _code == spanish;

  Future<void> load() async {
    try {
      final file = await _languageFile();
      if (await file.exists()) {
        final saved = (await file.readAsString()).trim();
        if (saved == english || saved == spanish) {
          _code = saved;
          notifyListeners();
        }
      }
    } catch (_) {
      // If the preference cannot be read, the app keeps Spanish as default.
    }
  }

  Future<void> setLanguage(String code) async {
    if (code != spanish && code != english) return;
    if (_code == code) return;
    _code = code;
    notifyListeners();
    try {
      final file = await _languageFile();
      await file.writeAsString(code, flush: true);
    } catch (_) {
      // The language still changes for the current session.
    }
  }

  Future<void> toggle() => setLanguage(isSpanish ? english : spanish);

  Future<File> _languageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}warehouse_language.txt');
  }

  String get appName => 'Warehouse Elite';

  String get tagline => isSpanish
      ? 'GESTION PRECISA DE INVENTARIO'
      : 'PRECISION INVENTORY MANAGEMENT';
  String get initializing => isSpanish
      ? 'INICIANDO SESION SEGURA'
      : 'INITIALIZING SECURE SESSION';

  String get home => isSpanish ? 'Inicio' : 'Home';
  String get warehouse => isSpanish ? 'Almacen' : 'Warehouse';
  String get scan => isSpanish ? 'Escanear' : 'Scan';
  String get history => isSpanish ? 'Historial' : 'History';
  String get products => isSpanish ? 'Productos' : 'Products';

  String get welcome => isSpanish ? 'BIENVENIDO' : 'WELCOME';
  String get operationalSummary => isSpanish ? 'Resumen operativo' : 'Operational Summary';
  String get todayInbound => isSpanish ? 'ENTRADAS DE HOY' : 'TODAY INBOUND';
  String get todayOutbound => isSpanish ? 'SALIDAS DE HOY' : 'TODAY OUTBOUND';
  String get lowStockAlerts => isSpanish ? 'ALERTAS DE STOCK BAJO' : 'LOW STOCK ALERTS';
  String get goodsReceipt => isSpanish ? 'Entrada' : 'Goods Receipt';
  String get dispatch => isSpanish ? 'Salida' : 'Dispatch';
  String get critical => isSpanish ? 'Critico' : 'Critical';
  String get quickCenter => isSpanish ? 'Centro de operacion rapida' : 'Quick Action Center';
  String get quickCenterHelp => isSpanish
      ? 'Inicie el escaner para agregar un producto o actualizar el stock.'
      : 'Start the scanner to add a product or update stock status.';
  String get quickBarcodeScan => isSpanish ? 'Escanear codigo rapido' : 'Quick Barcode Scan';
  String get recentMovements => isSpanish ? 'Movimientos recientes' : 'Recent Movements';
  String get seeAll => isSpanish ? 'Ver todo' : 'See All';
  String get noMovementsYet => isSpanish ? 'Todavia no hay movimientos' : 'No movements yet';
  String get productFallback => isSpanish ? 'Producto' : 'Product';
  String get units => isSpanish ? 'unid.' : 'pcs';
  String get edited => isSpanish ? 'Editado' : 'Edited';

  String get productNotFoundAdd => isSpanish
      ? 'No se encontro un producto registrado con este codigo. Puede agregar uno nuevo.'
      : 'No registered product was found with this barcode. You can add a new product.';
  String get addProductAction => isSpanish ? 'AGREGAR PRODUCTO' : 'ADD PRODUCT';
  String get stockInTitle => isSpanish ? 'Entrada - Stock entrante' : 'Goods Receipt - Stock In';
  String get stockOutTitle => isSpanish ? 'Salida - Stock saliente' : 'Dispatch - Stock Out';
  String get countTitle => isSpanish ? 'Conteo - Actualizar stock' : 'Count - Update Stock';
  String get wasteReturnTitle => isSpanish ? 'Mal estado / Devolucion' : 'Waste / Return';
  String get operation => isSpanish ? 'Operacion' : 'Operation';
  String get newStockQuantity => isSpanish ? 'NUEVA CANTIDAD DE STOCK' : 'NEW STOCK QUANTITY';
  String get quantity => isSpanish ? 'CANTIDAD' : 'QUANTITY';
  String get addNoteOptional => isSpanish ? 'Agregar nota (opcional)' : 'Add note (optional)';
  String currentStock(int qty) => isSpanish ? 'Stock actual: $qty unid.' : 'Current stock: $qty pcs';
  String get validQuantityError => isSpanish ? 'Ingrese una cantidad valida' : 'Please enter a valid quantity';
  String savedOperation(String title) => isSpanish ? '$title guardada correctamente.' : '$title saved successfully.';
  String get saveOperation => isSpanish ? 'Guardar operacion' : 'Save Operation';
  String get stockIn => isSpanish ? 'Entrada' : 'Goods Receipt';
  String get stockInSubtitle => isSpanish ? 'Registrar mercancia recibida' : 'Register received goods';
  String get dispatchSubtitle => isSpanish ? 'Preparar productos para salida' : 'Prepare outgoing products';
  String get count => isSpanish ? 'Conteo' : 'Count';
  String get countSubtitle => isSpanish ? 'Confirmar el conteo fisico actual' : 'Confirm current shelf count';
  String get wasteReturn => isSpanish ? 'Mal estado / Devolucion' : 'Waste / Return';
  String get wasteReturnSubtitle => isSpanish ? 'Registrar producto danado o devolucion' : 'Process damaged goods or customer returns';
  String get viewCurrentStock => isSpanish ? 'Ver stock actual' : 'View Current Stock';
  String get viewPrice => isSpanish ? 'Ver precio' : 'View Price';
  String get priceSubtitle => isSpanish ? 'Costo, venta y analisis de ganancia' : 'Cost, sale price and profit analysis';
  String get warehouseLocation => isSpanish ? 'UBICACION EN ALMACEN' : 'WAREHOUSE LOCATION';
  String get notSpecified => isSpanish ? 'No especificado' : 'Not specified';
  String get wrongBarcode => isSpanish ? 'Codigo incorrecto' : 'Wrong Barcode';
  String get newScan => isSpanish ? 'Nueva lectura' : 'New Scan';
  String get activeScanSession => isSpanish ? 'SESION DE ESCANEO ACTIVA' : 'ACTIVE SCAN SESSION';
  String get lastDetectedProduct => isSpanish ? 'ULTIMO PRODUCTO DETECTADO' : 'LAST DETECTED PRODUCT';
  String get productNotFound => isSpanish ? 'No se encontro producto con este codigo' : 'No product found with this barcode';

  String get inventoryManagement => isSpanish ? 'GESTION DE INVENTARIO' : 'INVENTORY MANAGEMENT';
  String get addNewProduct => isSpanish ? 'Agregar nuevo producto' : 'Add New Product';
  String get ok => isSpanish ? 'Aceptar' : 'OK';
  String get productAddedDebug => isSpanish ? 'Producto agregado' : 'Product added';
  String productAdded(String name) => isSpanish ? '$name agregado correctamente.' : '$name added successfully.';
  String get barcodeAlreadyExists => isSpanish ? 'Codigo ya registrado' : 'Barcode Already Registered';
  String get barcodeAlreadyExistsMsg => isSpanish
      ? 'Ya existe un producto con este codigo. Use un codigo diferente.'
      : 'A product already exists with this barcode. Please use a different barcode.';
  String get productNotSaved => isSpanish ? 'No se pudo agregar el producto' : 'Product Could Not Be Added';
  String productSaveError(Object e) => isSpanish ? 'Ocurrio un error: $e' : 'An error occurred: $e';
  String templateSaved(String path) => isSpanish ? 'Plantilla guardada: $path' : 'Template saved: $path';
  String get templateNotCreated => isSpanish ? 'No se pudo crear la plantilla' : 'Template could not be created';
  String get productNameLabel => isSpanish ? 'NOMBRE EN INGLES' : 'ENGLISH NAME';
  String get productNameHint => isSpanish ? 'ej. Industrial Servo Motor' : 'e.g. Industrial Servo Motor';
  String get productNameRequired => isSpanish ? 'El nombre en ingles es obligatorio' : 'English name is required';
  String get spanishProductNameLabel => isSpanish ? 'NOMBRE EN ESPANOL' : 'SPANISH NAME';
  String get spanishProductNameHint => isSpanish ? 'ej. Motor servo industrial' : 'e.g. Motor servo industrial';
  String get categoryLabel => isSpanish ? 'CATEGORIA' : 'CATEGORY';
  String get initialQuantity => isSpanish ? 'CANTIDAD INICIAL' : 'INITIAL QUANTITY';
  String get costPriceLabel => isSpanish ? 'COSTO' : 'COST PRICE';
  String get salePriceLabel => isSpanish ? 'PRECIO DE VENTA' : 'SALE PRICE';
  String get weightLabel => isSpanish ? 'PESO (kg)' : 'WEIGHT (kg)';
  String get optional => isSpanish ? 'Opcional' : 'Optional';
  String get locationLabel => isSpanish ? 'UBICACION EN ALMACEN' : 'WAREHOUSE LOCATION';
  String get locationHint => isSpanish ? 'Zona A - Estante 1' : 'Zone A - Shelf 1';
  String get saving => isSpanish ? 'Guardando...' : 'Saving...';
  String get saveProduct => isSpanish ? 'Guardar producto' : 'Save Product';
  String get bulkAddProducts => isSpanish ? 'Agregar productos en lote' : 'Bulk Add Products';
  String get bulkAddHelp => isSpanish
      ? 'Si tiene muchos productos, cargue su lista de stock al instante.'
      : 'Have many products? Upload your current stock list instantly.';
  String get acceptedFormat => isSpanish ? 'FORMATO ACEPTADO' : 'ACCEPTED FORMAT';
  String get importXlsx => isSpanish ? 'Importar XLSX' : 'Import XLSX';
  String get downloadExcelTemplate => isSpanish ? 'Descargar plantilla Excel' : 'Download Excel Template';
  String get fractionError => isSpanish ? 'La cantidad no puede ser decimal' : 'Quantity cannot be fractional';
  String get validNumberError => isSpanish ? 'Ingrese un numero valido' : 'Enter a valid number';
  String get negativeQuantityError => isSpanish ? 'La cantidad no puede ser menor que cero' : 'Quantity cannot be less than zero';
  String get barcodeSku => isSpanish ? 'CODIGO / SKU' : 'BARCODE / SKU';
  String get barcodeRequired => isSpanish ? 'El codigo es obligatorio' : 'Barcode is required';
  String get scanOrType => isSpanish ? 'Escanee o escriba el codigo' : 'Scan or type manually';

  String get manualBarcodeEntry => isSpanish ? 'Ingreso manual de codigo' : 'Manual Barcode Entry';
  String get enterBarcode => isSpanish ? 'Ingrese el codigo' : 'Enter barcode number';
  String get cancel => isSpanish ? 'Cancelar' : 'Cancel';
  String get searchAction => isSpanish ? 'Buscar' : 'Search';
  String get cameraUnavailable => isSpanish ? 'Camara no disponible\nUse ingreso manual' : 'Camera unavailable\nUse manual entry';
  String get scanBarcodeTitle => isSpanish ? 'Escanear codigo' : 'Scan Barcode';
  String get alignBarcode => isSpanish ? 'ALINEE EL CODIGO EN EL MARCO' : 'ALIGN BARCODE INSIDE FRAME';
  String get torchOn => isSpanish ? 'LUZ' : 'TORCH';
  String get manualEntry => isSpanish ? 'MANUAL' : 'MANUAL';

  String get lowStockProducts => isSpanish ? 'PRODUCTOS CON STOCK BAJO' : 'LOW STOCK PRODUCTS';
  String get inboundProducts => isSpanish ? 'PRODUCTOS CON ENTRADAS' : 'INBOUND PRODUCTS';
  String get outboundProducts => isSpanish ? 'PRODUCTOS CON SALIDAS' : 'OUTBOUND PRODUCTS';
  String get productCatalog => isSpanish ? 'CATALOGO DE PRODUCTOS' : 'PRODUCT CATALOG';
  String allProductsCount(int count) => isSpanish ? 'Todos los productos ($count)' : 'All Products ($count)';
  String get totalProducts => isSpanish ? 'Total productos' : 'Total Products';
  String get lowStock => isSpanish ? 'Stock bajo' : 'Low Stock';
  String get outOfStock => isSpanish ? 'Sin stock' : 'Out of Stock';
  String get newProduct => isSpanish ? 'Nuevo producto' : 'New Product';
  String get searchProductsHint => isSpanish ? 'Buscar por nombre en espanol, ingles, codigo o categoria...' : 'Search Spanish name, English name, barcode or category...';
  String get sortByName => isSpanish ? 'Por nombre' : 'By Name';
  String get sortByStock => isSpanish ? 'Por stock' : 'By Stock';
  String get sortByUpdated => isSpanish ? 'Ultima actualizacion' : 'Last Updated';
  String get inStock => isSpanish ? 'EN STOCK' : 'IN STOCK';
  String get noProductsYet => isSpanish ? 'Todavia no hay productos' : 'No products yet';
  String get startAddingProducts => isSpanish ? 'Empiece agregando un producto' : 'Start by adding a product';
  String get addProduct => isSpanish ? 'Agregar producto' : 'Add Product';

  String get productUpdated => isSpanish ? 'Producto actualizado' : 'Product information updated';
  String get locationNotSpecified => isSpanish ? 'Ubicacion no especificada' : 'Location not specified';
  String get barcodeNo => isSpanish ? 'CODIGO' : 'BARCODE NO';
  String get category => isSpanish ? 'CATEGORIA' : 'CATEGORY';
  String get weight => isSpanish ? 'PESO' : 'WEIGHT';
  String get none => isSpanish ? 'Ninguno' : 'None';
  String get companyCostPrice => isSpanish ? 'COSTO DE COMPRA' : 'COMPANY COST PRICE';
  String get salePrice => isSpanish ? 'PRECIO DE VENTA' : 'SALE PRICE';
  String get recalculateProfit => isSpanish ? 'Recalcular ganancia' : 'Recalculate Profit';
  String get profitAnalysis => isSpanish ? 'Analisis de ganancia' : 'Profit Analysis';
  String get automatic => isSpanish ? 'AUTO' : 'AUTO';
  String get netProfit => isSpanish ? 'GANANCIA NETA' : 'NET PROFIT';
  String get profitRate => isSpanish ? 'MARGEN' : 'PROFIT RATE';
  String get adjustStock => isSpanish ? 'Ajustar stock' : 'Adjust Stock';
  String get adjustStockHelp => isSpanish ? 'Actualice el conteo fisico para esta ubicacion.' : 'Update the physical count for this location.';
  String get currentStockLabel => isSpanish ? 'STOCK ACTUAL' : 'CURRENT STOCK';
  String get availableUnits => isSpanish ? 'Unidades disponibles' : 'Units available';
  String get max => isSpanish ? 'Max' : 'Max';
  String get updateInventory => isSpanish ? 'Actualizar inventario' : 'Update Inventory';

  String movementTypeLabel(String type) {
    switch (type) {
      case 'mal_kabul':
        return isSpanish ? 'Entrada de stock' : 'Stock In';
      case 'sevkiyat':
        return isSpanish ? 'Salida' : 'Dispatch';
      case 'sayim':
        return isSpanish ? 'Conteo' : 'Count';
      case 'fire_iade':
        return isSpanish ? 'Mal estado / Devolucion' : 'Waste / Return';
      default:
        return type;
    }
  }

  String categoryName(String value) {
    if (isSpanish) {
      return _categoryEs[value] ?? value;
    }
    return _categoryEn[value] ?? value;
  }
}

const Map<String, String> _categoryEs = {
  'Genel': 'General',
  'Elektronik': 'Electronica',
  'Donanım': 'Hardware',
  'Ham Madde': 'Materia prima',
  'Güvenlik Ekipmanı': 'Equipo de seguridad',
  'Gıda': 'Alimentos',
  'Tekstil': 'Textil',
  'Diğer': 'Otro',
};

const Map<String, String> _categoryEn = {
  'Genel': 'General',
  'Elektronik': 'Electronics',
  'Donanım': 'Hardware',
  'Ham Madde': 'Raw Material',
  'Güvenlik Ekipmanı': 'Safety Equipment',
  'Gıda': 'Food',
  'Tekstil': 'Textile',
  'Diğer': 'Other',
};
