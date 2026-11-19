import 'package:flutter/material.dart';

import '../core/native_bridge.dart';
import '../core/theme.dart';

/// Bandeau rouge affiché quand Flutter n'arrive pas à parler au code Android
/// (MainActivity.kt absent, inactif ou en erreur). Invisible quand tout va bien
/// et sur iOS.
class NativeErrorBanner extends StatelessWidget {
  const NativeErrorBanner({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(20, 10, 20, 0),
  });

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (!NativeBridge.supported) return const SizedBox.shrink();

    return ValueListenableBuilder<String?>(
      valueListenable: NativeBridge.bridgeError,
      builder: (BuildContext context, String? error, Widget? child) {
        if (error == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: margin,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Neon.fade(Neon.red, 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Neon.fade(Neon.red, 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PONT ANDROID NON CONNECTÉ',
                style: displayStyle(size: 12, color: Neon.red, spacing: 2),
              ),
              const SizedBox(height: 6),
              Text(
                error,
                style: const TextStyle(color: Neon.text, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 8),
              const Text(
                "1. Arrête complètement l'appli, puis relance « flutter run » "
                "(un hot reload ne suffit pas).\n"
                "2. Vérifie que le MainActivity.kt du projet est bien celui fourni "
                "(README, étape 3).",
                style: TextStyle(color: Neon.textDim, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }
}
