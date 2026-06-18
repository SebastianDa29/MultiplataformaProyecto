import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/utils/date_helper.dart';
import '../../core/enums/producto_tipo.dart';
import '../models/producto_model.dart';

class ExcelService {
  /// Genera y abre un archivo Excel con la lista de productos
  static Future<void> exportarProductos(List<ProductoModel> productos) async {
    final excel = Excel.createExcel();

    // Hoja principal
    final hoja = excel['Inventario'];
    excel.setDefaultSheet('Inventario');

    // ── Estilos ──────────────────────────────────────────────
    final estiloEncabezado = CellStyle(
      bold: true,
      backgroundColorHex: '#C8102E'.excelColor,
      fontColorHex: '#FFFFFF'.excelColor,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final estiloImpar = CellStyle(
      backgroundColorHex: '#FFF5F5'.excelColor,
    );

    final estiloPromo = CellStyle(
      backgroundColorHex: '#FFF8DC'.excelColor,
      fontColorHex: '#7A5900'.excelColor,
      bold: true,
    );

    final estiloBajo = CellStyle(
      backgroundColorHex: '#FFE4E4'.excelColor,
      fontColorHex: '#C62828'.excelColor,
      bold: true,
    );

    // ── Encabezados ──────────────────────────────────────────
    final encabezados = [
      'Código',
      'Nombre',
      'U. Medida',
      'Tipo',
      'Subtipo',
      'Stock',
      'Stock Real',
      'Stock Mínimo',
      'Precio (S/)',
      'Precio Promo (S/)',
      'Almacenaje',
      'Pasillo/Rack',
      'Proveedor',
      'Promo Activa',
      'Inicio Promo',
      'Fin Promo',
    ];

    for (var col = 0; col < encabezados.length; col++) {
      final cell = hoja.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(encabezados[col]);
      cell.cellStyle = estiloEncabezado;
    }

    // ── Filas de datos ───────────────────────────────────────
    for (var i = 0; i < productos.length; i++) {
      final p = productos[i];
      final fila = i + 1;
      final esImpar = i % 2 != 0;
      final tienePromo = p.tienePromocionActiva;
      final stockBajo  = p.stockReal <= 5;

      final valores = [
        p.codigo,
        p.nombre,
        p.unidadMedida,
        p.tipo.etiqueta,
        p.subtipo.etiqueta,
        p.stock.toString(),
        p.stockReal.toString(),
        p.stockMinimo.toString(),
        p.precio.toStringAsFixed(2),
        p.precioPromocion?.toStringAsFixed(2) ?? '-',
        p.almacenaje,
        p.ubicacion ?? '-',
        p.proveedor,
        tienePromo ? 'Sí' : 'No',
        p.inicioPromocion != null ? DateHelper.formatear(p.inicioPromocion!) : '-',
        p.finPromocion != null ? DateHelper.formatear(p.finPromocion!) : '-',
      ];

      for (var col = 0; col < valores.length; col++) {
        final cell = hoja.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: fila),
        );
        cell.value = TextCellValue(valores[col]);

        // Color según estado
        if (col == 6 && p.esStockBajo) {
          cell.cellStyle = estiloBajo;
        } else if (tienePromo && (col == 9 || col == 13)) {
          cell.cellStyle = estiloPromo;
        } else if (esImpar) {
          cell.cellStyle = estiloImpar;
        }
      }
    }

    // ── Anchos de columna ────────────────────────────────────
    final anchos = [14, 28, 12, 16, 22, 8, 10, 12, 12, 16, 16, 16, 20, 12, 14, 14];
    for (var i = 0; i < anchos.length; i++) {
      hoja.setColumnWidth(i, anchos[i].toDouble());
    }

    // ── Guardar y abrir ──────────────────────────────────────
    final dir      = await getTemporaryDirectory();
    final fecha    = DateTime.now();
    final nombre   = 'Inventario_${fecha.day}-${fecha.month}-${fecha.year}.xlsx';
    final archivo  = File('${dir.path}/$nombre');
    final bytes    = excel.encode();

    if (bytes == null) throw Exception('Error al generar el archivo Excel');

    await archivo.writeAsBytes(bytes);
    await OpenFilex.open(archivo.path);
  }
}
