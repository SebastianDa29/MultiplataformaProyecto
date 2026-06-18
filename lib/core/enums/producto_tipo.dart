enum ProductoTipo {
  comestible,
  noComestible,
}

extension ProductoTipoExt on ProductoTipo {
  String get etiqueta {
    switch (this) {
      case ProductoTipo.comestible:    return 'Comestible';
      case ProductoTipo.noComestible:  return 'No Comestible';
    }
  }

  String get valor {
    switch (this) {
      case ProductoTipo.comestible:    return 'comestible';
      case ProductoTipo.noComestible:  return 'no_comestible';
    }
  }

  /// Subtipos disponibles según el tipo principal
  List<ProductoSubtipo> get subtipos {
    switch (this) {
      case ProductoTipo.comestible:
        return [
          ProductoSubtipo.comidasInstantaneas,
          ProductoSubtipo.snacks,
          ProductoSubtipo.bebidas,
          ProductoSubtipo.lacteos,
          ProductoSubtipo.conservas,
          ProductoSubtipo.condimentos,
          ProductoSubtipo.dulces,
          ProductoSubtipo.panaderia,
        ];
      case ProductoTipo.noComestible:
        return [
          ProductoSubtipo.desodorantes,
          ProductoSubtipo.limpiezaHogar,
          ProductoSubtipo.higieneBucal,
          ProductoSubtipo.cosmeticos,
          ProductoSubtipo.papeleria,
          ProductoSubtipo.plasticos,
          ProductoSubtipo.juguetes,
          ProductoSubtipo.electrodomesticos,
        ];
    }
  }

  static ProductoTipo fromValor(String? valor) {
    return ProductoTipo.values.firstWhere(
          (e) => e.valor == valor,
      orElse: () => ProductoTipo.comestible,
    );
  }
}

enum ProductoSubtipo {
  // Comestibles
  comidasInstantaneas,
  snacks,
  bebidas,
  lacteos,
  conservas,
  condimentos,
  dulces,
  panaderia,
  // No comestibles
  desodorantes,
  limpiezaHogar,
  higieneBucal,
  cosmeticos,
  papeleria,
  plasticos,
  juguetes,
  electrodomesticos,
}

extension ProductoSubtipoExt on ProductoSubtipo {
  String get etiqueta {
    switch (this) {
      case ProductoSubtipo.comidasInstantaneas: return 'Comidas Instantáneas';
      case ProductoSubtipo.snacks:              return 'Snacks';
      case ProductoSubtipo.bebidas:             return 'Bebidas';
      case ProductoSubtipo.lacteos:             return 'Lácteos';
      case ProductoSubtipo.conservas:           return 'Conservas';
      case ProductoSubtipo.condimentos:         return 'Condimentos';
      case ProductoSubtipo.dulces:              return 'Dulces y Golosinas';
      case ProductoSubtipo.panaderia:           return 'Panadería';
      case ProductoSubtipo.desodorantes:        return 'Desodorantes';
      case ProductoSubtipo.limpiezaHogar:       return 'Limpieza del Hogar';
      case ProductoSubtipo.higieneBucal:        return 'Higiene Bucal';
      case ProductoSubtipo.cosmeticos:          return 'Cosméticos';
      case ProductoSubtipo.papeleria:           return 'Papelería';
      case ProductoSubtipo.plasticos:           return 'Plásticos y Utensilios';
      case ProductoSubtipo.juguetes:            return 'Juguetes';
      case ProductoSubtipo.electrodomesticos:   return 'Electrodomésticos';
    }
  }

  String get valor {
    switch (this) {
      case ProductoSubtipo.comidasInstantaneas: return 'comidas_instantaneas';
      case ProductoSubtipo.snacks:              return 'snacks';
      case ProductoSubtipo.bebidas:             return 'bebidas';
      case ProductoSubtipo.lacteos:             return 'lacteos';
      case ProductoSubtipo.conservas:           return 'conservas';
      case ProductoSubtipo.condimentos:         return 'condimentos';
      case ProductoSubtipo.dulces:              return 'dulces';
      case ProductoSubtipo.panaderia:           return 'panaderia';
      case ProductoSubtipo.desodorantes:        return 'desodorantes';
      case ProductoSubtipo.limpiezaHogar:       return 'limpieza_hogar';
      case ProductoSubtipo.higieneBucal:        return 'higiene_bucal';
      case ProductoSubtipo.cosmeticos:          return 'cosmeticos';
      case ProductoSubtipo.papeleria:           return 'papeleria';
      case ProductoSubtipo.plasticos:           return 'plasticos';
      case ProductoSubtipo.juguetes:            return 'juguetes';
      case ProductoSubtipo.electrodomesticos:   return 'electrodomesticos';
    }
  }

  static ProductoSubtipo fromValor(String? valor) {
    return ProductoSubtipo.values.firstWhere(
          (e) => e.valor == valor,
      orElse: () => ProductoSubtipo.snacks,
    );
  }
}