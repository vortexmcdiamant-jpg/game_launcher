import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
import 'package:flutter/services.dart';

import '../models/device_status.dart';
import '../models/game.dart';

/// Pont Flutter <-> Android (code Kotlin dans MainActivity.kt).
///
/// Toutes les méthodes sont « sûres » : sur iOS, ou en cas d'erreur, elles
/// renvoient une valeur par défaut au lieu de faire planter l'appli. Quand le
/// pont échoue, [bridgeError] contient la raison (affichée dans l'appli).
class NativeBridge {
  NativeBridge._();

  static const MethodChannel _channel = MethodChannel('gamelauncher/native');

  /// Liste des jeux, nettoyage RAM, « Ne pas déranger » : Android uniquement.
  /// iOS interdit à une appli de voir les autres applis ou de les fermer.
  static bool get supported => Platform.isAndroid;

  /// Dernière erreur du pont Android (null = tout va bien). Un bandeau rouge
  /// l'affiche à l'écran : sans ça, un MainActivity.kt absent ou inactif
  /// donnerait juste des jauges vides, sans explication.
  static final ValueNotifier<String?> bridgeError = ValueNotifier<String?>(null);

  // Jeux fictifs affichés quand on n'est pas sur Android (démo / tests).
  static const List<Game> _demoGames = <Game>[
    Game(name: 'Asphalt Nitro', packageName: 'demo.asphalt'),
    Game(name: 'Drift Legends', packageName: 'demo.drift'),
    Game(name: 'Neon Racer', packageName: 'demo.neon'),
    Game(name: 'Turbo Garage', packageName: 'demo.turbo'),
    Game(name: 'Apex Pursuit', packageName: 'demo.apex'),
    Game(name: 'Rally Storm', packageName: 'demo.rally'),
  ];

  /// Appelle une méthode Kotlin. Renvoie null en cas d'échec, et dans ce cas
  /// remplit [bridgeError]. Un appel réussi efface l'erreur.
  static Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      final T? result = await _channel.invokeMethod<T>(method, args);
      bridgeError.value = null;
      return result;
    } on MissingPluginException {
      bridgeError.value =
          'Le code Android ne répond pas (MissingPluginException sur « $method »). '
          "Le MainActivity.kt fourni n'est pas actif dans ce projet.";
      debugPrint('NativeBridge.$method : MissingPluginException');
    } on PlatformException catch (e) {
      bridgeError.value = 'Erreur Android sur « $method » : ${e.message ?? e.code}';
      debugPrint('NativeBridge.$method : $e');
    }
    return null;
  }

  /// Jeux installés (ou toutes les applis lançables si [includeAll]).
  static Future<List<Game>> getGames({bool includeAll = false}) async {
    if (!supported) return _demoGames;
    final List<dynamic>? raw = await _invoke<List<dynamic>>(
        'getGames', <String, dynamic>{'includeAll': includeAll});
    final List<Game> games = <Game>[];
    for (final dynamic item in raw ?? const <dynamic>[]) {
      if (item is! Map) continue;
      games.add(Game(
        name: (item['name'] as String?) ?? '?',
        packageName: (item['package'] as String?) ?? '',
        icon: item['icon'] as Uint8List?,
        isGame: (item['isGame'] as bool?) ?? true,
      ));
    }
    return games;
  }

  /// Lance le jeu. Renvoie false s'il est introuvable ou en mode démo.
  static Future<bool> launchGame(String packageName) async {
    if (!supported) return false;
    final bool? ok = await _invoke<bool>(
        'launchGame', <String, dynamic>{'package': packageName});
    return ok ?? false;
  }

  static Future<BatteryStatus> getBattery() async {
    if (!supported) return BatteryStatus.unknown;
    final Map<dynamic, dynamic>? m =
        await _invoke<Map<dynamic, dynamic>>('getBattery');
    if (m == null) return BatteryStatus.unknown;
    return BatteryStatus(
      level: (m['level'] as num?)?.toInt() ?? -1,
      tempC: (m['tempC'] as num?)?.toDouble() ?? 0,
      charging: (m['charging'] as bool?) ?? false,
      thermal: (m['thermal'] as num?)?.toInt() ?? -1,
    );
  }

  static Future<MemoryStatus?> getMemory() async {
    if (!supported) return null;
    final Map<dynamic, dynamic>? m =
        await _invoke<Map<dynamic, dynamic>>('getMemory');
    if (m == null) return null;
    return MemoryStatus(
      availMb: (m['availMb'] as num?)?.toInt() ?? 0,
      totalMb: (m['totalMb'] as num?)?.toInt() ?? 0,
    );
  }

  /// Demande à Android de fermer les processus en arrière-plan des applis
  /// (hors système, hors lanceur et hors [keepPackage], le jeu qu'on va
  /// lancer). Dure environ 1 seconde.
  static Future<CleanResult?> cleanRam({String? keepPackage}) async {
    if (!supported) return null;
    final Map<dynamic, dynamic>? m = await _invoke<Map<dynamic, dynamic>>(
        'cleanRam', <String, dynamic>{'keep': keepPackage});
    if (m == null) return null;
    return CleanResult(
      availBeforeMb: (m['availBeforeMb'] as num?)?.toInt() ?? 0,
      availAfterMb: (m['availAfterMb'] as num?)?.toInt() ?? 0,
      totalMb: (m['totalMb'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<DndStatus> dndStatus() async {
    const DndStatus none = DndStatus(granted: false, active: false);
    if (!supported) return none;
    final Map<dynamic, dynamic>? m =
        await _invoke<Map<dynamic, dynamic>>('dndStatus');
    if (m == null) return none;
    return DndStatus(
      granted: (m['granted'] as bool?) ?? false,
      active: (m['active'] as bool?) ?? false,
    );
  }

  /// Ouvre l'écran Android où l'utilisateur autorise l'accès à « Ne pas déranger ».
  static Future<void> openDndSettings() async {
    if (!supported) return;
    await _invoke<Object>('openDndSettings');
  }

  /// Active / désactive « Ne pas déranger ». Faux si l'accès n'est pas accordé.
  static Future<bool> setDnd(bool enabled) async {
    if (!supported) return false;
    final bool? ok =
        await _invoke<bool>('setDnd', <String, dynamic>{'enabled': enabled});
    return ok ?? false;
  }
}
