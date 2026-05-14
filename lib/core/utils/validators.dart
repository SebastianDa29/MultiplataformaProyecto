class Validators {
  static String? requerido(String? value, {String campo = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$campo es obligatorio';
    }
    return null;
  }

  static String? numero(String? value, {String campo = 'El valor'}) {
    if (value == null || value.trim().isEmpty) return '$campo es obligatorio';
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return '$campo debe ser un número válido';
    if (parsed < 0) return '$campo no puede ser negativo';
    return null;
  }

  static String? enteroPositivo(String? value, {String campo = 'El valor'}) {
    if (value == null || value.trim().isEmpty) return '$campo es obligatorio';
    final parsed = int.tryParse(value);
    if (parsed == null) return '$campo debe ser un número entero';
    if (parsed < 0) return '$campo no puede ser negativo';
    return null;
  }

  static String? precioPromocion(String? promo, double precioNormal) {
    if (promo == null || promo.trim().isEmpty) return null;
    final parsed = double.tryParse(promo.replaceAll(',', '.'));
    if (parsed == null) return 'Ingresa un precio válido';
    if (parsed >= precioNormal) return 'El precio promocional debe ser menor al normal';
    if (parsed <= 0) return 'El precio debe ser mayor a 0';
    return null;
  }

  static String? fechaFin(DateTime? inicio, DateTime? fin) {
    if (inicio == null || fin == null) return null;
    if (fin.isBefore(inicio)) return 'La fecha fin debe ser posterior al inicio';
    return null;
  }

  static String? codigoBarras(String? value) {
    if (value == null || value.trim().isEmpty) return 'El código es obligatorio';
    if (value.length < 4) return 'Código demasiado corto';
    return null;
  }
}