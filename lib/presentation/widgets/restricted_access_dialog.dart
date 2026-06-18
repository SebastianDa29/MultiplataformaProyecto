import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/pda_styles.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PDAStyles.borderRadius)),
      title: Row(children: [
        const Icon(Icons.lock_outline, color: AppColors.rojo, size: 28),
        const SizedBox(width: PDAStyles.targetPadding / 2),
        Text(AppStrings.accesoRestringido, 
          style: PDAStyles.headerStyle.copyWith(color: Colors.black)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
          'Esta acción requiere autorización del supervisor.\nIngresa la clave secreta:',
          style: TextStyle(fontSize: PDAStyles.fontMedium),
        ),
        const SizedBox(height: PDAStyles.targetPadding),
        TextField(
          controller: _controller,
          obscureText: !_verClave,
          autofocus: true,
          style: PDAStyles.valueStyle,
          decoration: PDAStyles.inputDecoration(
            AppStrings.claveSecreta,
            icon: Icons.vpn_key,
          ).copyWith(
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(100, PDAStyles.minTouchTarget),
                ),
                child: const Text(AppStrings.cancelar, style: TextStyle(fontSize: PDAStyles.fontMedium)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _cargando ? null : _verificar,
                style: PDAStyles.primaryButtonStyle.copyWith(
                  minimumSize: WidgetStateProperty.all(const Size(120, PDAStyles.minTouchTarget)),
                ),
                child: _cargando
                    ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text(AppStrings.ingresar,
                    style: PDAStyles.buttonTextStyle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}