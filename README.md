# Game Launcher — guide pas à pas

Lanceur de jeux futuriste (thème sombre, néon rouge/cyan, ambiance supercar) en **Flutter** :

- **Son de démarrage** de moteur à l'ouverture, avec option **Mute** dans les réglages
- **Carrousel 3D** des jeux détectés + gros bouton central **LANCER**
- **Mode Gaming** : nettoyage de la RAM, « Ne pas déranger », batterie et température

> ⚠️ Ce code a été écrit sans pouvoir le compiler (pas de Flutter dans l'environnement
> où je l'ai produit). Il a été relu avec soin, mais lance `flutter analyze` dès l'étape 4
> et envoie-moi tel quel tout message d'erreur : je le corrige.

---

## Ce qui marche sur quelle plateforme

| Fonction | Android | iOS |
|---|---|---|
| Son de démarrage + Mute | ✅ | ✅ |
| Carrousel 3D, thème, animations | ✅ | ✅ (avec des jeux fictifs de démo) |
| Détecter les jeux installés | ✅ | ❌ interdit par Apple |
| Lancer un jeu | ✅ | ❌ interdit par Apple |
| Nettoyer la RAM | ✅ (partiel, voir « Limites ») | ❌ |
| « Ne pas déranger » | ✅ (avec autorisation de l'utilisateur) | ❌ |
| Batterie / température | ✅ | ❌ |

iOS n'autorise pas une appli à voir, lancer ou fermer les autres applis. Sur iPhone,
l'appli s'ouvre donc en **mode démo** : un lanceur réel n'est possible que sur Android.

---

## Structure du projet

```
game_launcher/
├── pubspec.yaml                  dépendances + déclaration du son
├── assets/audio/engine_start.wav son de démarrage (2,8 s, généré — remplaçable)
├── lib/
│   ├── main.dart                 point d'entrée : charge les réglages, lance le splash
│   ├── core/
│   │   ├── theme.dart            couleurs néon, halos, styles de texte
│   │   ├── settings.dart         réglages sauvegardés (Mute, boost auto, toutes les applis)
│   │   ├── sound_service.dart    lecture du son de démarrage
│   │   ├── native_bridge.dart    pont Flutter <-> Android (MethodChannel)
│   │   └── gaming_service.dart   boost auto avant un jeu, restauration après
│   ├── models/                   Game, BatteryStatus, MemoryStatus, CleanResult…
│   ├── screens/
│   │   ├── splash_screen.dart    tachymètre animé + son
│   │   ├── home_screen.dart      carrousel + bouton LANCER
│   │   ├── gaming_mode_screen.dart  jauges, nettoyage RAM, Ne pas déranger
│   │   └── settings_screen.dart  Mute, boost auto, toutes les applis
│   └── widgets/                  carrousel 3D, affiche de jeu, jauge, bouton néon, fond animé
└── android_overlay/              code Android à copier dans le projet généré
    ├── MainActivity.kt           liste/lancement des jeux, RAM, batterie, DND
    └── AndroidManifest_ajouts.xml  permissions + <queries> à ajouter
```

Principe : **Flutter dessine tout** (écrans, animations, son). Le code **Kotlin** ne sert
qu'à parler à Android (jeux installés, RAM…). Les deux communiquent par un canal nommé
`gamelauncher/native`.

---

## Étape 1 — Installer les outils

1. Installe **Flutter** (flutter.dev → *Get started*) : version récente, 3.24 ou plus.
2. Installe **Android Studio** (pour le SDK Android et l'émulateur).
3. Pour iOS uniquement : un Mac avec **Xcode**.
4. Dans un terminal : `flutter doctor` — corrige ce qu'il signale en rouge.
5. Branche ton téléphone Android (mode développeur + débogage USB) ou crée un émulateur.

## Étape 2 — Créer le projet Flutter et y mettre mes fichiers

```bash
flutter create --org com.example --project-name game_launcher --platforms=android,ios game_launcher_app
```

Puis, depuis ce dossier `game_launcher/` :

1. Copie `pubspec.yaml` dans `game_launcher_app/` (remplace celui qui existe).
2. Copie le dossier `assets/` dans `game_launcher_app/`.
3. **Supprime** le dossier `game_launcher_app/lib/` généré, puis copie à la place mon dossier `lib/`.
4. **Supprime** `game_launcher_app/test/widget_test.dart` (il cherche une classe `MyApp` qui n'existe plus).

```bash
cd game_launcher_app
flutter pub get
```

## Étape 3 — Brancher le code Android

1. Dans le projet généré, trouve le fichier `MainActivity.kt` :
   `android/app/src/main/kotlin/…/MainActivity.kt` (le chemin dépend du nom de ton projet).
   **Il n'en faut qu'un seul.** Ouvre-le et **note sa toute première ligne** :
   `package quelque.chose`.
2. Remplace **tout le contenu** de ce fichier par celui de `android_overlay/MainActivity.kt`,
   puis remets en **première ligne** le `package …` que tu viens de noter. Cette ligne doit être
   identique à l'original : sinon Android continue d'utiliser l'ancien fichier, sans erreur ni
   message, et l'appli affiche des jauges vides.
3. Ouvre `android/app/src/main/AndroidManifest.xml` et ajoute les blocs de
   `android_overlay/AndroidManifest_ajouts.xml` (les 2 permissions avant `<application>`,
   le bloc `<queries>` après `</application>`), puis mets `android:label="Game Launcher"`.

Sans le bloc `<queries>`, Android 11+ cache les autres applis : le carrousel resterait vide.

> ⚠️ Le code Kotlin et le manifeste **ne sont pas pris en compte par un hot reload (`r`) ni un
> hot restart (`R`)**. Après toute modification dans `android/`, arrête l'appli et relance
> `flutter run` (au besoin après `flutter clean`).

## Étape 4 — Lancer et vérifier

```bash
flutter analyze
flutter run
```

Ce que tu dois voir :

1. **Démarrage** : le tachymètre monte et le moteur gronde (≈ 3 s). Un toucher passe l'intro.
2. **Accueil** : si aucun jeu n'est détecté, bouton « Afficher toutes les applis », ou active-le dans les réglages.
3. **Carrousel** : glisse de gauche à droite ; l'affiche centrale est grande et de face, les voisines pivotent. Toucher une affiche latérale la ramène au centre.
4. **LANCER** : nettoie la RAM, active « Ne pas déranger » si autorisé, puis ouvre le jeu.
5. **Mode Gaming** (icône compteur en haut à droite) : 3 jauges, bouton NETTOYER, interrupteur « Ne pas déranger ».
6. **Réglages** : **Mute** coupe le son de démarrage au prochain lancement de l'appli ; « Tester le son » le rejoue.

« Ne pas déranger » : au premier usage, le bouton AUTORISER ouvre l'écran Android où tu
actives l'accès pour *Game Launcher*. Au retour dans l'appli, l'état se met à jour.

## Étape 5 — Remplacer le son de moteur

`assets/audio/engine_start.wav` est un moteur V8 **synthétique** (démarreur, allumage,
coup d'accélérateur, retour au ralenti), calé sur l'animation du tachymètre. Pour un son plus
réaliste, remplace ce fichier par le tien, **en gardant le même nom** :

- Durée idéale : ≈ 3 s (le splash dure 2,8 s : constante `_total` dans `splash_screen.dart`).
- Prends un son dont tu as les droits (libre de droits, CC0, acheté…). Ne copie pas un son de jeu ou de constructeur.
- Autre format (mp3…) : change le nom dans `pubspec.yaml` **et** dans `sound_service.dart`.

## Étape 6 — Personnaliser

| Je veux changer… | Où |
|---|---|
| Les couleurs néon | `lib/core/theme.dart` (classe `Neon`) |
| L'inclinaison / la taille des affiches | `lib/widgets/game_carousel.dart` (`angle`, `scale`, `opacity`) |
| Le nombre d'affiches visibles | `lib/screens/home_screen.dart` (`viewportFraction`, 0.58) |
| Les seuils de température | `lib/screens/gaming_mode_screen.dart` (`_gauges`) |
| Une police futuriste | `pubspec.yaml` : ajoute Orbitron (licence libre, fonts.google.com) et décommente le bloc `fonts` |

---

## Dépannage

**Jauges « -- », « Mémoire indisponible », aucun jeu détecté.** L'interface marche mais Flutter
ne parle pas au code Android. Un **bandeau rouge « PONT ANDROID NON CONNECTÉ »** s'affiche alors
en haut avec la raison exacte. Dans l'ordre :

1. `MissingPluginException` : le `MainActivity.kt` fourni n'est pas actif. Refais l'étape 3
   (une seule `MainActivity.kt`, même `package` que l'original), puis
   `flutter clean && flutter run` (pas de hot reload).
2. Le projet a un autre nom que `game_launcher` ? Le dossier `kotlin/…` porte ce nom-là : c'est
   le `package` du fichier d'origine qu'il faut garder, pas celui de mon exemple.
3. Le bandeau n'apparaît pas mais le carrousel est vide : ajoute (ou corrige) le bloc `<queries>`
   du manifeste, puis relance complètement. Sinon, ouvre les réglages et active « Toutes les applis ».
4. Autre message d'erreur : copie-le-moi tel quel.

## Limites à connaître

- **RAM** : Android interdit de fermer l'appli au premier plan et les applis système. Le nettoyage ferme les processus d'**arrière-plan**, et le système en relance certains : le gain est réel mais souvent temporaire. Le jeu que tu lances n'est jamais fermé.
- **Température** : c'est celle de la **batterie**. Android ne donne pas celle du processeur aux applis. L'« état thermique » (Normal, Léger…) vient du système (Android 10+).
- **Détection des jeux** : Android ne classe une appli parmi les jeux que si son développeur l'a déclaré. Les autres apparaissent avec l'option « Toutes les applis ».
- **Google Play** : l'appli évite la permission `QUERY_ALL_PACKAGES` (très restreinte) au profit de `<queries>`. Si tu publies, relis la politique Google sur ces permissions.
- **Ne pas déranger** : le lanceur le désactive au retour dans l'appli *seulement s'il l'avait activé lui-même*.

## Idées pour la suite

Favoris et tri des jeux, temps de jeu par titre, fond animé selon le jeu sélectionné,
raccourcis vers le mode Jeu d'Android 12+, thèmes de couleurs, widget d'écran d'accueil.
