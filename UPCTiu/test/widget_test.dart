import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:upctiu/main.dart';

void main() {
  testWidgets('La pantalla TIU muestra los datos por defecto', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initializeDateFormatting('es_ES', null);

    await tester.pumpWidget(MyApp(prefs: prefs));

    expect(find.text('TIU VIRTUAL'), findsOneWidget);
    expect(find.text('EDERY RENZO A*** V***'), findsOneWidget);
    expect(find.text('201822832'), findsOneWidget);
    expect(find.text('N01864219'), findsOneWidget);

    // Desmonta la pantalla para que se cancelen los timers del reloj.
    await tester.pumpWidget(const SizedBox());
  });
}
