import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Jauge circulaire néon (RAM, batterie, température…).
/// [value] va de 0.0 à 1.0 ; l'anneau s'anime quand la valeur change.
class NeonGauge extends StatelessWidget {
  const NeonGauge({
    super.key,
    required this.value,
    required this.color,
    required this.center,
    required this.label,
    this.size = 104,
  });

  final double value;
  final Color color;

  /// Texte au centre de l'anneau (ex. « 36°C »).
  final String center;

  /// Légende sous l'anneau (ex. « TEMP »).
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: clampD(value, 0.0, 1.0)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double v, Widget? child) {
                  return CustomPaint(
                    size: Size.square(size),
                    painter: _RingPainter(v, color),
                  );
                },
              ),
              Text(
                center,
                style: displayStyle(size: size * 0.19, color: color, spacing: 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Neon.textDim,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 8;
    final Rect rect = Rect.fromCircle(center: c, radius: r);

    // Rail de l'anneau.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = Neon.fade(color, 0.14),
    );
    if (value <= 0) return;

    final double sweep = 2 * math.pi * value;
    // Halo flou puis trait net par-dessus.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = Neon.fade(color, 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
