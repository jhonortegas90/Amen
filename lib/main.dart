import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'src/app.dart';
import 'src/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Altar Radio Playback',
      androidNotificationOngoing: true,
    );
  }

  final views = WidgetsBinding.instance.platformDispatcher.views;
  bool isTablet = false;
  if (views.isNotEmpty) {
    final double shortestSide =
        views.first.physicalSize.shortestSide / views.first.devicePixelRatio;
    isTablet = shortestSide >= 600;
  }

  if (!isTablet) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  final bootstrap = await FirebaseBootstrap.initialize();

  runApp(
    ProviderScope(
      overrides: [firebaseBootstrapProvider.overrideWithValue(bootstrap)],
      child: const AmenApp(),
    ),
  );
}
