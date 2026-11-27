import 'package:material_ui/material_ui.dart';

import 'screens/dashboard_screen.dart';
import 'services/subscription_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = SubscriptionRepository();
  await repository.init();
  runApp(RadarAssinaturasApp(repository: repository));
}

class RadarAssinaturasApp extends StatelessWidget {
  const RadarAssinaturasApp({super.key, required this.repository});

  final SubscriptionRepository repository;

  ThemeMode _resolveThemeMode(String mode) {
    return switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        return MaterialApp(
          title: 'Radar Assinaturas',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _resolveThemeMode(repository.themeMode),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: DashboardScreen(repository: repository),
        );
      },
    );
  }
}
