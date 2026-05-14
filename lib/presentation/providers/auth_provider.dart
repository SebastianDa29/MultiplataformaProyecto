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
    status = AuthStatus.cargando;
    errorMensaje = null;
    notifyListeners();

    try {
      usuario = await _repo.login(email, password);
      status = AuthStatus.autenticado;
    } catch (e) {
      status = AuthStatus.error;
      errorMensaje = 'Credenciales incorrectas';
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    usuario = null;
    _permisosTemporales.clear();
    status = AuthStatus.noAutenticado;
    notifyListeners();
  }

  /// Devuelve true si el usuario puede ejecutar el permiso solicitado
  bool puedeEjecutar(Permiso permiso) {
    if (usuario == null) return false;
    if (_permisosTemporales.contains(permiso)) return true;
    return usuario!.rol.puedeEjecutar(permiso);
  }

  /// Verifica la clave secreta y desbloquea el permiso temporalmente
  Future<bool> desbloquearConClave(String clave, Permiso permiso) async {
    final ok = await _repo.verificarClaveSecreta(clave);
    if (ok) {
      _permisosTemporales.add(permiso);
      notifyListeners();
    }
    return ok;
  }

  bool get esSupervisor => usuario?.rol == UserRole.supervisor;
}