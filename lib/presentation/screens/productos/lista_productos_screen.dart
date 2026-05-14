import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../widgets/producto_card.dart';
import '../../widgets/restricted_access_dialog.dart';
import '../../../router/app_router.dart';

class ListaProductosScreen extends StatefulWidget {
  const ListaProductosScreen({super.key});

  @override
  State<ListaProductosScreen> createState() => _ListaProductosScreenState();
}

class _ListaProductosScreenState extends State<ListaProductosScreen> {
  final _busquedaCtrl = TextEditingController();
  String _filtroCategoria = 'Todos';

  final List<String> _categorias = ['Todos', 'Stock bajo', 'En promoción'];

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _editarStock(BuildContext context, dynamic producto) async {
    final ctrl = TextEditingController(text: '${producto.stock}');
    final auth = context.read<AuthProvider>();

    Future<void> guardar() async {
      final nuevo = int.tryParse(ctrl.text);
      if (nuevo == null || nuevo < 0) return;
      await context.read<InventarioProvider>().actualizarStock(
          producto.id, nuevo, auth.usuario!.nombre);
      if (context.mounted) Navigator.of(context).pop();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Editar Stock'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: AppStrings.stock,
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => guardar(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancelar),
          ),
          ElevatedButton(
            onPressed: guardar,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rojo),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _intentarEliminar(BuildContext context, dynamic producto) {
    final auth = context.read<AuthProvider>();

    Future<void> eliminar() async {
      await context.read<InventarioProvider>().eliminarProducto(
          producto.id, auth.usuario!.nombre);
      if (context.mounted) Navigator.of(context).pop();
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

  void _confirmarEliminar(BuildContext context, Future<void> Function() accion) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancelar),
          ),
          ElevatedButton(
            onPressed: () => accion(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rojoStock),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<dynamic> _aplicarFiltro(List<dynamic> productos) {
    switch (_filtroCategoria) {
      case 'Stock bajo':
        return productos.where((p) => p.stockReal <= 5).toList();
      case 'En promoción':
        return productos.where((p) => p.tienePromocionActiva).toList();
      default:
        return productos;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth       = context.watch<AuthProvider>();
    final inventario = context.watch<InventarioProvider>();
    final productos  = _aplicarFiltro(inventario.productos);

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        backgroundColor: AppColors.rojo,
        foregroundColor: AppColors.blanco,
        title: const Text(AppStrings.listaProductos),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.dashboard),
        ),
        actions: [
          if (auth.puedeEjecutar(Permiso.agregarProducto))
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: AppStrings.agregarProducto,
              onPressed: () => context.go(AppRouter.agregar),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: AppColors.blanco,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _busquedaCtrl,
              onChanged: (v) => context.read<InventarioProvider>().setFiltro(v),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o proveedor...',
                prefixIcon: const Icon(Icons.search, color: AppColors.grisMedio),
                suffixIcon: _busquedaCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _busquedaCtrl.clear();
                    context.read<InventarioProvider>().setFiltro('');
                  },
                )
                    : null,
                filled: true,
                fillColor: AppColors.grisClaro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Filtros
          Container(
            color: AppColors.blanco,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: _categorias.map((cat) {
                final activo = _filtroCategoria == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    selected: activo,
                    selectedColor: AppColors.rojo,
                    labelStyle: TextStyle(
                      color: activo ? AppColors.blanco : AppColors.grisOscuro,
                      fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _filtroCategoria = cat),
                  ),
                );
              }).toList(),
            ),
          ),

          // Contador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  '${productos.length} producto(s)',
                  style: const TextStyle(color: AppColors.grisMedio, fontSize: 13),
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: productos.isEmpty
                ? const Center(
              child: Text('No se encontraron productos',
                  style: TextStyle(color: AppColors.grisMedio)),
            )
                : ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, i) {
                final p = productos[i];
                return ProductoCard(
                  producto: p,
                  onTap: auth.puedeEjecutar(Permiso.editarProducto)
                      ? () => context.go('${AppRouter.agregar}?id=${p.id}')
                      : null,
                  onEditarStock: () => _editarStock(context, p),
                  onEliminar: auth.esSupervisor
                      ? () => _intentarEliminar(context, p)
                      : null,
                );
              },
            ),
          ),
        ],
      ),

      // FAB solo para supervisor o con permiso
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (auth.puedeEjecutar(Permiso.agregarProducto)) {
            context.go(AppRouter.agregar);
          } else {
            RestrictedAccessDialog.mostrar(
              context,
              permiso: Permiso.agregarProducto,
              onDesbloqueado: () => context.go(AppRouter.agregar),
            );
          }
        },
        backgroundColor: AppColors.rojo,
        foregroundColor: AppColors.blanco,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
    );
  }
}