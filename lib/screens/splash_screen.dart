import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../widgets/grid_background.dart';
import 'home_screen.dart';

/// Écran de démarrage : tachymètre néon + son de moteur (sauf si Mute).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.settings, required this.sound});

  final SettingsController settings;
  final SoundService sound;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Durée totale = durée du fichier engine_start.wav fourni (2,8 s).
  static const Duration _total = Duration(milliseconds: 2800);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _total);

  bool _left = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) _goHome();
    });
    // Le son démarre dès l'ouverture, sauf si l'utilisateur a activé Mute.
    if (!widget.settings.muted) {
      widget.sound.playStartup();
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goHome() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (BuildContext context, Animation<double> a, Animation<double> b) =>
            HomeScreen(settings: widget.settings, sound: widget.sound),
        transitionsBuilder: (BuildContext context, Animation<double> a,
                Animation<double> b, Widget child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  /// Régime moteur de 0.0 à 1.0 en fonction du temps [s] (en secondes),
  /// calé sur la chronologie du son : démarreur -> ralenti -> coup d'accélérateur.
  static double _rev(double s) {
    if (s < 0.60) return 0.05 + 0.04 * math.sin(s * 40).abs();
    if (s < 0.95) return 0.18 + 0.02 * math.sin(s * 30);
    if (s < 1.55) {
      return 0.18 + 0.77 * Curves.easeIn.transform((s - 0.95) / 0.60);
    }
    if (s < 2.20) {
      return 0.95 - 0.70 * Curves.easeOut.transform((s - 1.55) / 0.65);
    }
    return 0.25 - 0.05 * clampD((s - 2.20) / 0.60, 0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Un toucher passe l'intro (et coupe le son).
        onTap: () {
          widget.sound.stop();
          _goHome();
        },
        child: GridBackground(
          child: SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  final double s = _controller.value * _total.inMilliseconds / 1000.0;
                  final double rev = _rev(s);
                  final double fadeIn = clampD(s / 0.5, 0.0, 1.0);
                  final double flicker =
                      s < 0.9 ? 0.55 + 0.45 * (math.sin(s * 70) * 0.5 + 0.5) : 1.0;

                  return Opacity(
                    opacity: fadeIn,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              CustomPaint(
                                size: const Size.square(280),
                                painter: _TachoPainter(rev),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    (rev * 8).toStringAsFixed(1),
                                    style: displayStyle(
                                      size: 44,
                                      weight: FontWeight.w900,
                                      spacing: 1,
                                    ),
                                  ),
                                  const Text(
                                    'x1000 RPM',
                                    style: TextStyle(
                                      color: Neon.textDim,
                                      fontSize: 11,
                                      letterSpacing: 3,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Opacity(
                          opacity: flicker,
                          // FittedBox : le titre rétrécit au lieu de déborder
                          // sur un petit écran ou avec une police plus large.
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'GAME ',
                                style: displayStyle(
                                  size: 28,
                                  color: Neon.red,
                                  weight: FontWeight.w900,
                                  spacing: 4,
                                ).copyWith(
                                  shadows: <Shadow>[
                                    Shadow(color: Neon.fade(Neon.red, 0.8), blurRadius: 18),
                                  ],
                                ),
                              ),
                              Text(
                                'LAUNCHER',
                                style: displayStyle(
                                  size: 28,
                                  color: Neon.cyan,
                                  weight: FontWeight.w900,
                                  spacing: 4,
                                ).copyWith(
                                  shadows: <Shadow>[
                                    Shadow(color: Neon.fade(Neon.cyan, 0.8), blurRadius: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.settings.muted ? 'SON COUPÉ' : 'DÉMARRAGE…',
                          style: const TextStyle(
                            color: Neon.textDim,
                            fontSize: 12,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tachymètre : arc de 270°, graduations, zone rouge, aiguille.
class _TachoPainter extends CustomPainter {
  _TachoPainter(this.rev);

  final double rev;

  static const double _start = 3 * math.pi / 4; // 135°
  static const double _sweep = 3 * math.pi / 2; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 14;
    final Rect rect = Rect.fromCircle(center: c, radius: r);

    // Rail de l'arc.
    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = Neon.fade(Neon.cyan, 0.12),
    );

    // Graduations (les dernières sont rouges : zone rouge du compte-tours).
    final Paint tick = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i <= 27; i++) {
      final double ang = _start + _sweep * i / 27;
      final bool major = i % 3 == 0;
      final double r1 = r - 18;
      final double r2 = r - (major ? 34 : 27);
      tick.color = i >= 22
          ? Neon.fade(Neon.red, major ? 0.95 : 0.6)
          : Neon.fade(Neon.cyan, major ? 0.8 : 0.4);
      canvas.drawLine(
        c + Offset(math.cos(ang) * r1, math.sin(ang) * r1),
        c + Offset(math.cos(ang) * r2, math.sin(ang) * r2),
        tick,
      );
    }

    // Arc actif : dégradé cyan -> rouge, avec halo flou.
    if (rev > 0.005) {
      final Shader shader = const SweepGradient(
        startAngle: 0.0,
        endAngle: _sweep,
        colors: <Color>[Neon.cyan, Neon.red],
        transform: GradientRotation(_start),
      ).createShader(rect);
      canvas.drawArc(
        rect,
        _start,
        _sweep * rev,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawArc(
        rect,
        _start,
        _sweep * rev,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..shader = shader,
      );
    }

    // Aiguille.
    final double na = _start + _sweep * rev;
    canvas.drawLine(
      c - Offset(math.cos(na) * 14, math.sin(na) * 14),
      c + Offset(math.cos(na) * (r - 10), math.sin(na) * (r - 10)),
      Paint()
        ..color = Neon.red
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 9, Paint()..color = Neon.panelHi);
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Neon.cyan,
    );
  }

  @override
  bool shouldRepaint(_TachoPainter oldDelegate) => oldDelegate.rev != rev;
}
