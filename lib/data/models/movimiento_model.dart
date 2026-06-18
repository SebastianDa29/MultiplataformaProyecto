import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/tipo_movimiento.dart';

class MovimientoModel {
  final String id;
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final TipoMovimiento tipo;
  final String motivo;
  final String usuarioId;
  final String usuarioNombre;
  final DateTime fecha;
  final String? referenciaId;

  const MovimientoModel({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.tipo,
    required this.motivo,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.fecha,
    this.referenciaId,
  });

  factory MovimientoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MovimientoModel(
      id: doc.id,
      productoId: d['productoId'] ?? '',
      productoNombre: d['productoNombre'] ?? '',
      cantidad: d['cantidad'] ?? 0,
      tipo: TipoMovimientoExtension.fromValor(d['tipo'] ?? 'ajuste'),
      motivo: d['motivo'] ?? '',
      usuarioId: d['usuarioId'] ?? '',
      usuarioNombre: d['usuarioNombre'] ?? '',
      fecha: (d['fecha'] as Timestamp).toDate(),
      referenciaId: d['referenciaId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'productoId': productoId,
    'productoNombre': productoNombre,
    'cantidad': cantidad,
    'tipo': tipo.valor,
    'motivo': motivo,
    'usuarioId': usuarioId,
    'usuarioNombre': usuarioNombre,
    'fecha': Timestamp.fromDate(fecha),
    'referenciaId': referenciaId,
  };
}
