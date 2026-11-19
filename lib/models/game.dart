import 'dart:typed_data';

/// Un jeu (ou une appli) détecté sur le téléphone.
class Game {
  const Game({
    required this.name,
    required this.packageName,
    this.icon,
    this.isGame = true,
  });

  final String name;

  /// Identifiant Android (ex. com.supercell.clashofclans).
  final String packageName;

  /// Icône au format PNG, ou null (on affiche alors une initiale stylisée).
  final Uint8List? icon;

  /// Faux pour une appli « normale » affichée via l'option « toutes les applis ».
  final bool isGame;
}
