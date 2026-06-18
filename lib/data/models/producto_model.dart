import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/stock_calculator.dart';
import '../../core/utils/date_helper.dart';
import '../../core/enums/producto_tipo.dart';

class ProductoModel {
  final String id;
  final String codigo;
  final String nombre;
  final String proveedor;
  final String almacenaje;
  final String? ubicacion; // Nueva: Pasillo, estante, etc.
  final int stockMinimo;   // Nueva: Alerta de reposición
  final String unidadMedida;// Nueva: Unidades, Cajas, kg, etc.
  final double precio;
  final double? precioPromocion;
  final DateTime? inicioPromocion;
  final DateTime? finPromocion;
  final int stock;
  final int ventaHoy;
  final String creadoPor;
  final DateTime? creadoEn;
  final ProductoTipo tipo;
  final ProductoSubtipo subtipo;

  const ProductoModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.proveedor,
    required this.almacenaje,
    this.ubicacion,
    this.stockMinimo = 0,
    this.unidadMedida = 'Unidad',
    required this.precio,
    this.precioPromocion,
    this.inicioPromocion,
    this.finPromocion,
    required this.stock,
    this.ventaHoy = 0,
    required this.creadoPor,
    this.creadoEn,
    required this.tipo,
    required this.subtipo,
  });

  int get stockReal => StockCalculator.calcularStockReal(stock, ventaHoy);

  bool get esStockBajo => stockReal <= stockMinimo;

  bool get tienePromocionActiva =>
      DateHelper.promoActiva(inicioPromocion, finPromocion);

  double get precioVigente =>
      tienePromocionActiva && precioPromocion != null
          ? precioPromocion!
          : precio;

  factory ProductoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductoModel(
      id: doc.id,
      codigo: d['codigo'] ?? '',
      nombre: d['nombre'] ?? '',
      proveedor: d['proveedor'] ?? '',
      almacenaje: d['almacenaje'] ?? '',
      ubicacion: d['ubicacion'],
      stockMinimo: d['stockMinimo'] ?? 0,
      unidadMedida: d['unidadMedida'] ?? 'Unidad',
      precio: (d['precio'] ?? 0).toDouble(),
      precioPromocion: d['precioPromocion'] != null
          ? (d['precioPromocion'] as num).toDouble()
          : null,
      inicioPromocion: (d['inicioPromocion'] as Timestamp?)?.toDate(),
      finPromocion: (d['finPromocion'] as Timestamp?)?.toDate(),
      stock: d['stock'] ?? 0,
      ventaHoy: d['ventaHoy'] ?? 0,
      creadoPor: d['creadoPor'] ?? '',
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
      tipo: ProductoTipoExt.fromValor(d['tipo']),
      subtipo: ProductoSubtipoExt.fromValor(d['subtipo']),
    );
  }

  Map<String, dynamic> toMap() => {
    'codigo': codigo,
    'nombre': nombre,
    'proveedor': proveedor,
    'almacenaje': almacenaje,
    'ubicacion': ubicacion,
    'stockMinimo': stockMinimo,
    'unidadMedida': unidadMedida,
    'precio': precio,
    'precioPromocion': precioPromocion,
    'inicioPromocion': inicioPromocion != null
        ? Timestamp.fromDate(inicioPromocion!)
        : null,
    'finPromocion': finPromocion != null
        ? Timestamp.fromDate(finPromocion!)
        : null,
    'stock': stock,
    'ventaHoy': ventaHoy,
    'creadoPor': creadoPor,
    'creadoEn': creadoEn != null
        ? Timestamp.fromDate(creadoEn!)
        : FieldValue.serverTimestamp(),
    'tipo': tipo.valor,
    'subtipo': subtipo.valor,
  };

  ProductoModel copyWith({
    String? nombre,
    String? proveedor,
    String? almacenaje,
    String? ubicacion,
    int? stockMinimo,
    String? unidadMedida,
    double? precio,
    double? precioPromocion,
    DateTime? inicioPromocion,
    DateTime? finPromocion,
    int? stock,
    int? ventaHoy,
    ProductoTipo? tipo,
    ProductoSubtipo? subtipo,
  }) {
    return ProductoModel(
      id: id,
      codigo: codigo,
      nombre: nombre ?? this.nombre,
      proveedor: proveedor ?? this.proveedor,
      almacenaje: almacenaje ?? this.almacenaje,
      ubicacion: ubicacion ?? this.ubicacion,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      precio: precio ?? this.precio,
      precioPromocion: precioPromocion ?? this.precioPromocion,
      inicioPromocion: inicioPromocion ?? this.inicioPromocion,
      finPromocion: finPromocion ?? this.finPromocion,
      stock: stock ?? this.stock,
      ventaHoy: ventaHoy ?? this.ventaHoy,
      creadoPor: creadoPor,
      creadoEn: creadoEn,
      tipo: tipo ?? this.tipo,
      subtipo: subtipo ?? this.subtipo,
    );
  }
}