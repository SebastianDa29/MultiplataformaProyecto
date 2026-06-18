import 'package:flutter/material.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/enums/user_role.dart';

enum AuthStatus { inicial, cargando, autenticado, noAutenticado, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  AuthStatus status = AuthStatus.inicial;
  UsuarioModel? usuario;
  String? errorMensaje;

  // Módulos desbloqueados temporalmente en esta sesión (por clave secreta)
  final Set<Permiso> _permisosTemporales = {};

  Future<void> login(String email, String password) async {
    status = AuthStatus.autenticado;
    usuario = const UsuarioModel(
      uid: 'pda-test-uid',
      nombre: 'Tester PDA',
      email: 'test@pda.com',
      rol: UserRole.supervisor,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    usuario = null;
    status = AuthStatus.noAutenticado;
    notifyListeners();
  }

  /// Devuelve true si el usuario puede ejecutar el permiso solicitado
  bool puedeEjecutar(Permiso permiso) => true;

  /// Verifica la clave secreta (bypass para pruebas)
  Future<bool> desbloquearConClave(String clave, Permiso permiso) async {
    return true; // Siempre permite el acceso en pruebas
  }

  // bypass para pruebas: siempre es supervisor
  bool get esSupervisor => true;

  // Al inicializar, fingimos que ya estamos autenticados para pruebas
  void inicializarParaPruebas() {
    status = AuthStatus.autenticado;
    usuario = const UsuarioModel(
      uid: 'pda-test-uid',
      nombre: 'Tester PDA',
      email: 'test@pda.com',
      rol: UserRole.supervisor,
    );
    notifyListeners();
  }
}