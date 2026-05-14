import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/merma_tipo.dart';
import '../../../core/utils/date_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../../router/app_router.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final inventario = context.watch<InventarioProvider>();

    // Métricas
    final totalProductos  = inventario.productos.length;
    final stockBajo       = inventario.productosStockBajo;
    final conPromocion    = inventario.productosConPromocion;
    final todasMermas     = inventario.mermas;

    final valorInventario = inventario.productos
        .fold<double>(0, (sum, p) => sum + (p.precio * p.stock));

    final mermasPorTipo = <MermaTipo, int>{};
    for (final m in todasMermas) {
      mermasPorTipo[m.tipo] = (mermasPorTipo[m.tipo] ?? 0) + m.cantidad;
    }

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        backgroundColor: AppColors.rojo,
        foregroundColor: AppColors.blanco,
        title: const Text('Reportes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.dashboard),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Cabecera del reporte
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.rojo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reporte General de Inventario',
                      style: TextStyle(
                          color: AppColors.blanco,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Generado: ${DateHelper.formatearConHora(DateTime.now())}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Por: ${auth.usuario?.nombre ?? ''}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const _SectionHeader(titulo: 'Resumen General'),

            // Cards de métricas
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _MetricaCard(
                  titulo: 'Total Productos',
                  valor: '$totalProductos',
                  icono: Icons.inventory_2_outlined,
                  color: AppColors.rojo,
                ),
                _MetricaCard(
                  titulo: 'Valor Inventario',
                  valor: 'S/ ${valorInventario.toStringAsFixed(2)}',
                  icono: Icons.monetization_on_outlined,
                  color: AppColors.verdeStock,
                ),
                _MetricaCard(
                  titulo: 'Stock Bajo',
                  valor: '${stockBajo.length}',
                  icono: Icons.warning_amber_rounded,
                  color: AppColors.amarilloAlerta,
                ),
                _MetricaCard(
                  titulo: 'En Promoción',
                  valor: '${conPromocion.length}',
                  icono: Icons.local_offer_outlined,
                  color: AppColors.amarillo,
                ),
              ],
            ),

            const SizedBox(height: 20),
            const _SectionHeader(titulo: 'Mermas por Tipo'),

            // Tabla de mermas por tipo
            Container(
              decoration: BoxDecoration(
                color: AppColors.blanco,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: mermasPorTipo.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text('No hay mermas registradas',
                      style: TextStyle(color: AppColors.grisMedio)),
                ),
              )
                  : Column(
                children: MermaTipo.values.map((tipo) {
                  final cantidad = mermasPorTipo[tipo] ?? 0;
                  return _FilaMerma(tipo: tipo, cantidad: cantidad);
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
            const _SectionHeader(titulo: 'Productos con Stock Bajo'),

            if (stockBajo.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.verdeStock),
                    SizedBox(width: 8),
                    Text('Todos los productos tienen stock suficiente'),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: stockBajo.map((p) {
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.rojoStock.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: AppColors.rojoStock, size: 20),
                      ),
                      title: Text(p.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Código: ${p.codigo} · Proveedor: ${p.proveedor}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Stock: ${p.stock}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.rojoStock)),
                          Text('Real: ${p.stockReal}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.grisMedio)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 20),
            const _SectionHeader(titulo: 'Productos en Promoción Activa'),

            if (conPromocion.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.grisMedio),
                    SizedBox(width: 8),
                    Text('No hay promociones activas en este momento'),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: conPromocion.map((p) {
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.amarillo.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_offer_outlined,
                            color: AppColors.amarillo, size: 20),
                      ),
                      title: Text(p.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: p.finPromocion != null
                          ? Text(
                          'Hasta: ${DateHelper.formatear(p.finPromocion!)}',
                          style: const TextStyle(fontSize: 12))
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'S/ ${p.precioPromocion?.toStringAsFixed(2) ?? '-'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.rojo),
                          ),
                          Text(
                            'Normal: S/ ${p.precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.grisMedio,
                                decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internos ─────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String titulo;
  const _SectionHeader({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.rojo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.grisOscuro),
          ),
        ],
      ),
    );
  }
}

class _MetricaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _MetricaCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(fontSize: 11, color: AppColors.grisMedio),
          ),
        ],
      ),
    );
  }
}

class _FilaMerma extends StatelessWidget {
  final MermaTipo tipo;
  final int cantidad;

  const _FilaMerma({required this.tipo, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.grisMedio.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(tipo.etiqueta,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cantidad > 0
                  ? AppColors.rojoStock.withOpacity(0.1)
                  : AppColors.grisClaro,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$cantidad unidades',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cantidad > 0 ? AppColors.rojoStock : AppColors.grisMedio,
              ),
            ),
          ),
        ],
      ),
    );
  }
}