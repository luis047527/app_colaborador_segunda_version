import 'package:flutter_test/flutter_test.dart';
import 'package:app_colaborador_segunda_version/main.dart';

void main() {
  testWidgets('MainApp shows Login when not authenticated (default)', (tester) async {
    await tester.pumpWidget(const MainApp());
    await tester.pump();
    // Default AuthService is not authenticated -> LoginScreen
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
  });
}
