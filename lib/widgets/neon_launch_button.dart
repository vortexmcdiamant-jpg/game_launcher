import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Gros bouton central rouge néon, avec un halo qui pulse.
class NeonLaunchButton extends StatefulWidget {
  const NeonLaunchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon = Icons.play_arrow_rounded,
    this.width = 300,
    this.height = 82,
    this.fontSize = 26,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Icône à gauche du texte (une flèche « lecture » par défaut).
  final IconData icon;

  /// Dimensions et taille du texte (valeurs par défaut = gros bouton central).
  final double width;
  final double height;
  final double fontSize;

  /// Vrai pendant le boost / le lancement : affiche une roue de chargement.
  final bool busy;

  @override
  State<NeonLaunchButton> createState() => _NeonLaunchButtonState();
}

class _NeonLaunchButtonState extends State<NeonLaunchButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  bool _down = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.busy;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) {
        final double p = Curves.easeInOut.transform(_pulse.value);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (TapDownDetails d) => setState(() => _down = true) : null,
          onTapUp: enabled ? (TapUpDetails d) => setState(() => _down = false) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _down ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 90),
            child: Container(
              width: widget.width,
              height: widget.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFFF4D6D), Neon.red, Color(0xFFB0002A)],
                ),
                border: Border.all(
                  color: Neon.fade(Neon.cyan, 0.55 + 0.35 * p),
                  width: 1.6,
                ),
                boxShadow: Neon.glow(Neon.red, strength: 0.8 + 0.5 * p),
              ),
              child: widget.busy
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(widget.icon, size: 40, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          widget.label,
                          style: displayStyle(
                            size: widget.fontSize,
                            color: Colors.white,
                            weight: FontWeight.w900,
                            spacing: 6,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
