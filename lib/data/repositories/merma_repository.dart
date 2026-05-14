import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/merma_model.dart';
import '../services/firebase_service.dart';

class MermaRepository {
  final FirebaseService _fb = FirebaseService();

  Future<void> registrar(MermaModel merma) async {
    await _fb.mermas.add(merma.toMap());
  }

  Stream<List<MermaModel>> listarTodas() {
    return _fb.mermas
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => MermaModel.fromFirestore(d))
        .toList());
  }

  Stream<List<MermaModel>> listarPorProducto(String codigoProducto) {
    return _fb.mermas
        .where('codigoProducto', isEqualTo: codigoProducto)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => MermaModel.fromFirestore(d))
        .toList());
  }

  Future<List<MermaModel>> listarPorFecha(DateTime inicio, DateTime fin) async {
    final snap = await _fb.mermas
        .where('fecha',
        isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        isLessThanOrEqualTo: Timestamp.fromDate(fin))
        .orderBy('fecha', descending: true)
        .get();
    return snap.docs.map((d) => MermaModel.fromFirestore(d)).toList();
  }
}