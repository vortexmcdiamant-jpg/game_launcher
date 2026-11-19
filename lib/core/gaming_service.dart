import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_status.dart';
import 'native_bridge.dart';

/// Actions du Mode Gaming utilisées à la fois par l'écran dédié et par le
/// bouton « Lancer » (boost automatique).
class GamingService {
  GamingService._();

  static const String _kDndByLauncher = 'dnd_by_launcher';

  /// Note si c'est le lanceur qui a activé « Ne pas déranger » tout seul
  /// (boost auto). On le coupe alors au retour dans l'appli, pour ne pas
  /// laisser le téléphone en silence sans que l'utilisateur le sache.
  /// Le marqueur est SAUVEGARDÉ sur le téléphone : si Android ferme le
  /// lanceur pendant une longue partie, on s'en souvient au retour.
  static Future<void> setLauncherOwnsDnd(bool value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDndByLauncher, value);
    } catch (_) {
      // Sauvegarde impossible : au pire, le silence n'est pas rétabli tout seul.
    }
  }

  static Future<bool> _launcherOwnsDnd() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kDndByLauncher) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Nettoie la RAM et active « Ne pas déranger » si l'accès est accordé.
  /// [keepPackage] : le jeu qu'on va lancer. Il ne doit pas être fermé, sinon
  /// une partie laissée en arrière-plan serait perdue.
  static Future<CleanResult?> quickBoost({String? keepPackage}) async {
    final CleanResult? result =
        await NativeBridge.cleanRam(keepPackage: keepPackage);
    final DndStatus dnd = await NativeBridge.dndStatus();
    if (dnd.granted && !dnd.active) {
      final bool ok = await NativeBridge.setDnd(true);
      await setLauncherOwnsDnd(ok);
    }
    return result;
  }

  /// À appeler quand l'utilisateur revient dans le lanceur après une partie.
  static Future<void> restoreAfterGame() async {
    if (!await _launcherOwnsDnd()) return;
    await setLauncherOwnsDnd(false);
    await NativeBridge.setDnd(false);
  }
}
