import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/stock_calculator.dart';
import '../../core/utils/date_helper.dart';

class ProductoModel {
  final String id;
  final String codigo;
  final String nombre;
  final String proveedor;
  final String almacenaje;
  final double precio;
  final double? precioPromocion;
  final DateTime? inicioPromocion;
  final DateTime? finPromocion;
  final int stock;
  final int ventaHoy;
  final String creadoPor;
  final DateTime? creadoEn;

  const ProductoModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.proveedor,
    required this.almacenaje,
    required this.precio,
    this.precioPromocion,
    this.inicioPromocion,
    this.finPromocion,
    required this.stock,
    this.ventaHoy = 0,
    required this.creadoPor,
    this.creadoEn,
  });

  // Calculado automáticamente
  int get stockReal => StockCalculator.calcularStockReal(stock, ventaHoy);

  bool get tienePromocionActiva =>
      DateHelper.promoActiva(inicioPromocion, finPromocion);

  double get precioVigente =>
      tienePromocionActiva && precioPromocion != null
          ? precioPromocion!
          : precio;

  factory ProductoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductoModel(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      proveedor: data['proveedor'] ?? '',
      almacenaje: data['almacenaje'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      precioPromocion: data['precioPromocion'] != null
          ? (data['precioPromocion'] as num).toDouble()
          : null,
      inicioPromocion:
      (data['inicioPromocion'] as Timestamp?)?.toDate(),
      finPromocion:
      (data['finPromocion'] as Timestamp?)?.toDate(),
      stock: data['stock'] ?? 0,
      ventaHoy: data['ventaHoy'] ?? 0,
      creadoPor: data['creadoPor'] ?? '',
      creadoEn: (data['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'codigo': codigo,
    'nombre': nombre,
    'proveedor': proveedor,
    'almacenaje': almacenaje,
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
  };

  ProductoModel copyWith({
    String? nombre,
    String? proveedor,
    String? almacenaje,
    double? precio,
    double? precioPromocion,
    DateTime? inicioPromocion,
    DateTime? finPromocion,
    int? stock,
    int? ventaHoy,
  }) {
    return ProductoModel(
      id: id,
      codigo: codigo,
      nombre: nombre ?? this.nombre,
      proveedor: proveedor ?? this.proveedor,
      almacenaje: almacenaje ?? this.almacenaje,
      precio: precio ?? this.precio,
      precioPromocion: precioPromocion ?? this.precioPromocion,
      inicioPromocion: inicioPromocion ?? this.inicioPromocion,
      finPromocion: finPromocion ?? this.finPromocion,
      stock: stock ?? this.stock,
      ventaHoy: ventaHoy ?? this.ventaHoy,
      creadoPor: creadoPor,
      creadoEn: creadoEn,
    );
  }
}