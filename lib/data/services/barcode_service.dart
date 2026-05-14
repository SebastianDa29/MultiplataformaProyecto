// ===========================================================
// SERVICIO DE LECTURA DE CÓDIGO DE BARRAS
// ===========================================================
// El lector casero USB funciona como teclado (HID Device).
// Cuando escanea, envía el código como texto y presiona ENTER.
// Por eso no se necesita ninguna librería especial para él.
//
// La captura se hace con un TextEditingController en el widget
// BarcodeInputField. Ver: presentation/widgets/barcode_input_field.dart
//
// Si en el futuro quieres usar CÁMARA en lugar de lector USB,
// activa la sección marcada como [ACTIVAR PARA CÁMARA].
// ===========================================================

// [ACTIVAR PARA CÁMARA] - Agrega a pubspec.yaml:
//   mobile_scanner: ^3.5.0
//
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// class BarcodeCameraService {
//   MobileScannerController? controller;
//
//   void iniciar(Function(String codigo) onDetectado) {
//     controller = MobileScannerController();
//     // Usar MobileScanner widget en el screen correspondiente
//   }
//
//   void detener() {
//     controller?.dispose();
//   }
// }

class BarcodeService {
  // El lector USB no necesita inicialización.
  // Solo asegúrate de que el campo de texto esté enfocado
  // cuando el usuario apunte el lector al código.

  /// Limpia el código capturado (quita espacios y saltos de línea)
  static String limpiar(String raw) => raw.trim().replaceAll('\n', '').replaceAll('\r', '');

  /// Valida que el código tenga formato aceptable
  static bool esValido(String codigo) => codigo.length >= 4;
}