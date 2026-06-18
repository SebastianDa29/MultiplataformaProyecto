import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movimiento_model.dart';
import '../services/firebase_service.dart';

class MovimientoRepository {
  final FirebaseService _fb = FirebaseService();

  Future<void> registrarMovimiento(MovimientoModel movimiento) async {
    await _fb.db.collection('movimientos').add(movimiento.toMap()).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Error al registrar movimiento (Timeout)'),
    );
  }

  Stream<List<MovimientoModel>> listarMovimientos() {
    return _fb.db.collection('movimientos')
        .orderBy('fecha', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => MovimientoModel.fromFirestore(doc))
        .toList());
  }

  Stream<List<MovimientoModel>> listarMovimientosPorProducto(String productoId) {
    return _fb.db.collection('movimientos')
        .where('productoId', isEqualTo: productoId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => MovimientoModel.fromFirestore(doc))
        .toList());
  }
}
