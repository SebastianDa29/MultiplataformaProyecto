enum MermaTipo {
  robo,
  rotura,
  vencimiento,
  bapRotura,
  bapVencimiento,
}

extension MermaTipoExtension on MermaTipo {
  String get etiqueta {
    switch (this) {
      case MermaTipo.robo:           return 'Robo';
      case MermaTipo.rotura:         return 'Rotura';
      case MermaTipo.vencimiento:    return 'Vencimiento';
      case MermaTipo.bapRotura:      return 'BAP de Rotura';
      case MermaTipo.bapVencimiento: return 'BAP de Vencimiento';
    }
  }

  String get valor {
    switch (this) {
      case MermaTipo.robo:           return 'robo';
      case MermaTipo.rotura:         return 'rotura';
      case MermaTipo.vencimiento:    return 'vencimiento';
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