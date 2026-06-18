enum MermaTipo {
  vencimiento,      // 03
  rotura,           // 04
  robo,             // 05
  cd,               // 06
  calidad,          // 07
  destruccion,      // 17
  administrativa,   // 18
  bapRotura,        // 19
  bapVencimiento,   // 20
}

extension MermaTipoExtension on MermaTipo {
  String get etiqueta {
    switch (this) {
      case MermaTipo.vencimiento:    return '03 - Vencimiento';
      case MermaTipo.rotura:         return '04 - Rotura';
      case MermaTipo.robo:           return '05 - Robo';
      case MermaTipo.cd:             return '06 - CD';
      case MermaTipo.calidad:        return '07 - Calidad';
      case MermaTipo.destruccion:    return '17 - Destrucción';
      case MermaTipo.administrativa: return '18 - Administrativa';
      case MermaTipo.bapRotura:      return '19 - BAP Rotura';
      case MermaTipo.bapVencimiento: return '20 - BAP Vencimiento';
    }
  }

  String get valor {
    switch (this) {
      case MermaTipo.vencimiento:    return 'vencimiento';
      case MermaTipo.rotura:         return 'rotura';
      case MermaTipo.robo:           return 'robo';
      case MermaTipo.cd:             return 'cd';
      case MermaTipo.calidad:        return 'calidad';
      case MermaTipo.destruccion:    return 'destruccion';
      case MermaTipo.administrativa: return 'administrativa';
      case MermaTipo.bapRotura:      return 'bap_rotura';
      case MermaTipo.bapVencimiento: return 'bap_vencimiento';
    }
  }

  static MermaTipo fromValor(String valor) {
    return MermaTipo.values.firstWhere(
      (e) => e.valor == valor,
      orElse: () => MermaTipo.rotura,
    );
  }
}
