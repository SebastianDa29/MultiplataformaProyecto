enum UserRole {
  supervisor,
  inventarista,
}

extension UserRoleExtension on UserRole {
  String get nombre {
    switch (this) {
      case UserRole.supervisor:   return 'Supervisor';
      case UserRole.inventarista: return 'Inventarista';
    }
  }

  bool get esSupervisor => this == UserRole.supervisor;

  /// Devuelve true si este rol puede ejecutar la acción solicitada
  bool puedeEjecutar(Permiso permiso) {
    switch (this) {
      case UserRole.supervisor:
        return true; // acceso total
      case UserRole.inventarista:
        return _permisosInventarista.contains(permiso);
    }
  }

  static const List<Permiso> _permisosInventarista = [
    Permiso.verDashboard,
    Permiso.verProductos,
    Permiso.modificarStock,
    Permiso.registrarMerma,
    Permiso.verHistorial,
  ];
}

enum Permiso {
  verDashboard,
  verProductos,
  agregarProducto,
  editarProducto,
  eliminarProducto,
  modificarStock,
  editarPrecio,
  registrarMerma,
  verMermas,
  verHistorial,
  verReportes,
  exportarDatos,
  configuracion,
}