import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:little_yahya/main.dart';
import 'package:little_yahya/services/storage_service.dart';

void main() {
  testWidgets('App loads Today screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    await tester.pumpWidget(LittleYahyaApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
  });
}
