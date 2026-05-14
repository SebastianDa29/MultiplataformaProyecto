import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/merma_tipo.dart';

class MermaModel {
  final String id;
  final String codigoProducto;
  final String nombreProducto;
  final MermaTipo tipo;
  final int cantidad;
  final String observacion;
  final String registradoPor;
  final DateTime fecha;

  const MermaModel({
    required this.id,
    required this.codigoProducto,
    required this.nombreProducto,
    required this.tipo,
    required this.cantidad,
    required this.observacion,
    required this.registradoPor,
    required this.fecha,
  });

  factory MermaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MermaModel(
      id: doc.id,
      codigoProducto: data['codigoProducto'] ?? '',
      nombreProducto: data['nombreProducto'] ?? '',
      tipo: MermaTipoExtension.fromValor(data['tipo'] ?? 'rotura'),
      cantidad: data['cantidad'] ?? 0,
      observacion: data['observacion'] ?? '',
      registradoPor: data['registradoPor'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'codigoProducto': codigoProducto,
    'nombreProducto': nombreProducto,
    'tipo': tipo.valor,
    'cantidad': cantidad,
    'observacion': observacion,
    'registradoPor': registradoPor,
    'fecha': Timestamp.fromDate(fecha),
  };
}