import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/user_role.dart';

class UsuarioModel {
  final String uid;
  final String nombre;
  final String email;
  final UserRole rol;
  final DateTime? ultimoAcceso;

  const UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    this.ultimoAcceso,
  });

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UsuarioModel(
      uid: doc.id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] == 'supervisor'
          ? UserRole.supervisor
          : UserRole.inventarista,
      ultimoAcceso: (data['ultimoAcceso'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'email': email,
    'rol': rol == UserRole.supervisor ? 'supervisor' : 'inventarista',
    'ultimoAcceso': ultimoAcceso != null
        ? Timestamp.fromDate(ultimoAcceso!)
        : null,
  };

  UsuarioModel copyWith({
    String? nombre,
    String? email,
    UserRole? rol,
    DateTime? ultimoAcceso,
  }) {
    return UsuarioModel(
      uid: uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
    );
  }
}