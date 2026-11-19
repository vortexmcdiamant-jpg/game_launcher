import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/game.dart';
import 'game_card.dart';

/// Carrousel 3D : on glisse de gauche à droite, les affiches du centre sont
/// de face et grandes, celles des côtés pivotent, rapetissent et s'estompent.
class GameCarousel extends StatelessWidget {
  const GameCarousel({
    super.key,
    required this.games,
    required this.controller,
    required this.onPageChanged,
  });

  final List<Game> games;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  /// Position fractionnaire du carrousel (ex. 2.37 = entre le 3e et le 4e jeu).
  double _currentPage() {
    if (!controller.hasClients) return controller.initialPage.toDouble();
    // Pendant la toute première mise en page, lire `controller.page` déclenche
    // une assertion (debug) : on attend que les dimensions soient connues.
    final ScrollPosition pos = controller.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) {
      return controller.initialPage.toDouble();
    }
    return controller.page ?? controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: games.length,
      clipBehavior: Clip.none,
      physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
      onPageChanged: onPageChanged,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          // Un toucher sur une affiche latérale la ramène au centre.
          onTap: () => controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, Widget? child) {
              return _Tilt(delta: index - _currentPage(), game: games[index]);
            },
          ),
        );
      },
    );
  }
}

/// Applique la perspective 3D à une affiche selon son éloignement du centre.
/// [delta] = 0 au centre, négatif à gauche, positif à droite.
class _Tilt extends StatelessWidget {
  const _Tilt({required this.delta, required this.game});

  final double delta;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final double d = clampD(delta, -2.0, 2.0);
    final double a = d.abs();

    // Rotation autour de l'axe vertical. Le signe « - » fait « reculer » le
    // bord extérieur des affiches (effet anneau). Remplace-le par « + » pour
    // l'effet coverflow (les bords intérieurs reculent).
    final double angle = clampD(-d * 0.85, -1.15, 1.15);
    final double scale = clampD(1.0 - a * 0.20, 0.62, 1.0);
    final double dy = clampD(a, 0.0, 1.0) * 14.0;
    final double opacity = clampD(1.0 - a * 0.38, 0.25, 1.0);
    final double focus = clampD(1.0 - a, 0.0, 1.0);

    final Matrix4 perspective = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateY(angle);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          child: Transform(
            alignment: Alignment.center,
            transform: perspective,
            child: GameCard(game: game, focus: focus),
          ),
        ),
      ),
    );
  }
}
