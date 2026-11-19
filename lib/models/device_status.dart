/// État de la batterie et de la chauffe du téléphone.
class BatteryStatus {
  const BatteryStatus({
    required this.level,
    required this.tempC,
    required this.charging,
    required this.thermal,
  });

  static const BatteryStatus unknown =
      BatteryStatus(level: -1, tempC: 0, charging: false, thermal: -1);

  /// Pourcentage 0..100, ou -1 si inconnu.
  final int level;

  /// Température de la BATTERIE en °C (0 si inconnue). Ce n'est pas la
  /// température du processeur : Android ne la donne pas aux applis.
  final double tempC;

  final bool charging;

  /// Niveau thermique Android (API 29+) : 0 normal … 6 arrêt, -1 inconnu.
  final int thermal;

  bool get hasData => level >= 0;
  bool get hasTemp => tempC > 0;

  String get thermalLabel {
    switch (thermal) {
      case 0:
        return 'Normal';
      case 1:
        return 'Léger';
      case 2:
        return 'Modéré';
      case 3:
        return 'Sévère';
      case 4:
        return 'Critique';
      case 5:
        return 'Urgence';
      case 6:
        return 'Arrêt imminent';
      default:
        return 'n/d';
    }
  }
}

/// Mémoire vive (en Mo).
class MemoryStatus {
  const MemoryStatus({required this.availMb, required this.totalMb});

  final int availMb;
  final int totalMb;

  int get usedMb => totalMb - availMb;

  double get usedRatio {
    if (totalMb <= 0) return 0.0;
    final double r = usedMb / totalMb;
    return r < 0.0 ? 0.0 : (r > 1.0 ? 1.0 : r);
  }
}

/// Résultat d'un nettoyage de la RAM.
class CleanResult {
  const CleanResult({
    required this.availBeforeMb,
    required this.availAfterMb,
    required this.totalMb,
  });

  final int availBeforeMb;
  final int availAfterMb;
  final int totalMb;

  int get freedMb =>
      availAfterMb > availBeforeMb ? availAfterMb - availBeforeMb : 0;
}

/// État du mode « Ne pas déranger ».
class DndStatus {
  const DndStatus({required this.granted, required this.active});

  /// L'utilisateur a-t-il autorisé l'appli à piloter « Ne pas déranger » ?
  final bool granted;

  /// « Ne pas déranger » est-il actif en ce moment ?
  final bool active;
}

/// 1536 -> « 1.5 Go », 800 -> « 800 Mo ».
String formatMb(int mb) {
  if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} Go';
  return '$mb Mo';
}
