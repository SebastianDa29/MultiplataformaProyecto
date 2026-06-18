import 'package:go_router/go_router.dart';

import '../presentation/screens/login/login_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/productos/lista_productos_screen.dart';
import '../presentation/screens/productos/agregar_producto_screen.dart';
import '../presentation/screens/merma/merma_screen.dart';
import '../presentation/screens/reportes/reportes_screen.dart';
import '../presentation/screens/reportes/kardex_screen.dart';
import '../presentation/screens/productos/inventario_conteo_screen.dart';
import '../data/models/producto_model.dart';

class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String productos = '/productos';
  static const String agregar = '/productos/agregar';
  static const String mermas = '/mermas';
  static const String reportes = '/reportes';
  static const String kardex = '/kardex';
  static const String inventarioConteo = '/inventario-conteo';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: productos,
        builder: (context, state) => const ListaProductosScreen(),
      ),
      GoRoute(
        path: agregar,
        builder: (context, state) => AgregarProductoScreen(
          productoExistente: state.extra as ProductoModel?,
        ),
      ),
      GoRoute(
        path: mermas,
        builder: (context, state) => const MermaScreen(),
      ),
      GoRoute(
        path: reportes,
        builder: (context, state) => const ReportesScreen(),
      ),
      GoRoute(
        path: kardex,
        builder: (context, state) => const KardexScreen(),
      ),
      GoRoute(
        path: inventarioConteo,
        builder: (context, state) => const InventarioConteoScreen(),
      ),
    ],
  );
}