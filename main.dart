import 'package:flutter/material.dart';
import 'notifications.dart';
import 'store.dart';
import 'theme.dart';
import 'screens/start.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.I.load();
  await Notif.init();
  Store.I.save();
  runApp(const SmartDiaryApp());
}

class SmartDiaryApp extends StatelessWidget {
  const SmartDiaryApp({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Store.I,
        builder: (_, __) {
          final t = Store.I.s.theme;
          return MaterialApp(
            title: 'Smart Diary',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: t == 'dark' ? ThemeMode.dark : t == 'light' ? ThemeMode.light : ThemeMode.system,
            home: const StartGate(),
          );
        },
      );
}
