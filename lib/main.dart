import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_router.dart';
import 'dev/dev_backend.dart';
import 'services/api_client.dart';
import 'services/auth_api.dart';
import 'services/catalog_service.dart';
import 'services/exchange_repository.dart';
import 'services/order_service.dart';
import 'services/profile_actions_service.dart';
import 'services/social_service.dart';
import 'services/wallet_service.dart';
import 'state/auth_controller.dart';
import 'state/chatbot_controller.dart';
import 'services/chatbot_service.dart';
import 'theme/app_theme.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
    );
  }
  await ensureDevBackendRunning();

  final api = ApiClient();
  final auth = AuthController(AuthApi());
  await auth.loadSession();

  final catalog = CatalogService(api, () => auth.accessToken);
  final exchange = ExchangeRepository(api, () => auth.accessToken);
  final profileActions = ProfileActionsService(api, () => auth.accessToken);
  final social = SocialService(api, () => auth.accessToken);
  final wallet = WalletService(api, () => auth.accessToken);
  final orders = OrderService(api, () => auth.accessToken);

  final router = createAppRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: auth),
        ChangeNotifierProvider<CatalogService>.value(value: catalog),
        ChangeNotifierProvider<ExchangeRepository>.value(value: exchange),
        Provider<ProfileActionsService>.value(value: profileActions),
        ChangeNotifierProvider<SocialService>.value(value: social),
        ChangeNotifierProvider<WalletService>.value(value: wallet),
        ChangeNotifierProvider<OrderService>.value(value: orders),
        ChangeNotifierProvider(create: (_) => ChatbotController(ChatbotService())),
      ],
      child: AlworkiApp(router: router),
    ),
  );

  // Cargar datos remotos después de mostrar la UI (evita pantalla negra).
  Future.microtask(() async {
    await catalog.refresh();
    if (auth.isLoggedIn) {
      await Future.wait([
        social.loadMessages(),
        wallet.load(),
        orders.loadOrders(),
      ]);
    }
  });
}

class AlworkiApp extends StatelessWidget {
  const AlworkiApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Alworki',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
