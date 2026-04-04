import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AnalyticsService.init();
  await AnalyticsService.track('session_started', {
    'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
  });

  final b2b = B2BContainer.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppNotifier()),
        Provider<B2BContainer>.value(value: b2b),
        ChangeNotifierProvider(create: (_) => B2BNotifier(b2b)),
      ],
      child: const HereMapApp(),
    ),
  );
}
