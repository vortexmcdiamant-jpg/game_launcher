import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../widgets/grid_background.dart';

/// Réglages : Mute, boost automatique, affichage de toutes les applis.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings, required this.sound});

  final SettingsController settings;
  final SoundService sound;

  void _testSound(BuildContext context) {
    if (settings.muted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Le son est coupé (Mute).')));
      return;
    }
    sound.playStartup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (BuildContext context, Widget? child) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Retour',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Neon.cyan),
                      ),
                      Text('RÉ', style: displayStyle(size: 20, color: Neon.red, spacing: 3)),
                      Text('GLAGES', style: displayStyle(size: 20, color: Neon.cyan, spacing: 3)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SwitchTile(
                    icon: Icons.volume_off_rounded,
                    title: 'MUTE',
                    subtitle: 'Coupe le son de moteur au démarrage',
                    value: settings.muted,
                    onChanged: (bool v) {
                      settings.setMuted(v);
                      if (v) sound.stop();
                    },
                  ),
                  _ActionTile(
                    icon: Icons.graphic_eq_rounded,
                    title: 'TESTER LE SON',
                    subtitle: 'Joue le son de démarrage maintenant',
                    onTap: () => _testSound(context),
                  ),
                  _SwitchTile(
                    icon: Icons.bolt_rounded,
                    title: 'BOOST AUTOMATIQUE',
                    subtitle: 'Nettoie la RAM et active « Ne pas déranger » en lançant un jeu',
                    value: settings.autoBoost,
                    onChanged: settings.setAutoBoost,
                  ),
                  _SwitchTile(
                    icon: Icons.apps_rounded,
                    title: 'TOUTES LES APPLIS',
                    subtitle: 'Affiche toutes les applis, pas seulement les jeux détectés',
                    value: settings.showAllApps,
                    onChanged: settings.setShowAllApps,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Neon.fade(Neon.panel, 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Neon.fade(Neon.cyan, 0.30)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Icon(icon, color: Neon.cyan, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: displayStyle(size: 13, spacing: 2)),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Neon.textDim, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: const Icon(Icons.play_circle_outline_rounded, color: Neon.red, size: 30),
    );
  }
}
