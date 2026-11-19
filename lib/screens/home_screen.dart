import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/gaming_service.dart';
import '../core/native_bridge.dart';
import '../core/settings.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../models/device_status.dart';
import '../models/game.dart';
import '../widgets/game_carousel.dart';
import '../widgets/grid_background.dart';
import '../widgets/native_error_banner.dart';
import '../widgets/neon_launch_button.dart';
import 'gaming_mode_screen.dart';
import 'settings_screen.dart';

/// Accueil : carrousel 3D des jeux + gros bouton central « LANCER ».
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.settings, required this.sound});

  final SettingsController settings;
  final SoundService sound;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // viewportFraction 0.58 : on voit le jeu central et un bout des voisins.
  final PageController _pages =
      PageController(viewportFraction: 0.58, keepPage: false);

  List<Game> _games = const <Game>[];
  bool _loading = true;
  bool _launching = false;
  int _index = 0;
  late bool _showAll = widget.settings.showAllApps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_onSettingsChanged);
    // Si Android a fermé le lanceur pendant une partie, on rend le téléphone
    // sonore dès qu'on le rouvre.
    GamingService.restoreAfterGame();
    _loadGames();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_onSettingsChanged);
    _pages.dispose();
    super.dispose();
  }

  /// Recharge la liste quand l'option « toutes les applis » change.
  void _onSettingsChanged() {
    if (widget.settings.showAllApps != _showAll) {
      _showAll = widget.settings.showAllApps;
      _loadGames();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retour dans le lanceur après une partie : on rend le téléphone sonore.
    if (state == AppLifecycleState.resumed) {
      GamingService.restoreAfterGame();
    }
  }

  int _loadToken = 0;

  Future<void> _loadGames() async {
    final int token = ++_loadToken;
    setState(() => _loading = true);
    final List<Game> games =
        await NativeBridge.getGames(includeAll: widget.settings.showAllApps);
    // Un chargement plus récent a démarré entre-temps : on ignore celui-ci.
    if (!mounted || token != _loadToken) return;
    setState(() {
      _games = games;
      _index = 0;
      _loading = false;
    });
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _launch() async {
    if (_games.isEmpty || _launching) return;
    final Game game = _games[_index];
    setState(() => _launching = true);
    try {
      if (!NativeBridge.supported) {
        _toast('Mode démo : le lancement des jeux fonctionne sur Android.');
        return;
      }
      if (widget.settings.autoBoost) {
        final CleanResult? r =
            await GamingService.quickBoost(keepPackage: game.packageName);
        if (r != null && r.freedMb > 0) {
          _toast('RAM libérée : ${formatMb(r.freedMb)}');
        }
      }
      final bool ok = await NativeBridge.launchGame(game.packageName);
      if (!ok) {
        _toast('Impossible de lancer ${game.name}.');
        await GamingService.restoreAfterGame();
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  void _openGaming() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => const GamingModeScreen(),
    ));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) =>
          SettingsScreen(settings: widget.settings, sound: widget.sound),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _topBar(),
              const NativeErrorBanner(),
              Expanded(child: _body()),
              _bottom(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('GAME ', style: displayStyle(size: 18, color: Neon.red, spacing: 3)),
                    Text('LAUNCHER', style: displayStyle(size: 18, color: Neon.cyan, spacing: 3)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Mode Gaming',
            onPressed: _openGaming,
            icon: const Icon(Icons.speed_rounded, color: Neon.red, size: 28),
          ),
          IconButton(
            tooltip: 'Réglages',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded, color: Neon.cyan, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Neon.cyan));
    }
    if (_games.isEmpty) return _emptyState();

    return Column(
      children: <Widget>[
        Expanded(
          child: GameCarousel(
            games: _games,
            controller: _pages,
            onPageChanged: (int i) {
              HapticFeedback.selectionClick();
              setState(() => _index = i);
            },
          ),
        ),
        _gameInfo(),
      ],
    );
  }

  Widget _gameInfo() {
    final Game game = _games[_index];
    final String pos = (_index + 1).toString().padLeft(2, '0');
    final String total = _games.length.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        children: <Widget>[
          Text(
            game.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: displayStyle(size: 20, spacing: 3),
          ),
          const SizedBox(height: 4),
          Text(
            '$pos / $total',
            style: const TextStyle(
              color: Neon.cyan,
              fontSize: 13,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.sports_esports_rounded, size: 64, color: Neon.textDim),
            const SizedBox(height: 16),
            Text('AUCUN JEU DÉTECTÉ', style: displayStyle(size: 18)),
            const SizedBox(height: 10),
            const Text(
              "Android range une appli parmi les « jeux » seulement si son "
              "développeur l'a déclaré. Tu peux afficher toutes les applis "
              "et choisir toi-même.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Neon.textDim, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (!widget.settings.showAllApps)
              OutlinedButton(
                onPressed: () => widget.settings.setShowAllApps(true),
                child: const Text('AFFICHER TOUTES LES APPLIS'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottom() {
    final bool canLaunch = !_loading && _games.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NeonLaunchButton(
            label: 'LANCER',
            busy: _launching,
            onPressed: canLaunch ? _launch : null,
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: widget.settings,
            builder: (BuildContext context, Widget? child) {
              return Text(
                widget.settings.autoBoost
                    ? 'BOOST AUTO · RAM + NE PAS DÉRANGER'
                    : 'BOOST AUTO DÉSACTIVÉ',
                style: const TextStyle(
                  color: Neon.textDim,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
