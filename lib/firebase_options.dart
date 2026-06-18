import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// IMPORTANTE: Reemplaza TODOS los valores con los de tu proyecto Firebase.
// Los encuentras en: Consola Firebase → Configuración del proyecto → Tus apps

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma.',
        );
    }
  }

  // ── WEB ──────────────────────────────────────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBl3dP6k1MfaNzJSbdfVruWWmjiwIUACMQ',
    appId: '1:886475451398:web:bea1836a860114063b2787',
    messagingSenderId: '886475451398',
    projectId: 'gestioninvlrpd01',
    authDomain: 'gestioninvlrpd01.firebaseapp.com',
    storageBucket: 'gestioninvlrpd01.firebasestorage.app',
  );
  // ── ANDROID ──────────────────────────────────────────────

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4BoWmTFRdbGq0RVxmqwVlg6ygrQTT8Wc',
    appId: '1:886475451398:android:086f76346f6edc913b2787',
    messagingSenderId: '886475451398',
    projectId: 'gestioninvlrpd01',
    storageBucket: 'gestioninvlrpd01.firebasestorage.app',
  );
  // ── iOS ───────────────────────────────────────────────────

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAu7F3NpPE8MpHY5CTySHWh4hxA3eUKrA0',
    appId: '1:886475451398:ios:5e2f4f87a45875e73b2787',
    messagingSenderId: '886475451398',
    projectId: 'gestioninvlrpd01',
    storageBucket: 'gestioninvlrpd01.firebasestorage.app',
    iosBundleId: 'com.example.sistemaInventariosLrpd',
  );
  // ── macOS ─────────────────────────────────────────────────

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAu7F3NpPE8MpHY5CTySHWh4hxA3eUKrA0',
    appId: '1:886475451398:ios:5e2f4f87a45875e73b2787',
    messagingSenderId: '886475451398',
    projectId: 'gestioninvlrpd01',
    storageBucket: 'gestioninvlrpd01.firebasestorage.app',
    iosBundleId: 'com.example.sistemaInventariosLrpd',
  );
  // ── WINDOWS ───────────────────────────────────────────────

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBl3dP6k1MfaNzJSbdfVruWWmjiwIUACMQ',
    appId: '1:886475451398:web:2f866c38686944833b2787',
    messagingSenderId: '886475451398',
    projectId: 'gestioninvlrpd01',
    authDomain: 'gestioninvlrpd01.firebaseapp.com',
    storageBucket: 'gestioninvlrpd01.firebasestorage.app',
  );
}
