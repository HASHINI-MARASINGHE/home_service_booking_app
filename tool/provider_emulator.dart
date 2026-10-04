// Optional local-testing entry point. Production main.dart is unchanged.
// flutter run -t tool/provider_emulator.dart --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:home_service_bookin_app/firebase_options.dart';
import 'package:home_service_bookin_app/main.dart' show MyApp;

Future<void> main() async {
  if (!kDebugMode) throw StateError('The emulator entry point is debug-only.');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  const host = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  runApp(const MyApp());
}
