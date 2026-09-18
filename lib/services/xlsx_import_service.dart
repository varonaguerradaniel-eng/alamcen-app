import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
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

      // Expected columns: Codigo, Producto, Categoria, Cantidad, Costo, Precio de venta, Ubicacion, Peso
      final products = <Product>[];
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty || row[0]?.value == null) continue;

        try {
          final barcode = _cellToString(row[0]?.value);
          final name = row.length > 1 ? _cellToString(row[1]?.value) : '';
          final category = row.length > 2 ? _cellToString(row[2]?.value) : 'Genel';
          final quantity = row.length > 3 ? _cellToInt(row[3]?.value) : 0;
          final costPrice = row.length > 4 ? _cellToDouble(row[4]?.value) : 0.0;
          final salePrice = row.length > 5 ? _cellToDouble(row[5]?.value) : 0.0;
          final location = row.length > 6 ? _cellToString(row[6]?.value) : '';
          final weight = row.length > 7 ? _cellToDoubleNullable(row[7]?.value) : null;

          if (barcode.isNotEmpty && name.isNotEmpty) {
            products.add(Product(
              barcode: barcode,
              name: name,
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
    return _cellToDouble(value);
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
        TextCellValue('Producto de ejemplo'),
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





