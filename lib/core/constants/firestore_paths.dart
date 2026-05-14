class FirestorePaths {
  static const String usuarios   = 'usuarios';
  static const String productos  = 'productos';
  static const String mermas     = 'mermas';
  static const String historial  = 'historial';
  static const String config     = 'configuracion';

  static String productoDoc(String id) => 'productos/$id';
  static String mermaDoc(String id)    => 'mermas/$id';
  static String usuarioDoc(String uid) => 'usuarios/$uid';
}