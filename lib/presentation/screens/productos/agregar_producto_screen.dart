import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/stock_calculator.dart';
import '../../../data/models/producto_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../widgets/barcode_input_field.dart';
import '../../widgets/promo_banner.dart';
import '../../../router/app_router.dart';

class AgregarProductoScreen extends StatefulWidget {
  // Cuando se edita, se pasa el producto existente
  final ProductoModel? productoExistente;

  const AgregarProductoScreen({super.key, this.productoExistente});

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _proveedorCtrl;
  late final TextEditingController _almacenajeCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _promoCtrl;
  late final TextEditingController _stockCtrl;

  DateTime? _inicioPromo;
  DateTime? _finPromo;
  bool _guardando = false;
  bool get _esEdicion => widget.productoExistente != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productoExistente;
    _codigoCtrl     = TextEditingController(text: p?.codigo ?? '');
    _nombreCtrl     = TextEditingController(text: p?.nombre ?? '');
    _proveedorCtrl  = TextEditingController(text: p?.proveedor ?? '');
    _almacenajeCtrl = TextEditingController(text: p?.almacenaje ?? '');
    _precioCtrl     = TextEditingController(text: p != null ? '${p.precio}' : '');
    _promoCtrl      = TextEditingController(
        text: p?.precioPromocion != null ? '${p!.precioPromocion}' : '');
    _stockCtrl      = TextEditingController(text: p != null ? '${p.stock}' : '');
    _inicioPromo    = p?.inicioPromocion;
    _finPromo       = p?.finPromocion;
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _proveedorCtrl.dispose();
    _almacenajeCtrl.dispose();
    _precioCtrl.dispose();
    _promoCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  bool get _tienePromocion => _promoCtrl.text.trim().isNotEmpty;

  int get _stockReal {
    final stock = int.tryParse(_stockCtrl.text) ?? 0;
    return StockCalculator.calcularStockReal(stock, 0);
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final inicial = esInicio ? _inicioPromo : _finPromo;
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.rojo),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (esInicio) {
          _inicioPromo = picked;
        } else {
          _finPromo = picked;
        }
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final auth    = context.read<AuthProvider>();
    final inv     = context.read<InventarioProvider>();
    final usuario = auth.usuario!;

    final precioNormal = double.parse(_precioCtrl.text.replaceAll(',', '.'));
    final precioPromo  = _promoCtrl.text.isNotEmpty
        ? double.tryParse(_promoCtrl.text.replaceAll(',', '.'))
        : null;
    final stock = int.parse(_stockCtrl.text);

    final producto = ProductoModel(
      id: _esEdicion ? widget.productoExistente!.id : '',
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      proveedor: _proveedorCtrl.text.trim(),
      almacenaje: _almacenajeCtrl.text.trim(),
      precio: precioNormal,
      precioPromocion: precioPromo,
      inicioPromocion: _tienePromocion ? _inicioPromo : null,
      finPromocion: _tienePromocion ? _finPromo : null,
      stock: stock,
      ventaHoy: _esEdicion ? widget.productoExistente!.ventaHoy : 0,
      creadoPor: usuario.nombre,
      creadoEn: _esEdicion ? widget.productoExistente!.creadoEn : DateTime.now(),
    );

    try {
      if (_esEdicion) {
        await inv.actualizarProducto(producto, usuario.nombre);
      } else {
        await inv.agregarProducto(producto, usuario.nombre);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esEdicion ? 'Producto actualizado' : AppStrings.guardadoOk),
          backgroundColor: AppColors.verdeStock,
        ),
      );
      context.go(AppRouter.productos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.errorGuardar),
          backgroundColor: AppColors.rojoStock,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final esSupervisor = auth.esSupervisor;

    return Scaffold(
      backgroundColor: AppColors.grisClaro,
      appBar: AppBar(
        backgroundColor: AppColors.rojo,
        foregroundColor: AppColors.blanco,
        title: Text(_esEdicion ? 'Editar Producto' : AppStrings.agregarProducto),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.productos),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Sección: Identificación ─────────────────────
              _SectionTitle(titulo: 'Identificación'),

              // Código de barras
              // ← AQUÍ SE CAPTURA EL CÓDIGO (lector USB o manual)
              if (!_esEdicion) ...[
                BarcodeInputField(
                  onCodigoDetectado: (codigo) {
                    setState(() => _codigoCtrl.text = codigo);
                  },
                  label: 'Escanear código de barras',
                  autoFocus: false,
                ),
                const SizedBox(height: 10),
              ],

              // Código (no editable si ya existe)
              _Campo(
                controller: _codigoCtrl,
                label: AppStrings.codigo,
                readOnly: _esEdicion, // ← código de barras bloqueado en edición
                validator: Validators.codigoBarras,
                prefixIcon: Icons.qr_code,
                helperText: _esEdicion ? 'El código no puede modificarse' : null,
              ),
              const SizedBox(height: 12),

              _Campo(
                controller: _nombreCtrl,
                label: AppStrings.nombre,
                validator: (v) => Validators.requerido(v, campo: 'El nombre'),
                prefixIcon: Icons.label_outline,
                enabled: esSupervisor || !_esEdicion,
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: _Campo(
                    controller: _proveedorCtrl,
                    label: AppStrings.proveedor,
                    validator: (v) => Validators.requerido(v, campo: 'El proveedor'),
                    prefixIcon: Icons.business_outlined,
                    enabled: esSupervisor || !_esEdicion,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Campo(
                    controller: _almacenajeCtrl,
                    label: AppStrings.almacenaje,
                    validator: (v) => Validators.requerido(v, campo: 'El almacenaje'),
                    prefixIcon: Icons.warehouse_outlined,
                    enabled: esSupervisor,
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Sección: Precios ──────────────────────────────
              _SectionTitle(titulo: 'Precios'),

              Row(children: [
                Expanded(
                  child: _Campo(
                    controller: _precioCtrl,
                    label: '${AppStrings.precio} (S/)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => Validators.numero(v, campo: 'El precio'),
                    prefixIcon: Icons.attach_money,
                    enabled: esSupervisor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Campo(
                    controller: _promoCtrl,
                    label: '${AppStrings.promocion} (S/)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final precio = double.tryParse(_precioCtrl.text) ?? 0;
                      return Validators.precioPromocion(v, precio);
                    },
                    prefixIcon: Icons.local_offer_outlined,
                    enabled: esSupervisor,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),

              // Fechas de promoción (solo si hay precio promo)
              if (_tienePromocion) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _DateField(
                      label: AppStrings.inicioPromo,
                      fecha: _inicioPromo,
                      onTap: () => _seleccionarFecha(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: AppStrings.finPromo,
                      fecha: _finPromo,
                      onTap: () => _seleccionarFecha(context, false),
                    ),
                  ),
                ]),
              ],

              const SizedBox(height: 20),

              // ── Sección: Stock ────────────────────────────────
              _SectionTitle(titulo: 'Stock'),

              Row(children: [
                Expanded(
                  child: _Campo(
                    controller: _stockCtrl,
                    label: AppStrings.stock,
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.enteroPositivo(v, campo: 'El stock'),
                    prefixIcon: Icons.inventory_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                // Venta de hoy: solo lectura, siempre 0 al crear
                Expanded(
                  child: _CampoReadOnly(
                    label: AppStrings.ventaHoy,
                    valor: _esEdicion
                        ? '${widget.productoExistente!.ventaHoy}'
                        : '0',
                    icono: Icons.point_of_sale_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                // Stock real: calculado automáticamente
                Expanded(
                  child: _CampoReadOnly(
                    label: AppStrings.stockReal,
                    valor: '$_stockReal',
                    icono: Icons.calculate_outlined,
                    color: StockCalculator.esBajo(_stockReal)
                        ? AppColors.rojoStock
                        : AppColors.verdeStock,
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              // Banner de promoción activa (en edición)
              if (_esEdicion && widget.productoExistente!.tienePromocionActiva)
                PromoBanner(producto: widget.productoExistente!),

              const SizedBox(height: 28),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.save_outlined, color: Colors.white),
                  label: Text(
                    _esEdicion ? 'Actualizar Producto' : 'Guardar Producto',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rojo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRouter.productos),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.grisMedio),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(AppStrings.cancelar,
                      style: TextStyle(color: AppColors.grisOscuro)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets internos ─────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String titulo;
  const _SectionTitle({required this.titulo});

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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.grisOscuro,
            ),
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool readOnly;
  final bool enabled;
  final String? helperText;
  final void Function(String)? onChanged;

  const _Campo({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.readOnly = false,
    this.enabled = true,
    this.helperText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        filled: !enabled,
        fillColor: !enabled ? AppColors.grisClaro : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.rojo, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _CampoReadOnly extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color? color;

  const _CampoReadOnly({
    required this.label,
    required this.valor,
    required this.icono,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.grisClaro,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grisMedio.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.grisMedio)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icono, size: 16, color: color ?? AppColors.grisMedio),
              const SizedBox(width: 6),
              Text(
                valor,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color ?? AppColors.grisOscuro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? fecha;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.fecha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grisMedio.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.rojo),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grisMedio)),
                  const SizedBox(height: 2),
                  Text(
                    fecha != null ? DateHelper.formatear(fecha!) : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fecha != null
                          ? AppColors.grisOscuro
                          : AppColors.grisMedio,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}