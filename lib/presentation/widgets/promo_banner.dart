import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../data/models/producto_model.dart';

class PromoBanner extends StatelessWidget {
  final ProductoModel producto;

  const PromoBanner({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    if (!producto.tienePromocionActiva || producto.precioPromocion == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amarillo.withOpacity(0.15),
        border: Border.all(color: AppColors.amarillo),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.local_offer, color: AppColors.amarillo, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Promoción activa: S/ ${producto.precioPromocion!.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (producto.inicioPromocion != null && producto.finPromocion != null)
              Text(
                '${DateHelper.formatear(producto.inicioPromocion!)} '
                    '→ ${DateHelper.formatear(producto.finPromocion!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ]),
        ),
      ]),
    );
  }
}