import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:here_map/app_core.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    final b2b = B2BContainer.create();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppNotifier()),
          Provider<B2BContainer>.value(value: b2b),
          ChangeNotifierProvider(create: (_) => B2BNotifier(b2b)),
        ],
        child: const HereMapApp(),
      ),
    );
  });
}
