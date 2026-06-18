import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pda_styles.dart';
import '../../../core/enums/producto_tipo.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/stock_calculator.dart';
import '../../../data/models/producto_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../../router/app_router.dart';

class AgregarProductoScreen extends StatefulWidget {
  final ProductoModel? productoExistente;

  const AgregarProductoScreen({super.key, this.productoExistente});

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen>
    with TickerProviderStateMixin {

  // ── Controladores de texto ───────────────────────────────
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _proveedorCtrl;
  late final TextEditingController _almacenajeCtrl;
  late final TextEditingController _ubicacionCtrl;
  late final TextEditingController _unidadMedidaCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _promoCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _stockMinimoCtrl;

  // ── Estado del formulario ────────────────────────────────
  final _formKey        = GlobalKey<FormState>();
  DateTime? _inicioPromo;
  DateTime? _finPromo;
  ProductoTipo    _tipo    = ProductoTipo.comestible;
  ProductoSubtipo _subtipo = ProductoSubtipo.comidasInstantaneas;
  bool _guardando = false;
  int  _pasoActual = 0; // 0=Identificación 1=Clasificación 2=Precios 3=Stock

  // ── Animaciones ──────────────────────────────────────────
  late AnimationController _entradaCtrl;
  late AnimationController _pasoCtrl;
  late Animation<double>   _fadeEntrada;
  late Animation<Offset>   _slideEntrada;

  bool get _esEdicion => widget.productoExistente != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productoExistente;

    _codigoCtrl     = TextEditingController(text: p?.codigo ?? '');
    _nombreCtrl     = TextEditingController(text: p?.nombre ?? '');
    _proveedorCtrl  = TextEditingController(text: p?.proveedor ?? '');
    _almacenajeCtrl = TextEditingController(text: p?.almacenaje ?? '');
    _ubicacionCtrl  = TextEditingController(text: p?.ubicacion ?? '');
    _unidadMedidaCtrl = TextEditingController(text: p?.unidadMedida ?? 'Unidad');
    _precioCtrl     = TextEditingController(
        text: p != null ? p.precio.toStringAsFixed(2) : '');
    _promoCtrl      = TextEditingController(
        text: p?.precioPromocion != null
            ? p!.precioPromocion!.toStringAsFixed(2)
            : '');
    _stockCtrl      = TextEditingController(
        text: p != null ? '${p.stock}' : '');
    _stockMinimoCtrl = TextEditingController(
        text: p != null ? '${p.stockMinimo}' : '5');

    _tipo    = p?.tipo    ?? ProductoTipo.comestible;
    _subtipo = p?.subtipo ?? ProductoTipo.comestible.subtipos.first;
    _inicioPromo = p?.inicioPromocion;
    _finPromo    = p?.finPromocion;

    _entradaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pasoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeEntrada = CurvedAnimation(
        parent: _entradaCtrl, curve: Curves.easeOut);
    _slideEntrada = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entradaCtrl, curve: Curves.easeOut));

    _entradaCtrl.forward();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _proveedorCtrl.dispose();
    _almacenajeCtrl.dispose();
    _ubicacionCtrl.dispose();
    _unidadMedidaCtrl.dispose();
    _precioCtrl.dispose();
    _promoCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _entradaCtrl.dispose();
    _pasoCtrl.dispose();
    super.dispose();
  }

  // ── Getters calculados ───────────────────────────────────
  bool get _tienePromocion => _promoCtrl.text.trim().isNotEmpty;

  int get _stockActual => int.tryParse(_stockCtrl.text) ?? 0;

  int get _stockReal => StockCalculator.calcularStockReal(_stockActual, 0);

  double get _precioNormal =>
      double.tryParse(_precioCtrl.text.replaceAll(',', '.')) ?? 0;

  double? get _precioPromo =>
      _promoCtrl.text.isNotEmpty
          ? double.tryParse(_promoCtrl.text.replaceAll(',', '.'))
          : null;

  double get _ahorro =>
      _precioPromo != null ? _precioNormal - _precioPromo! : 0;

  double get _porcentajeDescuento =>
      _precioNormal > 0 && _precioPromo != null
          ? ((_precioNormal - _precioPromo!) / _precioNormal) * 100
          : 0;

  // ── Pasos del wizard ─────────────────────────────────────
  static const List<String> _pasos = [
    'Identificación',
    'Clasificación',
    'Precios',
    'Stock',
  ];

  static const List<IconData> _iconosPasos = [
    Icons.qr_code_rounded,
    Icons.category_rounded,
    Icons.attach_money_rounded,
    Icons.inventory_2_rounded,
  ];

  bool _validarPasoActual() {
    switch (_pasoActual) {
      case 0:
        return _codigoCtrl.text.trim().length >= 4 &&
            _nombreCtrl.text.trim().isNotEmpty &&
            _proveedorCtrl.text.trim().isNotEmpty &&
            _almacenajeCtrl.text.trim().isNotEmpty;
      case 1:
        return true; // tipo y subtipo siempre válidos
      case 2:
        return _precioNormal > 0;
      case 3:
        return _stockActual >= 0;
      default:
        return true;
    }
  }

  void _irAPaso(int paso) {
    if (paso < _pasoActual || _validarPasoActual()) {
      setState(() => _pasoActual = paso);
      _pasoCtrl.forward(from: 0);
    } else {
      _mostrarErrorPaso();
    }
  }

  void _siguiente() {
    if (_validarPasoActual()) {
      if (_pasoActual < _pasos.length - 1) {
        setState(() => _pasoActual++);
        _pasoCtrl.forward(from: 0);
      } else {
        _guardar();
      }
    } else {
      _mostrarErrorPaso();
    }
  }

  void _anterior() {
    if (_pasoActual > 0) {
      setState(() => _pasoActual--);
      _pasoCtrl.forward(from: 0);
    }
  }

  void _mostrarErrorPaso() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Completa todos los campos requeridos'),
          ],
        ),
        backgroundColor: AppColors.rojo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Guardar ──────────────────────────────────────────────
  Future<void> _guardar() async {
    setState(() => _guardando = true);
    HapticFeedback.mediumImpact();

    final auth    = context.read<AuthProvider>();
    final inv     = context.read<InventarioProvider>();
    final usuario = auth.usuario!;

    final producto = ProductoModel(
      id:              _esEdicion ? widget.productoExistente!.id : '',
      codigo:          _codigoCtrl.text.trim(),
      nombre:          _nombreCtrl.text.trim(),
      proveedor:       _proveedorCtrl.text.trim(),
      almacenaje:      _almacenajeCtrl.text.trim(),
      ubicacion:       _ubicacionCtrl.text.trim().isEmpty ? null : _ubicacionCtrl.text.trim(),
      unidadMedida:    _unidadMedidaCtrl.text.trim(),
      precio:          _precioNormal,
      precioPromocion: _precioPromo,
      inicioPromocion: _tienePromocion ? _inicioPromo : null,
      finPromocion:    _tienePromocion ? _finPromo    : null,
      stock:           _stockActual,
      stockMinimo:     int.tryParse(_stockMinimoCtrl.text) ?? 0,
      ventaHoy:        _esEdicion ? widget.productoExistente!.ventaHoy : 0,
      creadoPor:       usuario.nombre,
      creadoEn:        _esEdicion
          ? widget.productoExistente!.creadoEn
          : DateTime.now(),
      tipo:    _tipo,
      subtipo: _subtipo,
    );

    try {
      if (_esEdicion) {
        await inv.actualizarProducto(producto, usuario);
      } else {
        await inv.agregarProducto(producto, usuario);
      }

      if (!mounted) return;
      
      // Cambiamos el orden: Primero mostramos éxito, esperamos y LUEGO navegamos
      // asegurándonos de cerrar cualquier diálogo.
      _mostrarExito();
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        // Cerramos el diálogo de éxito antes de navegar para evitar que "quede" en el stack
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        context.go(AppRouter.productos);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false); // Asegurar que se desbloquee en error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.rojoStock,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      // No seteamos _guardando a false aquí si la navegación fue exitosa 
      // para evitar parpadeos del botón antes de cambiar de pantalla.
      // Pero si sigue montado y hubo un error, el catch ya lo manejó.
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(PDAStyles.borderRadius)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.verdeStock.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.verdeStock,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _esEdicion ? 'Producto actualizado' : '¡Producto guardado!',
                style: const TextStyle(
                  fontSize: PDAStyles.fontExtraLarge,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _nombreCtrl.text.trim(),
                style: const TextStyle(
                    color: AppColors.grisMedio, fontSize: PDAStyles.fontMedium),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Selector de fecha ────────────────────────────────────
  Future<void> _seleccionarFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (esInicio ? _inicioPromo : _finPromo) ?? DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final esSupervisor = auth.esSupervisor;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: FadeTransition(
        opacity: _fadeEntrada,
        child: SlideTransition(
          position: _slideEntrada,
          child: CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.rojo,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.go(AppRouter.productos),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _esEdicion ? 'Editar Producto' : 'Nuevo Producto',
                      style: const TextStyle(
                          fontSize: PDAStyles.fontLarge, fontWeight: FontWeight.bold),
                    ),
                    if (_nombreCtrl.text.isNotEmpty)
                      Text(
                        _nombreCtrl.text,
                        style: const TextStyle(
                            fontSize: PDAStyles.fontExtraSmall, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                expandedHeight: 0,
              ),

              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Indicador de pasos ───────────────
                      _IndicadorPasos(
                        pasos:       _pasos,
                        iconos:      _iconosPasos,
                        pasoActual:  _pasoActual,
                        onTapPaso:   _irAPaso,
                      ),

                      // ── Contenido del paso ───────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_pasoActual),
                          child: _buildPasoActual(esSupervisor),
                        ),
                      ),

                      // ── Navegación entre pasos ───────────
                      _NavegacionPasos(
                        pasoActual:  _pasoActual,
                        totalPasos:  _pasos.length,
                        guardando:   _guardando,
                        esEdicion:   _esEdicion,
                        onAnterior:  _anterior,
                        onSiguiente: _siguiente,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Constructor de pasos ─────────────────────────────────
  Widget _buildPasoActual(bool esSupervisor) {
    switch (_pasoActual) {
      case 0:
        return _PasoIdentificacion(
          codigoCtrl:     _codigoCtrl,
          nombreCtrl:     _nombreCtrl,
          proveedorCtrl:  _proveedorCtrl,
          almacenajeCtrl: _almacenajeCtrl,
          ubicacionCtrl:  _ubicacionCtrl,
          unidadMedidaCtrl: _unidadMedidaCtrl,
          esEdicion:      _esEdicion,
          esSupervisor:   esSupervisor,
          onNombreChanged: (_) => setState(() {}),
        );
      case 1:
        return _PasoClasificacion(
          tipo:    _tipo,
          subtipo: _subtipo,
          onTipoChanged: (t) {
            setState(() {
              _tipo    = t;
              _subtipo = t.subtipos.first;
            });
          },
          onSubtipoChanged: (s) => setState(() => _subtipo = s),
        );
      case 2:
        return _PasoPrecios(
          precioCtrl:  _precioCtrl,
          promoCtrl:   _promoCtrl,
          inicioPromo: _inicioPromo,
          finPromo:    _finPromo,
          esSupervisor: esSupervisor,
          ahorro:              _ahorro,
          porcentajeDescuento: _porcentajeDescuento,
          tienePromocion:      _tienePromocion,
          onSeleccionarFecha:  _seleccionarFecha,
          onPrecioChanged:     (_) => setState(() {}),
          onPromoChanged:      (_) => setState(() {}),
        );
      case 3:
        return _PasoStock(
          stockCtrl:  _stockCtrl,
          stockMinimoCtrl: _stockMinimoCtrl,
          stockReal:  _stockReal,
          ventaHoy:   _esEdicion
              ? widget.productoExistente!.ventaHoy
              : 0,
          onStockChanged: (_) => setState(() {}),
          resumen: _ResumenFinal(
            codigo:    _codigoCtrl.text,
            nombre:    _nombreCtrl.text,
            tipo:      _tipo,
            subtipo:   _subtipo,
            precio:    _precioNormal,
            precioPromo: _precioPromo,
            stock:     _stockActual,
            stockReal: _stockReal,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ════════════════════════════════════════════════════════════
// INDICADOR DE PASOS
// ════════════════════════════════════════════════════════════
class _IndicadorPasos extends StatelessWidget {
  final List<String>   pasos;
  final List<IconData> iconos;
  final int            pasoActual;
  final void Function(int) onTapPaso;

  const _IndicadorPasos({
    required this.pasos,
    required this.iconos,
    required this.pasoActual,
    required this.onTapPaso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Línea de progreso
          Row(
            children: List.generate(pasos.length, (i) {
              final activo   = i == pasoActual;
              final completo = i < pasoActual;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTapPaso(i),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0)
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                height: 2,
                                color: completo
                                    ? AppColors.rojo
                                    : Colors.grey.shade200,
                              ),
                            ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: activo ? 36 : 28,
                            height: activo ? 36 : 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: completo
                                  ? AppColors.rojo
                                  : activo
                                  ? AppColors.rojo
                                  : Colors.grey.shade200,
                              boxShadow: activo
                                  ? [
                                BoxShadow(
                                  color:
                                  AppColors.rojo.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ]
                                  : null,
                            ),
                            child: Icon(
                              completo
                                  ? Icons.check_rounded
                                  : iconos[i],
                              size: activo ? 18 : 14,
                              color: (activo || completo)
                                  ? Colors.white
                                  : Colors.grey.shade400,
                            ),
                          ),
                          if (i < pasos.length - 1)
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                height: 2,
                                color: i < pasoActual
                                    ? AppColors.rojo
                                    : Colors.grey.shade200,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pasos[i],
                        style: TextStyle(
                          fontSize: PDAStyles.fontExtraSmall,
                          fontWeight: activo
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: activo
                              ? AppColors.rojo
                              : i < pasoActual
                              ? AppColors.grisOscuro
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PASO 0 — IDENTIFICACIÓN
// ════════════════════════════════════════════════════════════
class _PasoIdentificacion extends StatelessWidget {
  final TextEditingController codigoCtrl;
  final TextEditingController nombreCtrl;
  final TextEditingController proveedorCtrl;
  final TextEditingController almacenajeCtrl;
  final TextEditingController ubicacionCtrl;
  final TextEditingController unidadMedidaCtrl;
  final bool esEdicion;
  final bool esSupervisor;
  final void Function(String) onNombreChanged;

  const _PasoIdentificacion({
    required this.codigoCtrl,
    required this.nombreCtrl,
    required this.proveedorCtrl,
    required this.almacenajeCtrl,
    required this.ubicacionCtrl,
    required this.unidadMedidaCtrl,
    required this.esEdicion,
    required this.esSupervisor,
    required this.onNombreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _TarjetaPaso(
      titulo:   'Identificación del producto',
      subtitulo: 'Código, nombre y logística',
      icono:    Icons.qr_code_rounded,
      child: Column(
        children: [
          // Código (Escaneo o manual)
          _CampoTexto(
            controller:  codigoCtrl,
            label:       'Código de barras',
            icono:       Icons.qr_code_scanner_rounded,
            readOnly:    esEdicion,
            autoFocus:   !esEdicion,
            teclado:     TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText:  esEdicion 
                ? 'No modificable' 
                : 'Usa el lector PDA o ingresa manual',
            validator:   Validators.codigoBarras,
          ),
          const SizedBox(height: 14),

          // Nombre
          _CampoTexto(
            controller:  nombreCtrl,
            label:       'Nombre del producto',
            icono:       Icons.label_rounded,
            enabled:     esSupervisor,
            validator:   (v) => Validators.requerido(v, campo: 'El nombre'),
            onChanged:   onNombreChanged,
            capitalizacion: TextCapitalization.words,
          ),
          const SizedBox(height: 14),

          // Proveedor y Unidad de Medida
          Row(
            children: [
              Expanded(
                child: _CampoTexto(
                  controller: proveedorCtrl,
                  label:      'Proveedor',
                  icono:      Icons.business_rounded,
                  enabled:    esSupervisor,
                  validator:  (v) =>
                      Validators.requerido(v, campo: 'El proveedor'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CampoTexto(
                  controller: unidadMedidaCtrl,
                  label:      'U. Medida',
                  icono:      Icons.scale_rounded,
                  enabled:    esSupervisor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Almacenaje y Ubicación (Pasillo/Estante)
          Row(
            children: [
              Expanded(
                child: _CampoTexto(
                  controller: almacenajeCtrl,
                  label:      'Almacenaje',
                  icono:      Icons.warehouse_rounded,
                  enabled:    esSupervisor,
                  validator:  (v) =>
                      Validators.requerido(v, campo: 'El almacenaje'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CampoTexto(
                  controller: ubicacionCtrl,
                  label:      'Pasillo/Rack',
                  icono:      Icons.location_on_rounded,
                  enabled:    esSupervisor,
                  helperText: 'Ej: P1-B2',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PASO 1 — CLASIFICACIÓN
// ════════════════════════════════════════════════════════════
class _PasoClasificacion extends StatelessWidget {
  final ProductoTipo    tipo;
  final ProductoSubtipo subtipo;
  final void Function(ProductoTipo)    onTipoChanged;
  final void Function(ProductoSubtipo) onSubtipoChanged;

  const _PasoClasificacion({
    required this.tipo,
    required this.subtipo,
    required this.onTipoChanged,
    required this.onSubtipoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _TarjetaPaso(
      titulo:    'Clasificación',
      subtitulo: 'Categoriza el producto correctamente',
      icono:     Icons.category_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo principal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),

          // Selector de tipo — tarjetas grandes
          Row(
            children: ProductoTipo.values.map((t) {
              final seleccionado = tipo == t;
              final esComestible = t == ProductoTipo.comestible;
              final colorTipo = esComestible
                  ? Colors.green.shade700
                  : Colors.indigo.shade700;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTipoChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                        right: esComestible ? 10 : 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: seleccionado
                          ? colorTipo
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: seleccionado
                            ? colorTipo
                            : Colors.grey.shade200,
                        width: seleccionado ? 2 : 1,
                      ),
                      boxShadow: seleccionado
                          ? [
                        BoxShadow(
                          color: colorTipo.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? Colors.white.withValues(alpha: 0.2)
                                : colorTipo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            esComestible
                                ? Icons.restaurant_rounded
                                : Icons.shopping_bag_rounded,
                            size: 28,
                            color: seleccionado
                                ? Colors.white
                                : colorTipo,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.etiqueta,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: seleccionado
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.subtipos.length} subtipos',
                          style: TextStyle(
                            fontSize: 11,
                            color: seleccionado
                                ? Colors.white70
                                : AppColors.grisMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          const Text(
            'Subtipo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),

          // Grid de subtipos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:  3,
              crossAxisSpacing: 8,
              mainAxisSpacing:  8,
              childAspectRatio: 2.4,
            ),
            itemCount: tipo.subtipos.length,
            itemBuilder: (_, i) {
              final s         = tipo.subtipos[i];
              final seleccionado = subtipo == s;
              final colorTipo = tipo == ProductoTipo.comestible
                  ? Colors.green.shade700
                  : Colors.indigo.shade700;

              return GestureDetector(
                onTap: () => onSubtipoChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? colorTipo.withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: seleccionado
                          ? colorTipo
                          : Colors.grey.shade200,
                      width: seleccionado ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      s.etiqueta,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: seleccionado
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: seleccionado
                            ? colorTipo
                            : AppColors.grisOscuro,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PASO 2 — PRECIOS
// ════════════════════════════════════════════════════════════
class _PasoPrecios extends StatelessWidget {
  final TextEditingController precioCtrl;
  final TextEditingController promoCtrl;
  final DateTime? inicioPromo;
  final DateTime? finPromo;
  final bool   esSupervisor;
  final double ahorro;
  final double porcentajeDescuento;
  final bool   tienePromocion;
  final void Function(bool) onSeleccionarFecha;
  final void Function(String) onPrecioChanged;
  final void Function(String) onPromoChanged;

  const _PasoPrecios({
    required this.precioCtrl,
    required this.promoCtrl,
    required this.inicioPromo,
    required this.finPromo,
    required this.esSupervisor,
    required this.ahorro,
    required this.porcentajeDescuento,
    required this.tienePromocion,
    required this.onSeleccionarFecha,
    required this.onPrecioChanged,
    required this.onPromoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _TarjetaPaso(
      titulo:    'Precios',
      subtitulo: 'Precio normal y promoción',
      icono:     Icons.attach_money_rounded,
      child: Column(
        children: [
          // Precio normal
          _CampoTexto(
            controller:   precioCtrl,
            label:        'Precio normal (S/)',
            icono:        Icons.payments_rounded,
            teclado:      const TextInputType.numberWithOptions(decimal: true),
            enabled:      esSupervisor,
            validator:    (v) => Validators.numero(v, campo: 'El precio'),
            onChanged:    onPrecioChanged,
            prefijo:      'S/',
          ),

          const SizedBox(height: 20),

          // Separador promoción
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.local_offer_rounded,
                        size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    const Text(
                      'Promoción (opcional)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF57C00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade200)),
            ],
          ),
          const SizedBox(height: 16),

          // Precio promocional
          _CampoTexto(
            controller:  promoCtrl,
            label:       'Precio promocional (S/)',
            icono:       Icons.local_offer_rounded,
            teclado:     const TextInputType.numberWithOptions(decimal: true),
            enabled:     esSupervisor,
            onChanged:   onPromoChanged,
            prefijo:     'S/',
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final precio =
                  double.tryParse(precioCtrl.text.replaceAll(',', '.')) ?? 0;
              return Validators.precioPromocion(v, precio);
            },
          ),

          // Preview descuento
          if (tienePromocion && ahorro > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade50,
                    Colors.orange.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.trending_down_rounded,
                        color: Colors.orange.shade800, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ahorro para el cliente',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        Text(
                          'S/ ${ahorro.toStringAsFixed(2)}  •  ${porcentajeDescuento.toStringAsFixed(0)}% de descuento',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Fechas de promo
          if (tienePromocion) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SelectorFecha(
                    label: 'Inicio',
                    fecha: inicioPromo,
                    icono: Icons.calendar_today_rounded,
                    onTap: () => onSeleccionarFecha(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SelectorFecha(
                    label: 'Fin',
                    fecha: finPromo,
                    icono: Icons.event_rounded,
                    onTap: () => onSeleccionarFecha(false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PASO 3 — STOCK
// ════════════════════════════════════════════════════════════
class _PasoStock extends StatelessWidget {
  final TextEditingController stockCtrl;
  final TextEditingController stockMinimoCtrl;
  final int stockReal;
  final int ventaHoy;
  final void Function(String) onStockChanged;
  final _ResumenFinal resumen;

  const _PasoStock({
    required this.stockCtrl,
    required this.stockMinimoCtrl,
    required this.stockReal,
    required this.ventaHoy,
    required this.onStockChanged,
    required this.resumen,
  });

  @override
  Widget build(BuildContext context) {
    final stock = int.tryParse(stockCtrl.text) ?? 0;
    final stockMin = int.tryParse(stockMinimoCtrl.text) ?? 0;
    final colorStock = stockReal <= stockMin
        ? AppColors.rojoStock
        : stockReal <= (stockMin * 1.5)
        ? AppColors.amarilloAlerta
        : AppColors.verdeStock;

    return Column(
      children: [
        _TarjetaPaso(
          titulo:    'Control de Inventario',
          subtitulo: 'Stock y alertas de reposición',
          icono:     Icons.inventory_2_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CampoTexto(
                      controller: stockCtrl,
                      label:      'Stock Actual',
                      icono:      Icons.inventory_2_rounded,
                      teclado:    TextInputType.number,
                      validator:  (v) =>
                          Validators.enteroPositivo(v, campo: 'El stock'),
                      onChanged:  onStockChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CampoTexto(
                      controller: stockMinimoCtrl,
                      label:      'Stock Mínimo',
                      icono:      Icons.notifications_active_rounded,
                      teclado:    TextInputType.number,
                      helperText: 'Alerta de reposición',
                      validator:  (v) =>
                          Validators.enteroPositivo(v, campo: 'El stock mínimo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Indicadores de stock
              Row(
                children: [
                  Expanded(
                    child: _IndicadorStock(
                      label: 'Stock ingresado',
                      valor: '$stock',
                      color: AppColors.rojo,
                      icono: Icons.add_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _IndicadorStock(
                      label: 'Venta de hoy',
                      valor: '$ventaHoy',
                      color: AppColors.grisMedio,
                      icono: Icons.point_of_sale_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _IndicadorStock(
                      label: 'Stock real',
                      valor: '$stockReal',
                      color: colorStock,
                      icono: Icons.calculate_rounded,
                      destacado: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Barra visual de stock
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: stock > 0 ? (stockReal / stock).clamp(0.0, 1.0) : 0,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(colorStock),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.grisMedio)),
                  Text(
                    '$stock unidades máx.',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.grisMedio),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Resumen final
        resumen,
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// RESUMEN FINAL (paso 3)
// ════════════════════════════════════════════════════════════
class _ResumenFinal extends StatelessWidget {
  final String          codigo;
  final String          nombre;
  final ProductoTipo    tipo;
  final ProductoSubtipo subtipo;
  final double          precio;
  final double?         precioPromo;
  final int             stock;
  final int             stockReal;

  const _ResumenFinal({
    required this.codigo,
    required this.nombre,
    required this.tipo,
    required this.subtipo,
    required this.precio,
    required this.precioPromo,
    required this.stock,
    required this.stockReal,
  });

  @override
  Widget build(BuildContext context) {
    if (nombre.isEmpty && codigo.isEmpty) return const SizedBox.shrink();

    final colorTipo = tipo == ProductoTipo.comestible
        ? Colors.green.shade700
        : Colors.indigo.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF2D2D4E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Vista previa del producto',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              nombre.isNotEmpty ? nombre : 'Nombre del producto',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              codigo.isNotEmpty ? 'Código: $codigo' : '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _PillResumen(
                    texto: tipo.etiqueta, color: colorTipo),
                _PillResumen(
                    texto: subtipo.etiqueta,
                    color: colorTipo.withValues(alpha: 0.7)),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _DatoResumen(
                    label: 'Precio',
                    valor: precio > 0
                        ? 'S/ ${precio.toStringAsFixed(2)}'
                        : '-',
                    icono: Icons.attach_money_rounded,
                  ),
                ),
                if (precioPromo != null)
                  Expanded(
                    child: _DatoResumen(
                      label: 'Promo',
                      valor: 'S/ ${precioPromo!.toStringAsFixed(2)}',
                      icono: Icons.local_offer_rounded,
                      color: Colors.amber,
                    ),
                  ),
                Expanded(
                  child: _DatoResumen(
                    label: 'Stock real',
                    valor: '$stockReal',
                    icono: Icons.inventory_2_rounded,
                    color: stockReal <= 5
                        ? Colors.red.shade300
                        : Colors.green.shade300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillResumen extends StatelessWidget {
  final String texto;
  final Color  color;
  const _PillResumen({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
            color: color == Colors.green.shade700
                ? Colors.green.shade300
                : Colors.indigo.shade200,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DatoResumen extends StatelessWidget {
  final String  label;
  final String  valor;
  final IconData icono;
  final Color   color;

  const _DatoResumen({
    required this.label,
    required this.valor,
    required this.icono,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 12, color: Colors.white38),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// NAVEGACIÓN ENTRE PASOS
// ════════════════════════════════════════════════════════════
class _NavegacionPasos extends StatelessWidget {
  final int  pasoActual;
  final int  totalPasos;
  final bool guardando;
  final bool esEdicion;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  const _NavegacionPasos({
    required this.pasoActual,
    required this.totalPasos,
    required this.guardando,
    required this.esEdicion,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    final esUltimoPaso = pasoActual == totalPasos - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Botón Anterior
          if (pasoActual > 0) ...[
            OutlinedButton.icon(
              onPressed: onAnterior,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
              label: const Text('Anterior'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.grisOscuro,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Botón Siguiente / Guardar
          Expanded(
            child: ElevatedButton.icon(
              onPressed: guardando ? null : onSiguiente,
              icon: guardando
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : Icon(
                esUltimoPaso
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                guardando
                    ? 'Guardando...'
                    : esUltimoPaso
                    ? (esEdicion
                    ? 'Actualizar producto'
                    : 'Guardar producto')
                    : 'Siguiente',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: esUltimoPaso
                    ? AppColors.verdeStock
                    : AppColors.rojo,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// WIDGETS REUTILIZABLES
// ════════════════════════════════════════════════════════════

class _TarjetaPaso extends StatelessWidget {
  final String  titulo;
  final String  subtitulo;
  final IconData icono;
  final Widget  child;

  const _TarjetaPaso({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la tarjeta
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                color: AppColors.rojo.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.rojo.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.rojo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icono, color: AppColors.rojo, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: PDAStyles.fontMedium,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                            fontSize: PDAStyles.fontExtraSmall, color: AppColors.grisMedio),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController  controller;
  final String                 label;
  final IconData               icono;
  final String? Function(String?)? validator;
  final TextInputType?          teclado;
  final List<TextInputFormatter>? inputFormatters;
  final bool                   readOnly;
  final bool                   enabled;
  final String?                helperText;
  final String?                prefijo;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextCapitalization     capitalizacion;
  final bool                   autoFocus;

  const _CampoTexto({
    required this.controller,
    required this.label,
    required this.icono,
    this.validator,
    this.teclado,
    this.inputFormatters,
    this.readOnly   = false,
    this.enabled    = true,
    this.helperText,
    this.prefijo,
    this.onChanged,
    this.onSubmitted,
    this.capitalizacion = TextCapitalization.none,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:          controller,
      validator:           validator,
      keyboardType:        teclado,
      inputFormatters:     inputFormatters,
      readOnly:            readOnly,
      enabled:             enabled,
      onChanged:           onChanged,
      onFieldSubmitted:    onSubmitted,
      autofocus:           autoFocus,
      textCapitalization:  capitalizacion,
      style: const TextStyle(
          fontSize: PDAStyles.fontMedium, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText:  label,
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: PDAStyles.fontExtraSmall),
        prefixIcon:  Icon(icono, size: 24, color: AppColors.grisMedio),
        prefixText:  prefijo != null ? '$prefijo ' : null,
        prefixStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: AppColors.rojo),
        filled:      !enabled || readOnly,
        fillColor:   (!enabled || readOnly)
            ? const Color(0xFFF5F5F5)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: AppColors.rojo, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.rojoStock),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 18),
      ),
    );
  }
}

class _SelectorFecha extends StatelessWidget {
  final String    label;
  final DateTime? fecha;
  final IconData  icono;
  final VoidCallback onTap;

  const _SelectorFecha({
    required this.label,
    required this.fecha,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(
            color: fecha != null
                ? AppColors.rojo.withValues(alpha: 0.5)
                : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(12),
          color: fecha != null
              ? AppColors.rojo.withValues(alpha: 0.04)
              : null,
        ),
        child: Row(
          children: [
            Icon(icono,
                size: 18,
                color: fecha != null
                    ? AppColors.rojo
                    : AppColors.grisMedio),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.grisMedio)),
                  const SizedBox(height: 2),
                  Text(
                    fecha != null
                        ? DateHelper.formatear(fecha!)
                        : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fecha != null
                          ? const Color(0xFF1A1A2E)
                          : AppColors.grisMedio,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16,
                color: fecha != null
                    ? AppColors.rojo
                    : Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

class _IndicadorStock extends StatelessWidget {
  final String  label;
  final String  valor;
  final Color   color;
  final IconData icono;
  final bool    destacado;

  const _IndicadorStock({
    required this.label,
    required this.valor,
    required this.color,
    required this.icono,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: destacado
            ? color.withValues(alpha: 0.1)
            : const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: destacado
              ? color.withValues(alpha: 0.3)
              : Colors.grey.shade100,
          width: destacado ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 9, color: AppColors.grisMedio),
          ),
        ],
      ),
    );
  }
}