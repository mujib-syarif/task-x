import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Services.init();
  runApp(const TaskXApp());
}
