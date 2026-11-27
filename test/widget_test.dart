import 'package:flutter_test/flutter_test.dart';
import 'package:radar_assinaturas/main.dart';
import 'package:radar_assinaturas/services/subscription_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dashboard carrega título Radar Assinaturas', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = SubscriptionRepository();
    await repository.init();

    await tester.pumpWidget(RadarAssinaturasApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Radar Assinaturas'), findsOneWidget);
    expect(find.text('Gasto Mensal'), findsOneWidget);
  });
}
