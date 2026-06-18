import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/pda_styles.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/enums/producto_tipo.dart';
import '../../../data/models/producto_model.dart';
import '../../../data/services/excel_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../widgets/restricted_access_dialog.dart';
import '../../../router/app_router.dart';

class ListaProductosScreen extends StatefulWidget {
  const ListaProductosScreen({super.key});

  @override
  State<ListaProductosScreen> createState() => _ListaProductosScreenState();
}

class _ListaProductosScreenState extends State<ListaProductosScreen>
    with SingleTickerProviderStateMixin {
  final _busquedaCtrl = TextEditingController();

  // Filtros activos
  ProductoTipo? _tipoFiltro;
  ProductoSubtipo? _subtipoFiltro;
  String _estadoFiltro = 'Todos'; // Todos | Stock bajo | En promoción

  bool _exportando = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    
    // Asegurar que escuchamos productos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>().escucharProductos();
    });
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Filtrado ─────────────────────────────────────────────
  List<ProductoModel> _filtrar(List<ProductoModel> todos) {
    var lista = todos;

    if (_tipoFiltro != null) {
      lista = lista.where((p) => p.tipo == _tipoFiltro).toList();
    }
    if (_subtipoFiltro != null) {
      lista = lista.where((p) => p.subtipo == _subtipoFiltro).toList();
    }
    switch (_estadoFiltro) {
      case 'Stock bajo':
        lista = lista.where((p) => p.esStockBajo).toList();
        break;
      case 'En promoción':
        lista = lista.where((p) => p.tienePromocionActiva).toList();
        break;
    }
    return lista;
  }

  void _limpiarFiltros() {
    setState(() {
      _tipoFiltro    = null;
      _subtipoFiltro = null;
      _estadoFiltro  = 'Todos';
      _busquedaCtrl.clear();
      context.read<InventarioProvider>().setFiltro('');
    });
  }

  bool get _hayFiltrosActivos =>
      _tipoFiltro != null ||
          _subtipoFiltro != null ||
          _estadoFiltro != 'Todos' ||
          _busquedaCtrl.text.isNotEmpty;

  // ── Exportar Excel ───────────────────────────────────────
  Future<void> _exportarExcel(List<ProductoModel> productos) async {
    setState(() => _exportando = true);
    try {
      await ExcelService.exportarProductos(productos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: AppColors.rojoStock,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  // ── Editar stock ─────────────────────────────────────────
  void _editarStock(BuildContext context, ProductoModel producto) {
    final ctrl = TextEditingController(text: '${producto.stock}');
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PDAStyles.borderRadius)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editar Stock', style: PDAStyles.headerStyle.copyWith(color: Colors.black)),
            const SizedBox(height: 4),
            Text(producto.nombre,
                style: const TextStyle(
                    fontSize: PDAStyles.fontSmall, color: AppColors.grisMedio,
                    fontWeight: FontWeight.normal)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: PDAStyles.valueStyle,
          decoration: PDAStyles.inputDecoration('Nuevo stock', icon: Icons.inventory_2_outlined),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(100, PDAStyles.minTouchTarget),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: PDAStyles.fontMedium)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final nuevo = int.tryParse(ctrl.text);
                    if (nuevo == null || nuevo < 0) return;
                    await context
                        .read<InventarioProvider>()
                        .actualizarStock(producto.id, nuevo, auth.usuario!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: PDAStyles.primaryButtonStyle.copyWith(
                    minimumSize: WidgetStateProperty.all(const Size(120, PDAStyles.minTouchTarget)),
                  ),
                  child: const Text('Guardar',
                      style: PDAStyles.buttonTextStyle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Eliminar ─────────────────────────────────────────────
  void _intentarEliminar(BuildContext context, ProductoModel producto) {
    final auth = context.read<AuthProvider>();

    Future<void> eliminar() async {
      await context
          .read<InventarioProvider>()
          .eliminarProducto(producto.id, auth.usuario!);
      if (context.mounted) Navigator.pop(context);
    }

    if (!auth.puedeEjecutar(Permiso.eliminarProducto)) {
      RestrictedAccessDialog.mostrar(
        context,
        permiso: Permiso.eliminarProducto,
        onDesbloqueado: () => _confirmarEliminar(context, eliminar),
      );
    } else {
      _confirmarEliminar(context, eliminar);
    }
  }

  void _confirmarEliminar(BuildContext ctx, Future<void> Function() accion) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PDAStyles.borderRadius)),
        title: Text('Eliminar producto', style: PDAStyles.headerStyle.copyWith(color: Colors.black)),
        content: const Text(
          '¿Estás seguro? Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: PDAStyles.fontMedium),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(100, PDAStyles.minTouchTarget),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: PDAStyles.fontMedium)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => accion(),
                  style: PDAStyles.primaryButtonStyle.copyWith(
                    backgroundColor: WidgetStateProperty.all(AppColors.rojoStock),
                    minimumSize: WidgetStateProperty.all(const Size(120, PDAStyles.minTouchTarget)),
                  ),
                  child: const Text('Eliminar',
                      style: PDAStyles.buttonTextStyle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth       = context.watch<AuthProvider>();
    final inventario = context.watch<InventarioProvider>();
    final productos  = _filtrar(inventario.productos);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        backgroundColor: AppColors.rojo,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Gestión de Productos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRouter.dashboard),
        ),
        actions: [
          // Botón Excel
          _exportando
              ? const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.table_chart_rounded),
            tooltip: 'Exportar a Excel',
            onPressed: () => _exportarExcel(productos),
          ),
          // Agregar
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: AppStrings.agregarProducto,
            onPressed: () => context.go(AppRouter.agregar),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // ── Panel de filtros ──────────────────────────────
            _PanelFiltros(
              busquedaCtrl: _busquedaCtrl,
              tipoFiltro: _tipoFiltro,
              subtipoFiltro: _subtipoFiltro,
              estadoFiltro: _estadoFiltro,
              hayFiltrosActivos: _hayFiltrosActivos,
              onBusqueda: (v) {
                context.read<InventarioProvider>().setFiltro(v);
                setState(() {});
              },
              onTipoChanged: (tipo) {
                setState(() {
                  _tipoFiltro    = tipo;
                  _subtipoFiltro = null;
                });
              },
              onSubtipoChanged: (sub) {
                setState(() => _subtipoFiltro = sub);
              },
              onEstadoChanged: (e) {
                setState(() => _estadoFiltro = e);
              },
              onLimpiar: _limpiarFiltros,
            ),

            // ── Barra de resultado ────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text(
                    '${productos.length} producto(s)',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.grisMedio),
                  ),
                  const Spacer(),
                  if (_hayFiltrosActivos)
                    TextButton.icon(
                      onPressed: _limpiarFiltros,
                      icon: const Icon(Icons.filter_alt_off_rounded,
                          size: 16, color: AppColors.rojo),
                      label: const Text('Limpiar filtros',
                          style: TextStyle(
                              color: AppColors.rojo, fontSize: 12)),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                ],
              ),
            ),

            // ── Lista / Tabla de productos ────────────────────
            Expanded(
              child: productos.isEmpty
                  ? _EmptyState(hayFiltros: _hayFiltrosActivos)
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: productos.length,
                itemBuilder: (context, i) {
                  return _ProductoTile(
                    producto: productos[i],
                    auth: auth,
                    onEditarStock: () =>
                        _editarStock(context, productos[i]),
                    onEliminar: () =>
                        _intentarEliminar(context, productos[i]),
                    onEditar: auth.puedeEjecutar(Permiso.editarProducto)
                        ? () => context.go(AppRouter.agregar, extra: productos[i])
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRouter.agregar),
        backgroundColor: AppColors.rojo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Producto',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PANEL DE FILTROS
// ════════════════════════════════════════════════════════════
class _PanelFiltros extends StatelessWidget {
  final TextEditingController busquedaCtrl;
  final ProductoTipo? tipoFiltro;
  final ProductoSubtipo? subtipoFiltro;
  final String estadoFiltro;
  final bool hayFiltrosActivos;
  final void Function(String) onBusqueda;
  final void Function(ProductoTipo?) onTipoChanged;
  final void Function(ProductoSubtipo?) onSubtipoChanged;
  final void Function(String) onEstadoChanged;
  final VoidCallback onLimpiar;

  const _PanelFiltros({
    required this.busquedaCtrl,
    required this.tipoFiltro,
    required this.subtipoFiltro,
    required this.estadoFiltro,
    required this.hayFiltrosActivos,
    required this.onBusqueda,
    required this.onTipoChanged,
    required this.onSubtipoChanged,
    required this.onEstadoChanged,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    final subtiposDisponibles = tipoFiltro?.subtipos ?? [];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          TextField(
            controller: busquedaCtrl,
            onChanged: onBusqueda,
            style: const TextStyle(fontSize: PDAStyles.fontMedium),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, código o proveedor...',
              hintStyle:
              const TextStyle(fontSize: PDAStyles.fontSmall, color: AppColors.grisMedio),
              prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.grisMedio, size: 28),
              suffixIcon: busquedaCtrl.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 24),
                onPressed: () {
                  busquedaCtrl.clear();
                  onBusqueda('');
                },
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF2F3F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),

          // Filtro por TIPO
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Tipo:',
                    style: TextStyle(
                        fontSize: PDAStyles.fontSmall,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grisOscuro)),
                const SizedBox(width: 8),
                _FiltroChip(
                  etiqueta: 'Todos',
                  seleccionado: tipoFiltro == null,
                  onTap: () => onTipoChanged(null),
                ),
                const SizedBox(width: 8),
                ...ProductoTipo.values.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FiltroChip(
                    etiqueta: t.etiqueta,
                    seleccionado: tipoFiltro == t,
                    onTap: () => onTipoChanged(tipoFiltro == t ? null : t),
                    color: t == ProductoTipo.comestible
                        ? Colors.green.shade700
                        : Colors.indigo.shade700,
                  ),
                )),
              ],
            ),
          ),

          // Filtro por SUBTIPO (solo si hay tipo seleccionado)
          if (tipoFiltro != null && subtiposDisponibles.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Subtipo:',
                      style: TextStyle(
                          fontSize: PDAStyles.fontSmall,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grisOscuro)),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    etiqueta: 'Todos',
                    seleccionado: subtipoFiltro == null,
                    onTap: () => onSubtipoChanged(null),
                  ),
                  const SizedBox(width: 8),
                  ...subtiposDisponibles.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FiltroChip(
                      etiqueta: s.etiqueta,
                      seleccionado: subtipoFiltro == s,
                      onTap: () =>
                          onSubtipoChanged(subtipoFiltro == s ? null : s),
                      color: AppColors.rojo,
                    ),
                  )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Filtro por ESTADO
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Estado:',
                    style: TextStyle(
                        fontSize: PDAStyles.fontSmall,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grisOscuro)),
                const SizedBox(width: 8),
                ...['Todos', 'Stock bajo', 'En promoción'].map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FiltroChip(
                    etiqueta: e,
                    seleccionado: estadoFiltro == e,
                    onTap: () => onEstadoChanged(e),
                    color: e == 'Stock bajo'
                        ? Colors.orange.shade800
                        : e == 'En promoción'
                        ? Colors.amber.shade800
                        : AppColors.rojo,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;
  final Color color;

  const _FiltroChip({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
    this.color = AppColors.rojo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? color : const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? color : Colors.transparent,
          ),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            fontSize: PDAStyles.fontSmall,
            fontWeight:
            seleccionado ? FontWeight.bold : FontWeight.normal,
            color: seleccionado ? Colors.white : AppColors.grisOscuro,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PRODUCTO TILE (tarjeta mejorada)
// ════════════════════════════════════════════════════════════
class _ProductoTile extends StatefulWidget {
  final ProductoModel producto;
  final AuthProvider auth;
  final VoidCallback onEditarStock;
  final VoidCallback onEliminar;
  final VoidCallback? onEditar;

  const _ProductoTile({
    required this.producto,
    required this.auth,
    required this.onEditarStock,
    required this.onEliminar,
    this.onEditar,
  });

  @override
  State<_ProductoTile> createState() => _ProductoTileState();
}

class _ProductoTileState extends State<_ProductoTile> {
  bool _expandido = false;

  Color get _colorTipo {
    return widget.producto.tipo == ProductoTipo.comestible
        ? Colors.green.shade700
        : Colors.indigo.shade700;
  }

  Color get _colorStock {
    if (widget.producto.stockReal == 0) return AppColors.rojoStock;
    if (widget.producto.esStockBajo) return AppColors.rojoStock;
    if (widget.producto.stockReal <= (widget.producto.stockMinimo * 1.5)) {
      return AppColors.amarilloAlerta;
    }
    return AppColors.verdeStock;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Fila principal ─────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icono tipo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _colorTipo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      p.tipo == ProductoTipo.comestible
                          ? Icons.restaurant_rounded
                          : Icons.shopping_bag_rounded,
                      color: _colorTipo,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nombre y clasificación
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: PDAStyles.fontMedium,
                            color: Color(0xFF1A1A2E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MiniChip(
                              texto: p.tipo.etiqueta,
                              color: _colorTipo,
                            ),
                            const SizedBox(width: 6),
                            _MiniChip(
                              texto: p.subtipo.etiqueta,
                              color: _colorTipo.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Stock real
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _colorStock.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p.stockReal}',
                          style: TextStyle(
                            color: _colorStock,
                            fontWeight: FontWeight.bold,
                            fontSize: PDAStyles.fontLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text('stock real',
                          style: TextStyle(
                              fontSize: PDAStyles.fontExtraSmall, color: AppColors.grisMedio)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expandido
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.grisMedio,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Detalle expandible ─────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _DetalleProducto(
              producto: p,
              auth: widget.auth,
              onEditarStock: widget.onEditarStock,
              onEliminar: widget.onEliminar,
              onEditar: widget.onEditar,
            ),
            crossFadeState: _expandido
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String texto;
  final Color color;
  const _MiniChip({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
            fontSize: PDAStyles.fontExtraSmall, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DetalleProducto extends StatelessWidget {
  final ProductoModel producto;
  final AuthProvider auth;
  final VoidCallback onEditarStock;
  final VoidCallback onEliminar;
  final VoidCallback? onEditar;

  const _DetalleProducto({
    required this.producto,
    required this.auth,
    required this.onEditarStock,
    required this.onEliminar,
    this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final p = producto;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Datos en grid
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
            },
            children: [
              _filaTabla('Código', p.codigo),
              _filaTabla('U. Medida', p.unidadMedida),
              _filaTabla('Proveedor', p.proveedor),
              _filaTabla('Almacenaje', p.almacenaje),
              if (p.ubicacion != null && p.ubicacion!.isNotEmpty)
                _filaTabla('Pasillo/Rack', p.ubicacion!),
              _filaTabla('Precio normal', 'S/ ${p.precio.toStringAsFixed(2)}'),
              if (p.tienePromocionActiva && p.precioPromocion != null)
                _filaTabla('Precio promo',
                    'S/ ${p.precioPromocion!.toStringAsFixed(2)}',
                    colorValor: AppColors.rojo),
              _filaTabla('Stock', '${p.stock}'),
              _filaTabla('Mínimo', '${p.stockMinimo}'),
              _filaTabla('Venta hoy', '${p.ventaHoy}'),
            ],
          ),

          // Banner promo
          if (p.tienePromocionActiva) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC02)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded,
                      color: Color(0xFF7A5900), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Promoción activa hasta ${p.finPromocion != null ? _formatFecha(p.finPromocion!) : '-'}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A5900),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Acciones
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditarStock,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: const Text('Stock',
                      style: TextStyle(fontSize: PDAStyles.fontSmall)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rojo,
                    side: const BorderSide(color: AppColors.rojo, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (auth.esSupervisor) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    label: const Text('Editar',
                        style: TextStyle(fontSize: PDAStyles.fontSmall)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      side: const BorderSide(color: Colors.indigo, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEliminar,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('Eliminar',
                        style: TextStyle(fontSize: PDAStyles.fontSmall)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rojoStock,
                      side: const BorderSide(color: AppColors.rojoStock, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  TableRow _filaTabla(String label, String valor, {Color? colorValor}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: PDAStyles.fontSmall, color: AppColors.grisMedio),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            valor,
            style: TextStyle(
              fontSize: PDAStyles.fontSmall,
              fontWeight: FontWeight.w600,
              color: colorValor ?? const Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
}

// ════════════════════════════════════════════════════════════
// EMPTY STATE
// ════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool hayFiltros;
  const _EmptyState({required this.hayFiltros});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hayFiltros
                ? Icons.filter_alt_off_rounded
                : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hayFiltros
                ? 'No hay productos con estos filtros'
                : 'No hay productos registrados',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          if (hayFiltros) ...[
            const SizedBox(height: 8),
            Text(
              'Prueba cambiando los filtros',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
