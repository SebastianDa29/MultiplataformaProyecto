import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DateHelper {
  static final DateFormat _formato    = DateFormat('dd/MM/yyyy');
  static final DateFormat _formatiHora = DateFormat('dd/MM/yyyy HH:mm');

  static String formatear(DateTime fecha) => _formato.format(fecha);
  static String formatearConHora(DateTime fecha) => _formatiHora.format(fecha);

  static DateTime? fromTimestamp(Timestamp? ts) => ts?.toDate();
  static Timestamp toTimestamp(DateTime fecha) => Timestamp.fromDate(fecha);

  /// Devuelve true si hoy está dentro del período de promoción
  static bool promoActiva(DateTime? inicio, DateTime? fin) {
    if (inicio == null || fin == null) return false;
    final ahora = DateTime.now();
    return ahora.isAfter(inicio) && ahora.isBefore(fin.add(const Duration(days: 1)));
  }

  /// Devuelve true si la fecha de vencimiento ya pasó o está dentro de N días
  static bool proximoAVencer(DateTime? vencimiento, {int diasAlerta = 7}) {
    if (vencimiento == null) return false;
    final diasRestantes = vencimiento.difference(DateTime.now()).inDays;
    return diasRestantes <= diasAlerta;
  }

  static String hoy() => _formato.format(DateTime.now());
}