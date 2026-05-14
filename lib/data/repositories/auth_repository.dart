import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';
import '../services/firebase_service.dart';
import '../../core/constants/firestore_paths.dart';

class AuthRepository {
  final FirebaseService _fb = FirebaseService();

  /// Inicia sesión y devuelve el modelo de usuario con su rol
  Future<UsuarioModel> login(String email, String password) async {
    final credential = await _fb.auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final doc = await _fb.usuarios.doc(uid).get();

    if (!doc.exists) throw Exception('Usuario no registrado en el sistema');

    // Actualizar último acceso
    await _fb.usuarios.doc(uid).update({
      'ultimoAcceso': FieldValue.serverTimestamp(),
    });

    return UsuarioModel.fromFirestore(doc);
  }

  Future<void> logout() async => _fb.auth.signOut();

  /// Devuelve el usuario actual si hay sesión activa
  Future<UsuarioModel?> usuarioActual() async {
    final user = _fb.auth.currentUser;
    if (user == null) return null;

    final doc = await _fb.usuarios.doc(user.uid).get();
    if (!doc.exists) return null;

    return UsuarioModel.fromFirestore(doc);
  }

  /// Verifica la clave secreta del supervisor guardada en Firestore
  Future<bool> verificarClaveSecreta(String claveIngresada) async {
    final doc = await _fb.config.doc('seguridad').get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    return data['claveSecreta'] == claveIngresada;
  }

  Stream<User?> get authStateChanges => _fb.auth.authStateChanges();
}