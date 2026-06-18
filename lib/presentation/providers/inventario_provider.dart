import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/firebase_service.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/merma_model.dart';
import '../../data/models/movimiento_model.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/merma_repository.dart';
import '../../data/repositories/movimiento_repository.dart';
import '../../core/enums/tipo_movimiento.dart';
import '../../core/enums/merma_tipo.dart';
import '../../data/models/usuario_model.dart';

class InventarioProvider extends ChangeNotifier {
  final ProductoRepository _prodRepo = ProductoRepository();
  final MermaRepository _mermaRepo   = MermaRepository();
  final MovimientoRepository _movRepo = MovimientoRepository();

  List<ProductoModel> _productos = [];
  List<MermaModel>   _mermas    = [];
  List<MovimientoModel> _movimientos = [];
  bool cargando = false;
  String? error;
  String _filtro = '';

  List<ProductoModel> get productos {
    if (_filtro.isEmpty) return _productos;
    final q = _filtro.toLowerCase();
    return _productos.where((p) =>
    p.nombre.toLowerCase().contains(q) ||
        p.codigo.toLowerCase().contains(q) ||
        p.proveedor.toLowerCase().contains(q)).toList();
  }

  List<ProductoModel> get productosStockBajo =>
      _productos.where((p) => p.stockReal <= 5).toList();

  List<ProductoModel> get productosConPromocion =>
      _productos.where((p) => p.tienePromocionActiva).toList();

  List<MermaModel> get mermas => _mermas;
  List<MovimientoModel> get movimientos => _movimientos;

  void setFiltro(String valor) {
    _filtro = valor;
    notifyListeners();
  }

  void escucharProductos() {
    _prodRepo.listarTodos().listen((lista) {
      _productos = lista;
      notifyListeners();
    });
  }

  void escucharMermas() {
    _mermaRepo.listarTodas().listen((lista) {
      _mermas = lista;
      notifyListeners();
    });
  }

  void escucharMovimientos() {
    _movRepo.listarMovimientos().listen((lista) {
      _movimientos = lista;
      notifyListeners();
    });
  }

  Future<ProductoModel?> buscarPorCodigo(String codigo) async {
    return _prodRepo.buscarPorCodigo(codigo);
  }

  Future<void> agregarProducto(ProductoModel p, UsuarioModel usuario) async {
    final nuevoId = await _prodRepo.agregar(p, usuario.nombre);
    await _movRepo.registrarMovimiento(MovimientoModel(
      id: '',
      productoId: nuevoId,
      productoNombre: p.nombre,
      cantidad: p.stock,
      tipo: TipoMovimiento.inicial,
      motivo: 'Carga inicial de producto',
      usuarioId: usuario.uid,
      usuarioNombre: usuario.nombre,
      fecha: DateTime.now(),
    ));
  }

  Future<void> actualizarProducto(ProductoModel p, UsuarioModel usuario) async {
    await _prodRepo.actualizar(p, usuario.nombre);
    await _movRepo.registrarMovimiento(MovimientoModel(
      id: '',
      productoId: p.id,
      productoNombre: p.nombre,
      cantidad: 0,
      tipo: TipoMovimiento.ajuste,
      motivo: 'Actualización de datos',
      usuarioId: usuario.uid,
      usuarioNombre: usuario.nombre,
      fecha: DateTime.now(),
    ));
  }

  Future<void> actualizarStock(String id, int nuevoStock, UsuarioModel usuario) async {
    final producto = _productos.firstWhere((p) => p.id == id);
    final diferencia = nuevoStock - producto.stock;

    await _prodRepo.actualizarStock(id, nuevoStock, usuario.nombre);

    await _movRepo.registrarMovimiento(MovimientoModel(
      id: '',
      productoId: id,
      productoNombre: producto.nombre,
      cantidad: diferencia,
      tipo: diferencia > 0 ? TipoMovimiento.entrada : TipoMovimiento.salida,
      motivo: 'Ajuste manual de stock',
      usuarioId: usuario.uid,
      usuarioNombre: usuario.nombre,
      fecha: DateTime.now(),
    ));
  }

  Future<void> registrarMerma(MermaModel merma, String productoId, UsuarioModel usuario) async {
    final producto = _productos.firstWhere((p) => p.id == productoId);
    final fb = FirebaseService();
    final batch = fb.db.batch();

    final mermaRef = fb.mermas.doc();
    batch.set(mermaRef, merma.toMap());

    batch.update(fb.productos.doc(productoId), {
      'stock': FieldValue.increment(-merma.cantidad)
    });

    final movRef = fb.db.collection('movimientos').doc();
    final mov = MovimientoModel(
      id: movRef.id,
      productoId: productoId,
      productoNombre: producto.nombre,
      cantidad: -merma.cantidad,
      tipo: TipoMovimiento.merma,
      motivo: 'Merma: ${merma.tipo.etiqueta} - ${merma.observacion}',
      usuarioId: usuario.uid,
      usuarioNombre: usuario.nombre,
      fecha: DateTime.now(),
      referenciaId: mermaRef.id,
    );
    batch.set(movRef, mov.toMap());

    await batch.commit();
  }

  Future<void> eliminarProducto(String id, UsuarioModel usuario) async {
    await _prodRepo.eliminar(id, usuario.nombre);
  }

  Future<void> procesarInventarioMasivo(Map<String, int> conteos, UsuarioModel usuario) async {
    cargando = true;
    error = null;
    notifyListeners();

    try {
      final fb = FirebaseService();
      final batch = fb.db.batch();
      final ahora = DateTime.now();

      for (var entry in conteos.entries) {
        final id = entry.key;
        final nuevoStock = entry.value;
        final producto = _productos.firstWhere((p) => p.id == id);
        final diferencia = nuevoStock - producto.stock;

        // 1. Actualizar Stock
        batch.update(fb.productos.doc(id), {'stock': nuevoStock});

        // 2. Registrar Movimiento
        final movRef = fb.db.collection('movimientos').doc();
        final mov = MovimientoModel(
          id: movRef.id,
          productoId: id,
          productoNombre: producto.nombre,
          cantidad: diferencia,
          tipo: TipoMovimiento.ajuste,
          motivo: 'Inventario masivo PDA',
          usuarioId: usuario.uid,
          usuarioNombre: usuario.nombre,
          fecha: ahora,
        );
        batch.set(movRef, mov.toMap());

        // 3. Historial
        final histRef = fb.historial.doc();
        batch.set(histRef, {
          'accion': 'stock_masivo',
          'codigo': producto.codigo,
          'nombre': producto.nombre,
          'usuario': usuario.nombre,
          'fecha': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      error = 'Error en inventario masivo: $e';
      rethrow;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> procesarMermasMasivas(List<MermaModel> listaMermas, UsuarioModel usuario) async {
    cargando = true;
    error = null;
    notifyListeners();

    try {
      final fb = FirebaseService();
      final batch = fb.db.batch();
      final ahora = DateTime.now();

      for (var merma in listaMermas) {
        final producto = _productos.firstWhere(
          (p) => p.codigo == merma.codigoProducto,
          orElse: () => throw Exception('Producto no encontrado: ${merma.codigoProducto}'),
        );

        // 1. Registrar Merma
        final mermaRef = fb.mermas.doc();
        batch.set(mermaRef, merma.toMap());

        // 2. Descontar Stock
        batch.update(fb.productos.doc(producto.id), {
          'stock': FieldValue.increment(-merma.cantidad)
        });

        // 3. Registrar Movimiento
        final movRef = fb.db.collection('movimientos').doc();
        final mov = MovimientoModel(
          id: movRef.id,
          productoId: producto.id,
          productoNombre: producto.nombre,
          cantidad: -merma.cantidad,
          tipo: TipoMovimiento.merma,
          motivo: 'Merma masiva: ${merma.tipo.etiqueta} - ${merma.observacion}',
          usuarioId: usuario.uid,
          usuarioNombre: usuario.nombre,
          fecha: ahora,
          referenciaId: mermaRef.id,
        );
        batch.set(movRef, mov.toMap());
      }

      await batch.commit();
    } catch (e) {
      error = 'Error en mermas masivas: $e';
      rethrow;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
