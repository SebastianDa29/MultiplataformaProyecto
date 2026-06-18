enum TipoMovimiento {
  entrada,
  salida,
  ajuste,
  merma,
  inicial,
}

extension TipoMovimientoExtension on TipoMovimiento {
  String get etiqueta {
    switch (this) {
      case TipoMovimiento.entrada: return 'Entrada';
      case TipoMovimiento.salida:  return 'Salida';
      case TipoMovimiento.ajuste:  return 'Ajuste';
      case TipoMovimiento.merma:   return 'Merma';
      case TipoMovimiento.inicial: return 'Carga Inicial';
    }
  }

  String get valor {
    return name;
  }

  static TipoMovimiento fromValor(String valor) {
    return TipoMovimiento.values.firstWhere(
      (e) => e.name == valor,
      orElse: () => TipoMovimiento.ajuste,
    );
  }
}
