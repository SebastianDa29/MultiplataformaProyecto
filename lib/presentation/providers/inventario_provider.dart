import 'package:flutter/material.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/merma_model.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/merma_repository.dart';

class InventarioProvider extends ChangeNotifier {
  final ProductoRepository _prodRepo = ProductoRepository();
  final MermaRepository _mermaRepo   = MermaRepository();

  List<ProductoModel> _productos = [];
  List<MermaModel>   _mermas    = [];
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

  Future<ProductoModel?> buscarPorCodigo(String codigo) async {
    return _prodRepo.buscarPorCodigo(codigo);
  }

  Future<void> agregarProducto(ProductoModel p, String usuario) async {
    await _prodRepo.agregar(p, usuario);
  }

  Future<void> actualizarProducto(ProductoModel p, String usuario) async {
    await _prodRepo.actualizar(p, usuario);
  }

  Future<void> actualizarStock(String id, int stock, String usuario) async {
    await _prodRepo.actualizarStock(id, stock, usuario);
  }

  Future<void> registrarMerma(MermaModel merma) async {
    await _mermaRepo.registrar(merma);
    await _prodRepo.descontarStockPorMerma(merma.codigoProducto, merma.cantidad);
  }

  Future<void> eliminarProducto(String id, String usuario) async {
    await _prodRepo.eliminar(id, usuario);
  }
}