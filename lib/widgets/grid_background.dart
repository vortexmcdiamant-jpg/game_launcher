import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Fond animé : sol en perspective façon garage / synthwave avec un halo
/// rouge à l'horizon. Le contenu de l'écran se place dans [child].
class GridBackground extends StatefulWidget {
  const GridBackground({super.key, this.child});

  final Widget? child;

  @override
  State<GridBackground> createState() => _GridBackgroundState();
}

class _GridBackgroundState extends State<GridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? child = widget.child;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RepaintBoundary(
          child: CustomPaint(painter: _GridPainter(_controller)),
        ),
        if (child != null) child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.anim) : super(repaint: anim);

  final Animation<double> anim;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect full = Offset.zero & size;
    final double horizon = h * 0.64;

    // Fond dégradé presque noir, légèrement rougeâtre en bas.
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF05060B), Color(0xFF0A0C16), Color(0xFF14060D)],
        ).createShader(full),
    );

    // Halo rouge à l'horizon (cercle dont le bord est totalement transparent).
    final double haloRadius = h * 0.45;
    canvas.drawCircle(
      Offset(w / 2, horizon),
      haloRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, horizon),
          haloRadius,
          <Color>[Neon.fade(Neon.red, 0.30), Neon.fade(Neon.red, 0.0)],
          <double>[0.0, 1.0],
        ),
    );

    // Lignes horizontales du sol : elles défilent vers le spectateur.
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const int rows = 14;
    for (int i = 0; i < rows; i++) {
      final double z = ((i + anim.value) % rows) / rows; // 0 = loin, 1 = près
      final double y = horizon + (h - horizon) * z * z;
      line.color = Neon.fade(Neon.cyan, 0.04 + 0.28 * z);
      canvas.drawLine(Offset(0, y), Offset(w, y), line);
    }

    // Lignes de fuite verticales.
    line.color = Neon.fade(Neon.cyan, 0.11);
    const int cols = 12;
    for (int i = -cols; i <= cols; i++) {
      final double xBottom = w / 2 + i * (w * 0.16);
      final double xTop = w / 2 + i * (w * 0.012);
      canvas.drawLine(Offset(xTop, horizon), Offset(xBottom, h), line);
    }

    // Ligne d'horizon rouge néon (un trait flou dessous, un trait net dessus).
    canvas.drawLine(
      Offset(0, horizon),
      Offset(w, horizon),
      Paint()
        ..strokeWidth = 4
        ..color = Neon.fade(Neon.red, 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawLine(
      Offset(0, horizon),
      Offset(w, horizon),
      Paint()
        ..strokeWidth = 1.2
        ..color = Neon.fade(Neon.red, 0.9),
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
