import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage/app_storage.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}
