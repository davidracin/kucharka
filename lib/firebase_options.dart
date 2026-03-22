import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'This project is configured for web in this setup. Platform: $defaultTargetPlatform',
    );
  }

  static final FirebaseOptions web = FirebaseOptions(
    apiKey: _readEnv('FIREBASE_API_KEY'),
    appId: _readEnv('FIREBASE_APP_ID'),
    messagingSenderId: _readEnv('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _readEnv('FIREBASE_PROJECT_ID'),
    authDomain: _readEnv('FIREBASE_AUTH_DOMAIN'),
    storageBucket: _readEnv('FIREBASE_STORAGE_BUCKET'),
  );

  static String _readEnv(String key) {
    final value = dotenv.env[key] ?? '';
    if (value.isEmpty) {
      throw StateError('Missing key in .env: $key');
    }
    return value;
  }
}
