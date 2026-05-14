class StockCalculator {
  /// Stock real = stock actual - venta de hoy
  static int calcularStockReal(int stock, int ventaHoy) {
    final resultado = stock - ventaHoy;
    return resultado < 0 ? 0 : resultado;
  }

  /// Devuelve true si el stock real está por debajo del mínimo configurado
  static bool esBajo(int stockReal, {int minimo = 5}) {
    return stockReal <= minimo;
  }

  /// Devuelve el nivel de alerta: 0=normal, 1=bajo, 2=crítico
  static int nivelAlerta(int stockReal, {int minimo = 5}) {
    if (stockReal == 0) return 2;
    if (stockReal <= minimo) return 1;
    return 0;
  }
}