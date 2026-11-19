import 'dart:async';

import 'package:flutter/material.dart';

import '../core/gaming_service.dart';
import '../core/native_bridge.dart';
import '../core/theme.dart';
import '../models/device_status.dart';
import '../widgets/grid_background.dart';
import '../widgets/native_error_banner.dart';
import '../widgets/neon_gauge.dart';
import '../widgets/neon_launch_button.dart';

/// Tableau de bord du Mode Gaming : RAM, batterie, température,
/// nettoyage de la RAM et « Ne pas déranger ».
class GamingModeScreen extends StatefulWidget {
  const GamingModeScreen({super.key});

  @override
  State<GamingModeScreen> createState() => _GamingModeScreenState();
}

class _GamingModeScreenState extends State<GamingModeScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  BatteryStatus _battery = BatteryStatus.unknown;
  MemoryStatus? _memory;
  DndStatus _dnd = const DndStatus(granted: false, active: false);
  CleanResult? _lastClean;
  bool _cleaning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _startTimer();
  }

  /// Les jauges se mettent à jour toutes les 3 secondes, tant que l'écran est
  /// visible (le minuteur est coupé quand l'appli passe en arrière-plan).
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer t) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _timer = null;
    } else if (state == AppLifecycleState.resumed) {
      // Couvre aussi le retour de l'écran Android où l'on autorise
      // « Ne pas déranger ».
      _refresh();
      _startTimer();
    }
  }

  Future<void> _refresh() async {
    final BatteryStatus battery = await NativeBridge.getBattery();
    final MemoryStatus? memory = await NativeBridge.getMemory();
    final DndStatus dnd = await NativeBridge.dndStatus();
    if (!mounted) return;
    setState(() {
      _battery = battery;
      _memory = memory;
      _dnd = dnd;
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _clean() async {
    if (!NativeBridge.supported) {
      _toast('Le nettoyage de la RAM est disponible sur Android uniquement.');
      return;
    }
    setState(() => _cleaning = true);
    final CleanResult? result = await NativeBridge.cleanRam();
    await _refresh();
    if (!mounted) return;
    setState(() {
      _cleaning = false;
      _lastClean = result;
    });
  }

  Future<void> _toggleDnd(bool value) async {
    // L'utilisateur reprend la main : le boost auto ne touchera plus à ce réglage.
    await GamingService.setLauncherOwnsDnd(false);
    final bool ok = await NativeBridge.setDnd(value);
    if (!ok) _toast('Impossible de modifier « Ne pas déranger ».');
    await _refresh();
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: <Widget>[
              _header(),
              const NativeErrorBanner(margin: EdgeInsets.only(top: 4, bottom: 8)),
              const SizedBox(height: 12),
              if (!NativeBridge.supported) ...<Widget>[
                _panel(
                  accent: Neon.amber,
                  child: const Text(
                    "Mode démo : le Mode Gaming complet fonctionne sur Android. "
                    "iOS interdit aux applis de fermer les autres applis, de "
                    "piloter « Ne pas déranger » ou de lire la température.",
                    style: TextStyle(color: Neon.text, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _gauges(),
              const SizedBox(height: 22),
              _memoryPanel(),
              const SizedBox(height: 16),
              _dndPanel(),
              const SizedBox(height: 16),
              _thermalPanel(),
              const SizedBox(height: 18),
              const Text(
                "Android ne permet pas de fermer les applis système ni celle "
                "au premier plan, et le gain de RAM est souvent temporaire : "
                "le système relance certaines applis. La température affichée "
                "est celle de la batterie, pas celle du processeur.",
                style: TextStyle(color: Neon.textDim, fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Neon.cyan),
        ),
        Text('MODE ', style: displayStyle(size: 20, color: Neon.red, spacing: 3)),
        Text('GAMING', style: displayStyle(size: 20, color: Neon.cyan, spacing: 3)),
      ],
    );
  }

  Widget _gauges() {
    final MemoryStatus? mem = _memory;
    final bool hasMem = mem != null && mem.totalMb > 0;
    final double ramRatio = hasMem ? mem.usedRatio : 0.0;
    final Color ramColor = !hasMem
        ? Neon.textDim
        : (ramRatio < 0.70 ? Neon.cyan : (ramRatio < 0.85 ? Neon.amber : Neon.red));

    final BatteryStatus b = _battery;
    final Color battColor = !b.hasData
        ? Neon.textDim
        : ((b.charging || b.level >= 50)
            ? Neon.cyan
            : (b.level >= 20 ? Neon.amber : Neon.red));

    // 20 °C = jauge vide, 50 °C = jauge pleine.
    final double tempRatio = b.hasTemp ? clampD((b.tempC - 20.0) / 30.0, 0.0, 1.0) : 0.0;
    final Color tempColor = !b.hasTemp
        ? Neon.textDim
        : (b.tempC < 38 ? Neon.cyan : (b.tempC < 42 ? Neon.amber : Neon.red));

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double size = clampD((box.maxWidth - 24) / 3, 70.0, 104.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NeonGauge(
              size: size,
              value: ramRatio,
              color: ramColor,
              center: hasMem ? '${(ramRatio * 100).round()}%' : '--',
              label: 'RAM',
            ),
            NeonGauge(
              size: size,
              value: b.hasData ? b.level / 100.0 : 0.0,
              color: battColor,
              center: b.hasData ? '${b.level}%' : '--',
              label: b.charging ? 'EN CHARGE' : 'BATTERIE',
            ),
            NeonGauge(
              size: size,
              value: tempRatio,
              color: tempColor,
              center: b.hasTemp ? '${b.tempC.toStringAsFixed(0)}°C' : '--',
              label: 'TEMP',
            ),
          ],
        );
      },
    );
  }

  Widget _memoryPanel() {
    final MemoryStatus? m = _memory;
    final CleanResult? r = _lastClean;

    String info = 'Mémoire indisponible';
    if (m != null && m.totalMb > 0) {
      info = '${formatMb(m.usedMb)} utilisés sur ${formatMb(m.totalMb)} '
          '· ${formatMb(m.availMb)} libres';
    }
    String? cleanLine;
    if (r != null) {
      cleanLine = r.freedMb > 0
          ? 'Dernier nettoyage : ${formatMb(r.freedMb)} libérés'
          : 'Rien à libérer : la RAM est déjà propre';
    }

    return _panel(
      accent: Neon.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('MÉMOIRE', style: displayStyle(size: 14, color: Neon.red, spacing: 3)),
          const SizedBox(height: 8),
          Text(info, style: const TextStyle(color: Neon.text, height: 1.4)),
          if (cleanLine != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(cleanLine, style: const TextStyle(color: Neon.cyan, height: 1.4)),
          ],
          const SizedBox(height: 16),
          NeonLaunchButton(
            label: 'NETTOYER',
            icon: Icons.cleaning_services_rounded,
            busy: _cleaning,
            onPressed: _clean,
            width: double.infinity,
            height: 62,
            fontSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _dndPanel() {
    String hint;
    if (!NativeBridge.supported) {
      hint = 'Disponible sur Android';
    } else if (!_dnd.granted) {
      hint = "Autorise l'accès pour couper les notifications pendant le jeu.";
    } else {
      hint = _dnd.active ? 'Actif : notifications bloquées' : 'Inactif';
    }

    Widget trailing;
    if (_dnd.granted) {
      trailing = Switch(value: _dnd.active, onChanged: _toggleDnd);
    } else {
      trailing = OutlinedButton(
        onPressed: NativeBridge.supported ? NativeBridge.openDndSettings : null,
        child: const Text('AUTORISER'),
      );
    }

    return _panel(
      accent: Neon.cyan,
      child: Row(
        children: <Widget>[
          const Icon(Icons.do_not_disturb_on_rounded, color: Neon.cyan, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // FittedBox : le titre rétrécit au lieu d'être coupé en deux
                // sur les petits écrans.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NE PAS DÉRANGER',
                    style: displayStyle(size: 14, color: Neon.cyan, spacing: 3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: const TextStyle(color: Neon.textDim, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _thermalPanel() {
    final BatteryStatus b = _battery;
    final bool hot = (b.hasTemp && b.tempC >= 42) || b.thermal >= 3;
    final Color color = hot ? Neon.red : Neon.cyan;

    return _panel(
      accent: color,
      child: Row(
        children: <Widget>[
          Icon(Icons.thermostat_rounded, color: color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'ÉTAT THERMIQUE',
                  style: displayStyle(size: 14, color: color, spacing: 3),
                ),
                const SizedBox(height: 4),
                Text(
                  hot
                      ? 'Le téléphone chauffe : fais une pause ou retire la coque.'
                      : 'Niveau : ${b.thermalLabel}',
                  style: const TextStyle(color: Neon.textDim, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child, Color accent = Neon.cyan}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Neon.fade(Neon.panel, 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Neon.fade(accent, 0.45)),
      ),
      child: child,
    );
  }
}
