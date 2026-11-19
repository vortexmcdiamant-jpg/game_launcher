import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/game.dart';

/// Affiche d'un jeu : icône sur une tuile néon, avec son reflet au sol.
/// [focus] vaut 1.0 au centre du carrousel et tend vers 0.0 sur les côtés
/// (la bordure passe alors du rouge au cyan).
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game, required this.focus});

  final Game game;
  final double focus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double side = math.min(box.maxWidth * 0.94, box.maxHeight * 0.72);
        final Color border = Color.lerp(Neon.cyan, Neon.red, focus) ?? Neon.cyan;

        return Center(
          child: SizedBox(
            width: side,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: side,
                  height: side,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(side * 0.2),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Neon.panelHi, Neon.panel],
                    ),
                    border: Border.all(
                      color: Neon.fade(border, 0.5 + 0.5 * focus),
                      width: 1.6,
                    ),
                    boxShadow: Neon.glow(border, strength: 0.3 + 0.9 * focus),
                  ),
                  child: _iconTile(side),
                ),
                SizedBox(height: side * 0.04),
                _reflection(side),
              ],
            ),
          ),
        );
      },
    );
  }

  /// L'icône du jeu (ou une initiale stylisée), avec une marge autour.
  Widget _iconTile(double side) {
    return Padding(
      padding: EdgeInsets.all(side * 0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(side * 0.14),
        child: _icon(side),
      ),
    );
  }

  Widget _icon(double side) {
    final icon = game.icon;
    if (icon != null) {
      return Image.memory(
        icon,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }
    final String letter = game.name.isEmpty
        ? '?'
        : String.fromCharCode(game.name.runes.first).toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Neon.fade(Neon.red, 0.35), Neon.fade(Neon.cyan, 0.25)],
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: displayStyle(size: side * 0.4, weight: FontWeight.w900),
        ),
      ),
    );
  }

  /// Reflet : la tuile retournée verticalement, coupée à 30 % de sa hauteur
  /// et qui s'efface en dégradé, comme sur un sol brillant.
  Widget _reflection(double side) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Neon.fade(Colors.white, 0.35), Neon.fade(Colors.white, 0.0)],
        ).createShader(bounds);
      },
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.3,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1.0, -1.0, 1.0),
            child: SizedBox(
              width: side,
              height: side,
              child: _iconTile(side),
            ),
          ),
        ),
      ),
    );
  }
}
