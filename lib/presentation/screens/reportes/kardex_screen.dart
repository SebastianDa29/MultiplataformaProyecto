import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/tipo_movimiento.dart';
import '../../../core/utils/date_helper.dart';
import '../../providers/inventario_provider.dart';
import '../../../router/app_router.dart';

class KardexScreen extends StatefulWidget {
  const KardexScreen({super.key});

  @override
  State<KardexScreen> createState() => _KardexScreenState();
}

class _KardexScreenState extends State<KardexScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>().escucharMovimientos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventario = context.watch<InventarioProvider>();
    final movimientos = inventario.movimientos;

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        title: const Text('Kardex / Movimientos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.dashboard),
        ),
      ),
      body: movimientos.isEmpty
          ? const Center(child: Text('No hay movimientos registrados'))
          : ListView.builder(
              itemCount: movimientos.length,
              itemBuilder: (context, index) {
                final mov = movimientos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    isThreeLine: true,
                    leading: _getIconForTipo(mov.tipo),
                    title: Text(mov.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Motivo: ${mov.motivo}'),
                        Text('Por: ${mov.usuarioNombre} - ${DateHelper.formatearConHora(mov.fecha)}'),
                      ],
                    ),
                    trailing: Text(
                      '${mov.cantidad > 0 ? "+" : ""}${mov.cantidad}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getColorForTipo(mov.tipo),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _getIconForTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return const Icon(Icons.add_circle_outline, color: AppColors.verdeStock);
      case TipoMovimiento.salida:
        return const Icon(Icons.remove_circle_outline, color: AppColors.rojoStock);
      case TipoMovimiento.merma:
        return const Icon(Icons.delete_outline, color: AppColors.rojo);
      case TipoMovimiento.ajuste:
        return const Icon(Icons.edit_note, color: Colors.blue);
      case TipoMovimiento.inicial:
        return const Icon(Icons.inventory_2, color: Colors.orange);
    }
  }

  Color _getColorForTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return AppColors.verdeStock;
      case TipoMovimiento.salida:
        return AppColors.rojoStock;
      case TipoMovimiento.merma:
        return AppColors.rojo;
      case TipoMovimiento.ajuste:
        return Colors.blue;
      case TipoMovimiento.inicial:
        return Colors.orange;
    }
  }
}
