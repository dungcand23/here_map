import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';

import 'app.dart';
import 'services/analytics_service.dart';
import 'state/app_notifier.dart';
import 'b2b/b2b_notifier.dart';
import 'b2b/repositories/b2b_container.dart';

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
