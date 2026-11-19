import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/settings.dart';
import 'core/sound_service.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait uniquement : le carrousel est pensé pour ça.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Neon.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // On charge les réglages AVANT d'afficher quoi que ce soit : le splash
  // doit savoir tout de suite si le son est coupé (Mute).
  final SettingsController settings = await SettingsController.load();
  runApp(GameLauncherApp(settings: settings, sound: SoundService()));
}

class GameLauncherApp extends StatelessWidget {
  const GameLauncherApp({super.key, required this.settings, required this.sound});

  final SettingsController settings;
  final SoundService sound;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Launcher',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: SplashScreen(settings: settings, sound: sound),
    );
  }
}
