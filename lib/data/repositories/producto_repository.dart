import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import '../services/firebase_service.dart';
import '../../core/constants/firestore_paths.dart';

class ProductoRepository {
  final FirebaseService _fb = FirebaseService();

  /// Escucha en tiempo real todos los productos
  Stream<List<ProductoModel>> listarTodos() {
    return _fb.productos
        .orderBy('nombre')
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ProductoModel.fromFirestore(d))
        .toList());
  }

  /// Busca producto por código de barras
  Future<ProductoModel?> buscarPorCodigo(String codigo) async {
    final snap = await _fb.productos
        .where('codigo', isEqualTo: codigo)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return ProductoModel.fromFirestore(snap.docs.first);
  }

  /// Agrega un nuevo producto
  Future<void> agregar(ProductoModel producto, String usuarioNombre) async {
    await _fb.productos.add(producto.toMap());
    await _registrarHistorial('agregar', producto.codigo, producto.nombre, usuarioNombre);
  }

  /// Actualiza un producto existente
  Future<void> actualizar(ProductoModel producto, String usuarioNombre) async {
    await _fb.productos.doc(producto.id).update(producto.toMap());
    await _registrarHistorial('editar', producto.codigo, producto.nombre, usuarioNombre);
  }

  /// Solo actualiza el stock (permitido para inventaristas)
  Future<void> actualizarStock(String id, int nuevoStock, String usuarioNombre) async {
    await _fb.productos.doc(id).update({'stock': nuevoStock});
    await _registrarHistorial('stock', id, 'Ajuste de stock', usuarioNombre);
  }

  /// Actualiza venta de hoy (stockReal se recalcula en el modelo)
  Future<void> actualizarVentaHoy(String id, int ventaHoy) async {
    await _fb.productos.doc(id).update({'ventaHoy': ventaHoy});
  }

  /// Descuenta stock al registrar una merma
  Future<void> descontarStockPorMerma(String productoId, int cantidad) async {
    await _fb.db.runTransaction((tx) async {
      final ref = _fb.productos.doc(productoId);
      final snap = await tx.get(ref);
      final stockActual = (snap.data() as Map<String, dynamic>)['stock'] ?? 0;
      final nuevo = (stockActual - cantidad).clamp(0, 99999);
      tx.update(ref, {'stock': nuevo});
    });
  }

  Future<void> eliminar(String id, String usuarioNombre) async {
    final doc = await _fb.productos.doc(id).get();
    final data = doc.data() as Map<String, dynamic>?;
    await _fb.productos.doc(id).delete();
    await _registrarHistorial('eliminar', data?['codigo'] ?? id, data?['nombre'] ?? '', usuarioNombre);
  }

  /// Productos con stock por debajo del mínimo
  Stream<List<ProductoModel>> stockBajo({int minimo = 5}) {
    return _fb.productos
        .where('stock', isLessThanOrEqualTo: minimo)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ProductoModel.fromFirestore(d))
        .toList());
  }

  Future<void> _registrarHistorial(
      String accion, String codigo, String nombre, String usuario) async {
    await _fb.historial.add({
      'accion': accion,
      'codigo': codigo,
      'nombre': nombre,
      'usuario': usuario,
      'fecha': FieldValue.serverTimestamp(),
    });
  }
}