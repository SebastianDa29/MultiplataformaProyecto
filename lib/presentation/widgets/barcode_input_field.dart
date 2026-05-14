import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/barcode_service.dart';

// ===========================================================
// WIDGET: CAMPO DE CAPTURA DE CÓDIGO DE BARRAS
//
// MODO ACTUAL: Lector USB (actúa como teclado)
//   - El usuario enfoca el campo y pasa el lector por el código.
//   - El lector envía el texto y presiona ENTER automáticamente.
//   - El callback onCodigoDetectado se dispara al recibir ENTER.
//
// MODO MANUAL: Puede usarse también sin lector, escribiendo a mano.
//
// [ACTIVAR PARA CÁMARA] - Ver barcode_service.dart para instrucciones.
// ===========================================================

class BarcodeInputField extends StatefulWidget {
  final Function(String codigo) onCodigoDetectado;
  final String label;
  final bool autoFocus;

  const BarcodeInputField({
    super.key,
    required this.onCodigoDetectado,
    this.label = 'Escanea o ingresa el código',
    this.autoFocus = true,
  });

  @override
  State<BarcodeInputField> createState() => _BarcodeInputFieldState();
}

class _BarcodeInputFieldState extends State<BarcodeInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  // ← AQUÍ SE DETECTA EL INGRESO DEL CÓDIGO (por ENTER del lector o manual)
  void _onSubmit(String value) {
    final codigo = BarcodeService.limpiar(value);
    if (!BarcodeService.esValido(codigo)) return;
    widget.onCodigoDetectado(codigo);
    _controller.clear();
    _focus.requestFocus(); // mantiene el foco para siguiente escaneo
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      autofocus: widget.autoFocus,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.rojo),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.rojo, width: 2),
        ),
        helperText: 'Enfoca aquí antes de escanear',  // ← INDICACIÓN AL USUARIO
      ),
      // ← AQUÍ SE ACTIVA EL LECTOR FÍSICO (onSubmitted = cuando llega ENTER)
      onSubmitted: _onSubmit,
      textInputAction: TextInputAction.search,
    );
  }
}