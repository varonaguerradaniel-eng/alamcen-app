import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import 'database_helper.dart';

class XlsxImportService {
  static Future<XlsxImportResult> importFromFile({String languageCode = 'es'}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        return XlsxImportResult(
          success: false,
          message: _msg(languageCode, 'No se selecciono ningun archivo.', 'No file selected.'),
          importedCount: 0,
        );
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        return XlsxImportResult(
          success: false,
          message: _msg(languageCode, 'No se encontro la ruta del archivo.', 'File path was not found.'),
          importedCount: 0,
        );
      }

      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables.values.first;
      if (sheet.rows.isEmpty) {
        return XlsxImportResult(
          success: false,
          message: _msg(languageCode, 'El archivo Excel esta vacio.', 'The Excel file is empty.'),
          importedCount: 0,
        );
      }

      // Expected columns: Codigo, Producto, Producto Espanol, Categoria, Cantidad, Costo, Precio de venta, Ubicacion, Peso
      final products = <Product>[];
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty || row[0]?.value == null) continue;

        try {
          final barcode = _cellToString(row[0]?.value);
          final name = row.length > 1 ? _cellToString(row[1]?.value) : '';
          final spanishName = row.length > 2 ? _cellToString(row[2]?.value) : '';
          final category = row.length > 3 ? _cellToString(row[3]?.value) : 'Genel';
          final quantity = row.length > 4 ? _cellToInt(row[4]?.value) : 0;
          final costPrice = row.length > 5 ? _cellToDouble(row[5]?.value) : 0.0;
          final salePrice = row.length > 6 ? _cellToDouble(row[6]?.value) : 0.0;
          final location = row.length > 7 ? _cellToString(row[7]?.value) : '';
          final weight = row.length > 8 ? _cellToDoubleNullable(row[8]?.value) : null;

          if (barcode.isNotEmpty && name.isNotEmpty) {
            products.add(Product(
              barcode: barcode,
              name: name,
              spanishName: spanishName,
              category: category,
              quantity: quantity,
              costPrice: costPrice,
              salePrice: salePrice,
              location: location,
              weight: weight,
            ));
          }
        } catch (e) {
          debugPrint('Row $i parse error: $e');
        }
      }

      if (products.isEmpty) {
        return XlsxImportResult(
          success: false,
          message: _msg(languageCode, 'No se encontraron productos validos en el archivo.', 'No valid products were found in the file.'),
          importedCount: 0,
        );
      }

      final count = await DatabaseHelper.instance.bulkInsertProducts(products);

      return XlsxImportResult(
        success: true,
        message: _msg(languageCode, '$count productos importados correctamente.', '$count products imported successfully.'),
        importedCount: count,
        totalFound: products.length,
      );
    } catch (e) {
      return XlsxImportResult(
        success: false,
        message: _msg(languageCode, 'Error al importar: $e', 'Import error: $e'),
        importedCount: 0,
      );
    }
  }

  static Future<XlsxExportResult> exportFullBackup({String languageCode = 'es'}) async {
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      final movements = await DatabaseHelper.instance.getAllMovements();
      final excel = Excel.createExcel();
      final productsSheet = excel['Inventario'];
      final movementsSheet = excel['Movimientos'];

      _appendProductHeaders(productsSheet);
      for (final product in products) {
        _appendProductRow(productsSheet, product);
      }

      _appendMovementHeaders(movementsSheet, includeTypeCode: true);
      for (final movement in movements) {
        _appendMovementRow(movementsSheet, movement, languageCode, includeTypeCode: true);
      }

      final path = await _saveWorkbook(excel, 'respaldo_completo_${_timestamp()}.xlsx', languageCode);
      if (path == null) {
        return XlsxExportResult(success: false, message: _msg(languageCode, 'Exportacion cancelada.', 'Export cancelled.'));
      }
      return XlsxExportResult(
        success: true,
        message: _msg(languageCode, 'Respaldo completo exportado: $path', 'Full backup exported: $path'),
        path: path,
      );
    } catch (e) {
      return XlsxExportResult(success: false, message: _msg(languageCode, 'Error al exportar respaldo: $e', 'Backup export error: $e'));
    }
  }

  static Future<XlsxImportResult> restoreFullBackup({String languageCode = 'es'}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null || result.files.isEmpty) {
        return XlsxImportResult(
          success: false,
          message: _msg(languageCode, 'No se selecciono ningun archivo.', 'No file selected.'),
          importedCount: 0,
        );
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        return XlsxImportResult(
          success: false,
          message: _msg(languageCode, 'No se encontro la ruta del archivo.', 'File path was not found.'),
          importedCount: 0,
        );
      }

      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final productsSheet = excel.tables['Inventario'];
      final movementsSheet = excel.tables['Movimientos'];
      if (productsSheet == null || movementsSheet == null) {
        return XlsxImportResult(
          success: false,
          message: _msg(languageCode, 'El archivo no es un respaldo completo valido.', 'The file is not a valid full backup.'),
          importedCount: 0,
        );
      }

      final products = _parseProductsSheet(productsSheet);
      if (products.isEmpty) {
        return XlsxImportResult(
          success: false,
          message: _msg(languageCode, 'El respaldo no contiene productos validos.', 'The backup has no valid products.'),
          importedCount: 0,
        );
      }
      final movements = _parseMovementsSheet(movementsSheet);
      final counts = await DatabaseHelper.instance.restoreFullBackup(products: products, movements: movements);
      final productCount = counts['products'] ?? 0;
      final movementCount = counts['movements'] ?? 0;

      return XlsxImportResult(
        success: true,
        message: _msg(languageCode, 'Respaldo restaurado: $productCount productos y $movementCount movimientos.', 'Backup restored: $productCount products and $movementCount movements.'),
        importedCount: productCount,
        totalFound: movementCount,
      );
    } catch (e) {
      return XlsxImportResult(
        success: false,
        message: _msg(languageCode, 'Error al restaurar respaldo: $e', 'Backup restore error: $e'),
        importedCount: 0,
      );
    }
  }

  static Future<XlsxExportResult> exportProducts({String languageCode = 'es'}) async {
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      final excel = Excel.createExcel();
      final sheet = excel['Inventario'];

      _appendProductHeaders(sheet);
      for (final product in products) {
        _appendProductRow(sheet, product);
      }

      final path = await _saveWorkbook(excel, 'inventario_${_timestamp()}.xlsx', languageCode);
      if (path == null) {
        return XlsxExportResult(success: false, message: _msg(languageCode, 'Exportacion cancelada.', 'Export cancelled.'));
      }
      return XlsxExportResult(
        success: true,
        message: _msg(languageCode, 'Inventario exportado: $path', 'Inventory exported: $path'),
        path: path,
      );
    } catch (e) {
      return XlsxExportResult(success: false, message: _msg(languageCode, 'Error al exportar inventario: $e', 'Inventory export error: $e'));
    }
  }

  static Future<XlsxExportResult> exportMovements({String languageCode = 'es'}) async {
    try {
      final movements = await DatabaseHelper.instance.getAllMovements();
      final excel = Excel.createExcel();
      final sheet = excel['Movimientos'];

      _appendMovementHeaders(sheet, includeTypeCode: false);
      for (final movement in movements) {
        _appendMovementRow(sheet, movement, languageCode, includeTypeCode: false);
      }

      final path = await _saveWorkbook(excel, 'movimientos_${_timestamp()}.xlsx', languageCode);
      if (path == null) {
        return XlsxExportResult(success: false, message: _msg(languageCode, 'Exportacion cancelada.', 'Export cancelled.'));
      }
      return XlsxExportResult(
        success: true,
        message: _msg(languageCode, 'Movimientos exportados: $path', 'Movements exported: $path'),
        path: path,
      );
    } catch (e) {
      return XlsxExportResult(success: false, message: _msg(languageCode, 'Error al exportar movimientos: $e', 'Movements export error: $e'));
    }
  }

  static void _appendProductHeaders(dynamic sheet) {
    sheet.appendRow([
      TextCellValue('Codigo'),
      TextCellValue('Producto Ingles'),
      TextCellValue('Producto Espanol'),
      TextCellValue('Categoria'),
      TextCellValue('Cantidad'),
      TextCellValue('Costo'),
      TextCellValue('Precio de venta'),
      TextCellValue('Ubicacion'),
      TextCellValue('Peso (kg)'),
      TextCellValue('Creado'),
      TextCellValue('Actualizado'),
    ]);
  }

  static void _appendProductRow(dynamic sheet, Product product) {
    sheet.appendRow([
      TextCellValue(product.barcode),
      TextCellValue(product.name),
      TextCellValue(product.spanishName),
      TextCellValue(product.category),
      IntCellValue(product.quantity),
      DoubleCellValue(product.costPrice),
      DoubleCellValue(product.salePrice),
      TextCellValue(product.location),
      product.weight == null ? TextCellValue('') : DoubleCellValue(product.weight!),
      TextCellValue(_formatDate(product.createdAt)),
      TextCellValue(_formatDate(product.updatedAt)),
    ]);
  }

  static void _appendMovementHeaders(dynamic sheet, {required bool includeTypeCode}) {
    sheet.appendRow([
      if (includeTypeCode) TextCellValue('Tipo interno'),
      TextCellValue('Fecha'),
      TextCellValue('Hora'),
      TextCellValue('Operacion'),
      TextCellValue('Producto Ingles'),
      TextCellValue('Producto Espanol'),
      TextCellValue('Codigo'),
      TextCellValue('Cantidad'),
      TextCellValue('Stock antes'),
      TextCellValue('Stock despues'),
      TextCellValue('Ubicacion'),
      TextCellValue('Nota'),
    ]);
  }

  static void _appendMovementRow(dynamic sheet, StockMovement movement, String languageCode, {required bool includeTypeCode}) {
    sheet.appendRow([
      if (includeTypeCode) TextCellValue(movement.type),
      TextCellValue(_formatOnlyDate(movement.createdAt)),
      TextCellValue(_formatOnlyTime(movement.createdAt)),
      TextCellValue(_movementTypeLabel(movement.type, languageCode)),
      TextCellValue(movement.productName ?? ''),
      TextCellValue(movement.productSpanishName ?? ''),
      TextCellValue(movement.productBarcode ?? ''),
      IntCellValue(movement.quantity),
      movement.stockBefore == null ? TextCellValue('') : IntCellValue(movement.stockBefore!),
      movement.stockAfter == null ? TextCellValue('') : IntCellValue(movement.stockAfter!),
      TextCellValue(movement.productLocation ?? ''),
      TextCellValue(movement.note ?? ''),
    ]);
  }

  static List<Product> _parseProductsSheet(dynamic sheet) {
    final products = <Product>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty || row[0]?.value == null) continue;
      final barcode = _cellToString(row[0]?.value).trim();
      final name = row.length > 1 ? _cellToString(row[1]?.value).trim() : '';
      if (barcode.isEmpty || name.isEmpty) continue;
      products.add(Product(
        barcode: barcode,
        name: name,
        spanishName: row.length > 2 ? _cellToString(row[2]?.value).trim() : '',
        category: row.length > 3 ? _cellToString(row[3]?.value).trim() : 'Genel',
        quantity: row.length > 4 ? _cellToInt(row[4]?.value) : 0,
        costPrice: row.length > 5 ? _cellToDouble(row[5]?.value) : 0.0,
        salePrice: row.length > 6 ? _cellToDouble(row[6]?.value) : 0.0,
        location: row.length > 7 ? _cellToString(row[7]?.value).trim() : '',
        weight: row.length > 8 ? _cellToDoubleNullable(row[8]?.value) : null,
        createdAt: row.length > 9 ? _cellToDate(row[9]?.value) : null,
        updatedAt: row.length > 10 ? _cellToDate(row[10]?.value) : null,
      ));
    }
    return products;
  }

  static List<StockMovement> _parseMovementsSheet(dynamic sheet) {
    final movements = <StockMovement>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      final hasTypeCode = _cellToString(row[0]?.value).trim().startsWith('mal_') ||
          _cellToString(row[0]?.value).trim() == 'sevkiyat' ||
          _cellToString(row[0]?.value).trim() == 'sayim' ||
          _cellToString(row[0]?.value).trim() == 'fire_iade';
      final offset = hasTypeCode ? 1 : 0;
      final type = hasTypeCode ? _cellToString(row[0]?.value).trim() : _movementTypeFromLabel(row.length > 2 ? _cellToString(row[2]?.value) : '');
      final barcodeIndex = offset + 5;
      final quantityIndex = offset + 6;
      if (row.length <= quantityIndex) continue;
      final barcode = row.length > barcodeIndex ? _cellToString(row[barcodeIndex]?.value).trim() : '';
      if (barcode.isEmpty) continue;
      final createdAt = _dateFromParts(
        row.length > offset ? _cellToString(row[offset]?.value) : '',
        row.length > offset + 1 ? _cellToString(row[offset + 1]?.value) : '',
      );
      movements.add(StockMovement(
        productId: 0,
        type: type,
        quantity: _cellToInt(row[quantityIndex]?.value),
        stockBefore: row.length > offset + 7 ? _cellToIntNullable(row[offset + 7]?.value) : null,
        stockAfter: row.length > offset + 8 ? _cellToIntNullable(row[offset + 8]?.value) : null,
        note: row.length > offset + 10 ? _emptyToNull(_cellToString(row[offset + 10]?.value)) : null,
        createdAt: createdAt,
        productBarcode: barcode,
      ));
    }
    return movements;
  }

  static Future<String?> _saveWorkbook(Excel excel, String fileName, String languageCode) async {
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    final fileBytes = excel.save();
    if (fileBytes == null) return null;
    final bytes = Uint8List.fromList(fileBytes);

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: _msg(languageCode, 'Guardar archivo Excel', 'Save Excel file'),
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );
    if (savedPath == null) return null;

    return savedPath;
  }

  static String _timestamp() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  static String _formatDate(DateTime date) {
    return '${_formatOnlyDate(date)} ${_formatOnlyTime(date)}';
  }

  static String _formatOnlyDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static String _formatOnlyTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.hour)}:${two(date.minute)}';
  }

  static String _movementTypeLabel(String type, String languageCode) {
    final isEnglish = languageCode == 'en';
    switch (type) {
      case 'mal_kabul':
        return isEnglish ? 'Stock In' : 'Entrada de stock';
      case 'sevkiyat':
        return isEnglish ? 'Dispatch' : 'Salida';
      case 'sayim':
        return isEnglish ? 'Count' : 'Conteo';
      case 'fire_iade':
        return isEnglish ? 'Waste / Return' : 'Mal estado / Devolucion';
      default:
        return type;
    }
  }

  static String _msg(String languageCode, String es, String en) {
    return languageCode == 'en' ? en : es;
  }
  static String _cellToString(dynamic value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.value.toString();
    return value.toString();
  }

  static int _cellToInt(dynamic value) {
    if (value == null) return 0;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _cellToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is DoubleCellValue) return value.value;
    if (value is IntCellValue) return value.value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static double? _cellToDoubleNullable(dynamic value) {
    if (value == null) return null;
    final text = _cellToString(value).trim();
    if (text.isEmpty) return null;
    return _cellToDouble(value);
  }
  static int? _cellToIntNullable(dynamic value) {
    if (value == null) return null;
    final text = _cellToString(value).trim();
    if (text.isEmpty) return null;
    return _cellToInt(value);
  }

  static DateTime? _cellToDate(dynamic value) {
    final text = _cellToString(value).trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static DateTime _dateFromParts(String date, String time) {
    final cleanDate = date.trim();
    final cleanTime = time.trim();
    return DateTime.tryParse('$cleanDate $cleanTime') ?? DateTime.tryParse(cleanDate) ?? DateTime.now();
  }

  static String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static String _movementTypeFromLabel(String label) {
    final text = label.toLowerCase().trim();
    if (text.contains('entrada') || text.contains('stock in')) return 'mal_kabul';
    if (text.contains('salida') || text.contains('dispatch')) return 'sevkiyat';
    if (text.contains('conteo') || text.contains('count')) return 'sayim';
    if (text.contains('devolucion') || text.contains('return') || text.contains('waste')) return 'fire_iade';
    return 'sayim';
  }

  /// Generate a template XLSX file and return its path
  static Future<String?> generateTemplate() async {
    try {
      var excel = Excel.createExcel();
      var sheet = excel['Productos'];

      // Header row
      sheet.appendRow([
        TextCellValue('Codigo'),
        TextCellValue('Producto'),
        TextCellValue('Producto Espanol'),
        TextCellValue('Categoria'),
        TextCellValue('Cantidad'),
        TextCellValue('Costo'),
        TextCellValue('Precio de venta'),
        TextCellValue('Ubicacion'),
        TextCellValue('Peso (kg)'),
      ]);

      // Example row
      sheet.appendRow([
        TextCellValue('8690000000001'),
        TextCellValue('Industrial Servo Motor'),
        TextCellValue('Motor servo industrial'),
        TextCellValue('Genel'),
        IntCellValue(100),
        DoubleCellValue(150.00),
        DoubleCellValue(250.00),
        TextCellValue('Zona A - Estante 1'),
        DoubleCellValue(0.5),
      ]);

      // Remove default Sheet1 if exists
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final fileBytes = excel.save();
      if (fileBytes == null) return null;

      // Save to a reliable location
      String outputDir;
      if (Platform.isWindows) {
        outputDir = '${Platform.environment['USERPROFILE']}\\Downloads';
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Use app documents directory on mobile
        final dir = Directory.systemTemp.parent;
        outputDir = dir.path;
      } else {
        outputDir = Directory.systemTemp.path;
      }

      final outputPath = '$outputDir${Platform.pathSeparator}plantilla_productos.xlsx';
      final file = File(outputPath);
      await file.writeAsBytes(fileBytes);
      
      debugPrint('Template saved to: $outputPath');
      return outputPath;
    } catch (e) {
      debugPrint('Template generation error: $e');
      return null;
    }
  }
}

class XlsxImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int? totalFound;

  XlsxImportResult({
    required this.success,
    required this.message,
    required this.importedCount,
    this.totalFound,
  });
}

class XlsxExportResult {
  final bool success;
  final String message;
  final String? path;

  XlsxExportResult({
    required this.success,
    required this.message,
    this.path,
  });
}
