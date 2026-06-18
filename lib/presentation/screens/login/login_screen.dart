import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;
  String? _errorMsg;

  final Map<String, String> _demoUsers = {
    'basico': '1234',
    'inventarista1': '1234',
    'inventarista2': '1234',
    'inventarista3': '1234',
    'supervisor': '1234',
  };

  @override
  void initState() {
    super.initState();

    // Acceso rápido de prueba
    _userCtrl.text = 'basico';
    _passCtrl.text = '1234';
  }

  Future<void> _doLogin() async {
    final user = _userCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'Completa usuario y contraseña.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      // Simulación de validación
      await Future.delayed(const Duration(milliseconds: 500));

      final isValid = _demoUsers[user] == pass;

      if (!isValid) {
        if (!mounted) return;
        setState(() => _errorMsg = 'Usuario o contraseña incorrectos.');
        return;
      }

      if (!mounted) return;

      context.go(AppRouter.dashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Error de conexión. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  double _clampDouble(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 40,
            child: _buildLeftPanel(),
          ),
          Expanded(
            flex: 60,
            child: _buildRightPanel(compact: false),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMobileHeader(),
            const SizedBox(height: 16),
            _buildCompactPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final sidePad = _clampDouble(w * 0.08, 20, 36);
        final titleSize = _clampDouble(w * 0.055, 20, 28);
        final subtitleSize = _clampDouble(w * 0.022, 12, 14);
        final featureSize = _clampDouble(w * 0.021, 11, 13);

        return Container(
          color: AppColors.red,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(color: AppColors.red),
              ),
              Positioned(
                top: -60,
                right: -80,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.redDark,
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(height: 6, color: AppColors.yellow),
              ),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: h),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(sidePad, 32, sidePad, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _dot(AppColors.yellow),
                                  const SizedBox(width: 6),
                                  _dot(Colors.white.withValues(alpha: 0.35)),
                                  const SizedBox(width: 6),
                                  _dot(Colors.white.withValues(alpha: 0.35)),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Container(
                                width: _clampDouble(w * 0.18, 54, 70),
                                height: _clampDouble(w * 0.18, 54, 70),
                                decoration: BoxDecoration(
                                  color: AppColors.yellow,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.redDeep,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'China\nBusiness Fast',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sistema de Gestión\nde Inventario · Chincha Alta',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: subtitleSize,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _featureItem(
                                Icons.inventory_2_outlined,
                                'Control de stock',
                                'en tiempo real',
                                fontSize: featureSize,
                              ),
                              _featureItem(
                                Icons.warning_amber_outlined,
                                'Registro de mermas',
                                'con historial',
                                fontSize: featureSize,
                              ),
                              _featureItem(
                                Icons.local_offer_outlined,
                                'Promociones activas',
                                'automáticas',
                                fontSize: featureSize,
                              ),
                              _featureItem(
                                Icons.qr_code_scanner,
                                'Lector de código',
                                'de barras integrado',
                                fontSize: featureSize,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white24, height: 1),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.yellow,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: AppColors.redDeep,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Acceso controlado por roles\nSupervisor · Inventarista',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 10,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTopBar(compact: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: _buildLoginForm(compact: true),
          ),
          _buildFooter(compact: true),
        ],
      ),
    );
  }

  Widget _buildRightPanel({required bool compact}) {
    final horizontal = compact ? 20.0 : 32.0;
    final vertical = compact ? 20.0 : 28.0;

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(compact: compact),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: vertical,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildLoginForm(compact: compact),
                ),
              ),
            ),
          ),
          _buildFooter(compact: compact),
        ],
      ),
    );
  }

  Widget _buildTopBar({required bool compact}) {
    return Container(
      color: AppColors.yellow,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 24,
        vertical: compact ? 8 : 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'INVENTARIO 2026 · CHINCHA ALTA, ICA',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 9.5 : 10,
                fontWeight: FontWeight.w700,
                color: AppColors.redDeep,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'v1.0',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm({required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bienvenido',
          style: TextStyle(
            fontSize: compact ? 22 : 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ingresa tus credenciales para acceder al sistema de inventario.',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        if (_errorMsg != null) ...[
          _ErrorBox(message: _errorMsg!),
          const SizedBox(height: 14),
        ],
        _InputField(
          label: 'USUARIO',
          controller: _userCtrl,
          hint: 'Ingresa tu usuario',
          icon: Icons.person_outline_rounded,
          onSubmit: () => FocusScope.of(context).requestFocus(_passFocus),
        ),
        const SizedBox(height: 14),
        _InputField(
          label: 'CONTRASEÑA',
          controller: _passCtrl,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: _obscure,
          focusNode: _passFocus,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          onSubmit: _doLogin,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _userCtrl.text = 'basico';
                  _passCtrl.text = '1234';
                  setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Usuario básico'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _userCtrl.text = 'supervisor';
                  _passCtrl.text = '1234';
                  setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Supervisor'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _doLogin,
            icon: _loading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
                : const Icon(Icons.login_rounded, size: 20),
            label: Text(
              _loading ? 'Verificando...' : 'Ingresar al sistema',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.redDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 24,
        vertical: compact ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '© 2026 China Business Fast · Todos los derechos reservados',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_rounded,
                  color: AppColors.white,
                  size: 11,
                ),
                SizedBox(width: 4),
                Text(
                  'CBF',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.redDeep,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'China Business Fast',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Sistema de Inventario',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
    ),
  );

  Widget _featureItem(
      IconData icon,
      String bold,
      String normal, {
        required double fontSize,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.yellow, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$bold ',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: normal,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final FocusNode? focusNode;
  final VoidCallback? onToggleObscure;
  final VoidCallback? onSubmit;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.focusNode,
    this.onToggleObscure,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          onFieldSubmitted: (_) => onSubmit?.call(),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.muted,
              size: 18,
            ),
            suffixIcon: onToggleObscure != null
                ? IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.muted,
                size: 18,
              ),
              onPressed: onToggleObscure,
            )
                : null,
            filled: true,
            fillColor: AppColors.offWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.red,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFECACA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}