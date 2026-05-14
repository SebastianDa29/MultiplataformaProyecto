import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/enums/user_role.dart';
import '../providers/auth_provider.dart';

class RestrictedAccessDialog extends StatefulWidget {
  final Permiso permiso;
  final VoidCallback onDesbloqueado;

  const RestrictedAccessDialog({
    super.key,
    required this.permiso,
    required this.onDesbloqueado,
  });

  static Future<void> mostrar(
      BuildContext context, {
        required Permiso permiso,
        required VoidCallback onDesbloqueado,
      }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RestrictedAccessDialog(
        permiso: permiso,
        onDesbloqueado: onDesbloqueado,
      ),
    );
  }

  @override
  State<RestrictedAccessDialog> createState() => _RestrictedAccessDialogState();
}

class _RestrictedAccessDialogState extends State<RestrictedAccessDialog> {
  final _controller = TextEditingController();
  bool _cargando = false;
  String? _error;
  bool _verClave = false;

  Future<void> _verificar() async {
    setState(() { _cargando = true; _error = null; });

    final auth = context.read<AuthProvider>();
    final ok = await auth.desbloquearConClave(_controller.text, widget.permiso);

    if (!mounted) return;
    setState(() => _cargando = false);

    if (ok) {
      Navigator.of(context).pop();
      widget.onDesbloqueado();
    } else {
      setState(() => _error = AppStrings.claveIncorrecta);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.lock_outline, color: AppColors.rojo),
        const SizedBox(width: 8),
        const Text(AppStrings.accesoRestringido),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
          'Esta acción requiere autorización del supervisor.\nIngresa la clave secreta:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          obscureText: !_verClave,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppStrings.claveSecreta,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            errorText: _error,
            suffixIcon: IconButton(
              icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _verClave = !_verClave),
            ),
          ),
          onSubmitted: (_) => _verificar(),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancelar),
        ),
        ElevatedButton(
          onPressed: _cargando ? null : _verificar,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.rojo),
          child: _cargando
              ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(AppStrings.ingresar,
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}