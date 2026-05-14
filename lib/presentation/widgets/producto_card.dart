import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/stock_calculator.dart';
import '../../data/models/producto_model.dart';

class ProductoCard extends StatelessWidget {
  final ProductoModel producto;
  final VoidCallback? onTap;
  final VoidCallback? onEditarStock;

  const ProductoCard({
    super.key,
    required this.producto,
    this.onTap,
    this.onEditarStock, void Function()? onEliminar,
    ///////sdf
  });

  @override
  Widget build(BuildContext context) {
    final nivelAlerta = StockCalculator.nivelAlerta(producto.stockReal);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(children: [
                Expanded(
                  child: Text(producto.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (producto.tienePromocionActiva)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amarillo,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PROMO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 6),
              Text('Código: ${producto.codigo}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('Proveedor: ${producto.proveedor}',
                  style: const TextStyle(fontSize: 13)),

              const Divider(height: 16),

              // Precios
              Row(children: [
                Text('S/ ${producto.precio.toStringAsFixed(2)}',
                    style: TextStyle(
                        decoration: producto.tienePromocionActiva
                            ? TextDecoration.lineThrough
                            : null,
                        color: Colors.grey)),
                if (producto.tienePromocionActiva && producto.precioPromocion != null) ...[
                  const SizedBox(width: 8),
                  Text('S/ ${producto.precioPromocion!.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.rojo, fontWeight: FontWeight.bold)),
                ],
              ]),

              const SizedBox(height: 8),

              // Stock
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _StockBadge(label: 'Stock', valor: producto.stock, nivel: 0),
                _StockBadge(label: 'Venta hoy', valor: producto.ventaHoy, nivel: 0),
                _StockBadge(label: 'Stock real', valor: producto.stockReal, nivel: nivelAlerta),
                if (onEditarStock != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEditarStock,
                    tooltip: 'Editar stock',
                  ),
              ]),

              // Fechas promo
              if (producto.tienePromocionActiva &&
                  producto.inicioPromocion != null &&
                  producto.finPromocion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Promo: ${DateHelper.formatear(producto.inicioPromocion!)} '
                        '→ ${DateHelper.formatear(producto.finPromocion!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.rojo),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final int valor;
  final int nivel; // 0=normal, 1=bajo, 2=crítico

  const _StockBadge({required this.label, required this.valor, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final color = nivel == 2
        ? AppColors.rojoStock
        : nivel == 1
        ? AppColors.amarilloAlerta
        : AppColors.verdeStock;

    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 2),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          '$valor',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 14),
        ),
      ),
    ]);
  }
}