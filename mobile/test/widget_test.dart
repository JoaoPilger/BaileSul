import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App carrega e exibe header', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Conteúdo'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(
      find.text('© BaileSul – Todos os direitos reservados.'),
      findsOneWidget,
    );
  });
}
