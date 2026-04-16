import 'package:firebase_core/firebase_core.dart';

class FirebaseInitializer {
  Future<FirebaseApp> initialize() {
    return Firebase.initializeApp();
  }
}
