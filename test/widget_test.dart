import 'package:flutter_test/flutter_test.dart';

import 'package:my_edu_app/main.dart';

void main() {
  testWidgets('MyEduApp bootstrap smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BootstrapApp());

    // BootstrapApp asynchronously initializes AppState.
    // The test only verifies that the root widget can be mounted.
    await tester.pump();
  });
}
