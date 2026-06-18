import 'package:flutter/material.dart';
import 'app_colors.dart';

class PDAStyles {
  // ── Dimensiones para PDA ──────────────────────────────
  static const double targetPadding = 16.0;
  static const double minTouchTarget = 48.0;
  static const double borderRadius = 12.0;
  
  // ── Tamaños de Fuente ─────────────────────────────────
  static const double fontExtraSmall = 12.0;
  static const double fontSmall = 14.0;
  static const double fontMedium = 16.0;
  static const double fontLarge = 18.0;
  static const double fontExtraLarge = 22.0;
  static const double fontHuge = 28.0;

  // ── Estilos de Texto ──────────────────────────────────
  static const TextStyle labelStyle = TextStyle(
    fontSize: fontSmall,
    fontWeight: FontWeight.bold,
    color: AppColors.grisOscuro,
  );

  static const TextStyle valueStyle = TextStyle(
    fontSize: fontMedium,
    fontWeight: FontWeight.w600,
    color: AppColors.negro,
  );

  static const TextStyle headerStyle = TextStyle(
    fontSize: fontLarge,
    fontWeight: FontWeight.bold,
    color: AppColors.blanco,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: fontMedium,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1,
  );

  // ── Decoraciones ──────────────────────────────────────
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.blanco,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.rojo) : null,
      labelStyle: const TextStyle(fontSize: fontMedium),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: AppColors.rojo, width: 2.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // ── Estilos de Botón ──────────────────────────────────
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.rojo,
    foregroundColor: AppColors.blanco,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    elevation: 4,
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.rojo,
    side: const BorderSide(color: AppColors.rojo, width: 2),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );
}
