import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  FirebaseService._internal();
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get db => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  CollectionReference get usuarios => db.collection('usuarios');
  CollectionReference get productos => db.collection('productos');
  CollectionReference get mermas => db.collection('mermas');
  CollectionReference get historial => db.collection('historial');
  CollectionReference get config => db.collection('configuracion');
}