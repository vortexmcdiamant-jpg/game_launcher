import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglages de l'appli, sauvegardés sur le téléphone.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _muted = _prefs.getBool(_kMuted) ?? false;
    _autoBoost = _prefs.getBool(_kAutoBoost) ?? true;
    _showAllApps = _prefs.getBool(_kShowAllApps) ?? false;
  }

  static const String _kMuted = 'muted';
  static const String _kAutoBoost = 'auto_boost';
  static const String _kShowAllApps = 'show_all_apps';

  final SharedPreferences _prefs;

  bool _muted = false;
  bool _autoBoost = true;
  bool _showAllApps = false;

  static Future<SettingsController> load() async {
    return SettingsController(await SharedPreferences.getInstance());
  }

  /// Vrai = le son de démarrage est coupé (option « Mute »).
  bool get muted => _muted;

  /// Vrai = « Lancer » nettoie la RAM et active « Ne pas déranger » avant le jeu.
  bool get autoBoost => _autoBoost;

  /// Vrai = le carrousel montre toutes les applis, pas seulement les jeux.
  bool get showAllApps => _showAllApps;

  Future<void> setMuted(bool value) async {
    _muted = value;
    notifyListeners();
    await _prefs.setBool(_kMuted, value);
  }

  Future<void> setAutoBoost(bool value) async {
    _autoBoost = value;
    notifyListeners();
    await _prefs.setBool(_kAutoBoost, value);
  }

  Future<void> setShowAllApps(bool value) async {
    _showAllApps = value;
    notifyListeners();
    await _prefs.setBool(_kShowAllApps, value);
  }
}
