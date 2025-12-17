import 'package:flutter_test/flutter_test.dart';
import 'package:here_map/app.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HereMapApp());
  });
}
