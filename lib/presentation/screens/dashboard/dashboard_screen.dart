import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../../router/app_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navegar(BuildContext context, String ruta, Permiso permiso) {

    debugPrint('NAVEGANDO A: $ruta');

    if (context.mounted) {
      context.push(ruta);
    }
  }

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _fechaFormateada() {
    final now = DateTime.now();
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    const meses = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;

    final demoProductos = <_DemoProducto>[
      const _DemoProducto(nombre: 'Arroz Superior', stockReal: 4, stock: 20),
      const _DemoProducto(nombre: 'Aceite Vegetal', stockReal: 2, stock: 15),
      const _DemoProducto(nombre: 'Azúcar Blanca', stockReal: 1, stock: 12),
      const _DemoProducto(nombre: 'Fideos Spaghetti', stockReal: 8, stock: 18),
      const _DemoProducto(nombre: 'Leche Evaporada', stockReal: 6, stock: 10),
    ];

    final demoMermas = <_DemoMerma>[
      _DemoMerma(
        nombreProducto: 'Leche Evaporada',
        tipo: const _DemoTipoMerma('Vencimiento'),
        registradoPor: 'Sistema',
        cantidad: 2,
        fecha: DateTime.now(),
      ),
      _DemoMerma(
        nombreProducto: 'Azúcar Blanca',
        tipo: const _DemoTipoMerma('Daño'),
        registradoPor: 'Sistema',
        cantidad: 1,
        fecha: DateTime.now(),
      ),
      _DemoMerma(
        nombreProducto: 'Aceite Vegetal',
        tipo: const _DemoTipoMerma('Merma parcial'),
        registradoPor: 'Sistema',
        cantidad: 3,
        fecha: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    final totalProductos = demoProductos.length;
    final stockBajo = demoProductos.where((p) => p.stockReal <= 5).length;
    final conPromocion = 2;
    final totalMermasHoy = demoMermas
        .where((m) => _esHoy(m.fecha))
        .fold<int>(0, (sum, m) => sum + m.cantidad);

    final productosStockBajo =
    demoProductos.where((p) => p.stockReal <= 5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.rojo,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroHeader(
                    saludo: _saludo(),
                    nombre: usuario?.nombre ?? 'Usuario',
                    rol: usuario?.rol.nombre ?? 'Invitado',
                    fecha: _fechaFormateada(),
                  ),
                ),
                title: Text(
                  AppStrings.appNombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: AppStrings.cerrarSesion,
                    onPressed: () => _confirmarLogout(context, auth),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stockBajo > 0) ...[
                        _AlertaStrip(
                          mensaje: '⚠  $stockBajo producto(s) con stock bajo',
                          color: const Color(0xFFFFF3CD),
                          borderColor: const Color(0xFFFFCC02),
                          textColor: const Color(0xFF7A5900),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _LabelSeccion(texto: 'Resumen'),
                      const SizedBox(height: 10),
                      _MetricasGrid(
                        totalProductos: totalProductos,
                        stockBajo: stockBajo,
                        conPromocion: conPromocion,
                        totalMermasHoy: totalMermasHoy,
                      ),
                      const SizedBox(height: 28),
                      _LabelSeccion(texto: 'Módulos'),
                      const SizedBox(height: 10),
                      _ModulosGrid(
                        onNavegar: (ruta, permiso) =>
                            _navegar(context, ruta, permiso),
                      ),
                      const SizedBox(height: 28),
                      if (demoMermas.isNotEmpty) ...[
                        _LabelSeccion(texto: 'Últimas Mermas'),
                        const SizedBox(height: 10),
                        _UltimasMermas(mermas: demoMermas.take(4).toList()),
                      ],
                      const SizedBox(height: 28),
                      if (productosStockBajo.isNotEmpty) ...[
                        _LabelSeccion(texto: 'Stock Crítico'),
                        const SizedBox(height: 10),
                        _StockCriticoList(
                          productos: productosStockBajo.take(3).toList(),
                        ),
                      ],
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

  bool _esHoy(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }

  void _confirmarLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir del sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rojo),
            child: const Text(
              'Salir',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String saludo;
  final String nombre;
  final String rol;
  final String fecha;

  const _HeroHeader({
    required this.saludo,
    required this.nombre,
    required this.rol,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC8102E), Color(0xFF8B0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: _CirculoDecorativo(size: 160, opacity: 0.08),
          ),
          Positioned(
            bottom: -10,
            right: 60,
            child: _CirculoDecorativo(size: 90, opacity: 0.06),
          ),
          Positioned(
            top: 40,
            right: 110,
            child: _CirculoDecorativo(size: 50, opacity: 0.07),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    saludo,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PillBadge(texto: rol, color: AppColors.amarillo),
                      const SizedBox(width: 8),
                      _PillBadge(
                        texto: fecha,
                        color: Colors.white.withOpacity(0.2),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CirculoDecorativo extends StatelessWidget {
  final double size;
  final double opacity;
  const _CirculoDecorativo({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String texto;
  final Color color;
  final Color textColor;

  const _PillBadge({
    required this.texto,
    required this.color,
    this.textColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _LabelSeccion extends StatelessWidget {
  final String texto;
  const _LabelSeccion({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          texto,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _AlertaStrip extends StatelessWidget {
  final String mensaje;
  final Color color;
  final Color borderColor;
  final Color textColor;

  const _AlertaStrip({
    required this.mensaje,
    required this.color,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Text(
        mensaje,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MetricasGrid extends StatelessWidget {
  final int totalProductos;
  final int stockBajo;
  final int conPromocion;
  final int totalMermasHoy;

  const _MetricasGrid({
    required this.totalProductos,
    required this.stockBajo,
    required this.conPromocion,
    required this.totalMermasHoy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                titulo: 'Productos',
                valor: '$totalProductos',
                icono: Icons.inventory_2_rounded,
                gradientColors: [AppColors.rojo, const Color(0xFFE53935)],
                subtitulo: 'en inventario',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                titulo: 'Stock Bajo',
                valor: '$stockBajo',
                icono: Icons.trending_down_rounded,
                gradientColors: stockBajo > 0
                    ? [const Color(0xFFF57C00), const Color(0xFFFF9800)]
                    : [const Color(0xFF2E7D32), const Color(0xFF43A047)],
                subtitulo: stockBajo > 0 ? 'requieren atención' : 'todo en orden',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                titulo: 'Promociones',
                valor: '$conPromocion',
                icono: Icons.local_offer_rounded,
                gradientColors: [const Color(0xFFE6A800), AppColors.amarillo],
                subtitulo: 'activas hoy',
                textoDark: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                titulo: 'Mermas Hoy',
                valor: '$totalMermasHoy',
                icono: Icons.remove_circle_rounded,
                gradientColors: totalMermasHoy > 0
                    ? [const Color(0xFF880E4F), const Color(0xFFC2185B)]
                    : [const Color(0xFF37474F), const Color(0xFF546E7A)],
                subtitulo: 'unidades perdidas',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final List<Color> gradientColors;
  final String subtitulo;
  final bool textoDark;

  const _MetricCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.gradientColors,
    required this.subtitulo,
    this.textoDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = textoDark ? Colors.black87 : Colors.white;
    final subColor = textoDark ? Colors.black54 : Colors.white.withOpacity(0.8);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: subColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icono, color: textColor.withOpacity(0.9), size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: TextStyle(
              color: subColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulosGrid extends StatelessWidget {
  final void Function(String ruta, Permiso permiso) onNavegar;

  const _ModulosGrid({required this.onNavegar});

  @override
  Widget build(BuildContext context) {
    final modulos = [
      _ModuloData(
        titulo: 'Inventario',
        subtitulo: 'Lista de productos',
        icono: Icons.inventory_2_outlined,
        color: AppColors.rojo,
        ruta: AppRouter.productos,
        permiso: Permiso.verProductos,
      ),
      _ModuloData(
        titulo: 'Agregar',
        subtitulo: 'Nuevo producto',
        icono: Icons.add_circle_outline_rounded,
        color: const Color(0xFF1565C0),
        ruta: AppRouter.agregar,
        permiso: Permiso.agregarProducto,
      ),
      _ModuloData(
        titulo: 'Mermas',
        subtitulo: 'Registrar pérdida',
        icono: Icons.delete_sweep_outlined,
        color: const Color(0xFF6A1B9A),
        ruta: AppRouter.mermas,
        permiso: Permiso.registrarMerma,
      ),
      _ModuloData(
        titulo: 'Reportes',
        subtitulo: 'Solo supervisor',
        icono: Icons.bar_chart_rounded,
        color: const Color(0xFF00695C),
        ruta: AppRouter.reportes,
        permiso: Permiso.verReportes,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: modulos.length,
      itemBuilder: (context, i) {
        final m = modulos[i];
        return _ModuloCard(
          data: m,
          tieneAcceso: true,
          onTap: () => onNavegar(m.ruta, m.permiso),
        );
      },
    );
  }
}

class _ModuloData {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final String ruta;
  final Permiso permiso;

  const _ModuloData({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.ruta,
    required this.permiso,
  });
}

class _ModuloCard extends StatefulWidget {
  final _ModuloData data;
  final bool tieneAcceso;
  final VoidCallback onTap;

  const _ModuloCard({
    required this.data,
    required this.tieneAcceso,
    required this.onTap,
  });

  @override
  State<_ModuloCard> createState() => _ModuloCardState();
}

class _ModuloCardState extends State<_ModuloCard> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.data.color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _presionado = true),
      onTapUp: (_) {
        setState(() => _presionado = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _presionado = false),
      child: AnimatedScale(
        scale: _presionado ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.data.icono, color: color, size: 20),
                  ),
                  if (!widget.tieneAcceso)
                    Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.data.subtitulo,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UltimasMermas extends StatelessWidget {
  final List<_DemoMerma> mermas;
  const _UltimasMermas({required this.mermas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: mermas.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final esUltimo = i == mermas.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: !esUltimo
                  ? Border(
                bottom: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.rojoStock.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.rojoStock,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.nombreProducto,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1A1A2E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${m.tipo.etiqueta} · ${m.registradoPor}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.rojoStock.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '-${m.cantidad}',
                    style: const TextStyle(
                      color: AppColors.rojoStock,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StockCriticoList extends StatelessWidget {
  final List<_DemoProducto> productos;
  const _StockCriticoList({required this.productos});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: productos.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final esUltimo = i == productos.length - 1;
          final porcentaje = p.stock > 0
              ? (p.stockReal / p.stock).clamp(0.0, 1.0)
              : 0.0;

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              border: !esUltimo
                  ? Border(
                bottom: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1A1A2E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${p.stockReal} / ${p.stock}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.rojoStock,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: porcentaje,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      porcentaje < 0.2
                          ? AppColors.rojoStock
                          : AppColors.amarilloAlerta,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DemoTipoMerma {
  final String etiqueta;
  const _DemoTipoMerma(this.etiqueta);
}

class _DemoMerma {
  final String nombreProducto;
  final _DemoTipoMerma tipo;
  final String registradoPor;
  final int cantidad;
  final DateTime fecha;

  _DemoMerma({
    required this.nombreProducto,
    required this.tipo,
    required this.registradoPor,
    required this.cantidad,
    required this.fecha,
  });
}

class _DemoProducto {
  final String nombre;
  final int stockReal;
  final int stock;

  const _DemoProducto({
    required this.nombre,
    required this.stockReal,
    required this.stock,
  });
}