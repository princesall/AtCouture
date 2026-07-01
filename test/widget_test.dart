import 'package:flutter_test/flutter_test.dart';

import 'package:styleconnect/app.dart';
import 'package:styleconnect/providers/auth_provider.dart';

void main() {
  testWidgets('StyleConnect affiche le splash', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await authProvider.initialize();

    await tester.pumpWidget(StyleConnectApp(authProvider: authProvider));
    await tester.pump();

    expect(find.text('StyleConnect'), findsOneWidget);
  });
}
