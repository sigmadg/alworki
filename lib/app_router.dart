import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'state/auth_controller.dart';
import 'ui/profile/publish_portfolio_gallery_screen.dart';
import 'ui/profile/publish_portfolio_details_screen.dart';
import 'ui/profile/portfolio_feed_screen.dart';
import 'ui/feed/create_post_screen.dart';
import 'ui/feed/create_story_screen.dart';
import 'ui/projects/create_project_screen.dart';
import 'ui/projects/project_tracking_screen.dart';
import 'ui/auth/auth_screen.dart';
import 'ui/auth/forgot_password_screen.dart';
import 'ui/auth/verify_identity_screen.dart';
import 'ui/auth/whatsapp_verification_screen.dart';
import 'ui/chat/chat_screen.dart';
import 'ui/exchange/exchange_requests_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/messages/direct_chat_screen.dart';
import 'ui/messages/messages_screen.dart';
import 'ui/notifications/notifications_screen.dart';
import 'ui/contacts/contacts_screen.dart';
import 'ui/settings/blocked_contacts_screen.dart';
import 'ui/settings/contact_requests_screen.dart';
import 'ui/profile/profile_screen.dart';
import 'ui/profile/user_profile_screen.dart';
import 'ui/checkout/buy_blue_coins_screen.dart';
import 'ui/checkout/quote_checkout_screen.dart';
import 'ui/orders/service_completion_screen.dart';
import 'models/quote_checkout_data.dart';
import 'models/user_profile.dart';
import 'ui/projects/projects_screen.dart';
import 'ui/categories/categories_screen.dart';
import 'ui/search/search_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/shell/main_shell.dart';

GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (BuildContext context, GoRouterState state) {
      final loc = state.matchedLocation;
      final logged = auth.isLoggedIn;

      if (loc == '/splash') return null;

      const public = {
        '/login',
        '/register',
        '/forgot-password',
        '/verify-whatsapp',
      };
      if (!logged && !public.contains(loc)) return '/login';
      if (logged && (loc == '/login' || loc == '/register')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const AuthScreen(initialTab: 1)),
      GoRoute(path: '/register', builder: (context, state) => const AuthScreen(initialTab: 0)),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/verify-identity', builder: (context, state) => const VerifyIdentityScreen()),
      GoRoute(
        path: '/verify-whatsapp',
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? extra : <String, dynamic>{};
          return WhatsappVerificationScreen(
            phone: map['phone'] as String? ?? '',
            email: map['email'] as String? ?? '',
            password: map['password'] as String? ?? '',
          );
        },
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(path: '/create-post', builder: (context, state) => const CreatePostScreen()),
      GoRoute(path: '/create-story', builder: (context, state) => const CreateStoryScreen()),
      GoRoute(path: '/create-project', builder: (context, state) => const CreateProjectScreen()),
      GoRoute(path: '/publish-portfolio', builder: (context, state) => const PublishPortfolioGalleryScreen()),
      GoRoute(
        path: '/publish-portfolio/details',
        builder: (context, state) {
          final imageKey = state.extra as String? ?? 'background1.png';
          return PublishPortfolioDetailsScreen(imageKey: imageKey);
        },
      ),
      GoRoute(
        path: '/portfolio-feed',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            final raw = extra['items'];
            final items = raw is List<PortfolioItem>
                ? raw
                : raw is List
                    ? raw.whereType<PortfolioItem>().toList()
                    : <PortfolioItem>[];
            return PortfolioFeedScreen(
              userName: extra['name'] as String? ?? '',
              avatarKey: extra['avatar'] as String? ?? 'users/user.jpg',
              userId: (extra['userId'] as num?)?.toInt(),
              items: items,
            );
          }
          return const PortfolioFeedScreen(userName: '', avatarKey: 'users/user.jpg', items: []);
        },
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(
        path: '/contacts',
        builder: (context, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return ContactsScreen(initialTab: tab);
        },
      ),
      GoRoute(path: '/settings/contact-requests', builder: (context, state) => const ContactRequestsScreen()),
      GoRoute(path: '/settings/blocked-contacts', builder: (context, state) => const BlockedContactsScreen()),
      GoRoute(
        path: '/messages/:threadId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['threadId'] ?? '') ?? 1;
          return DirectChatScreen(threadId: id);
        },
      ),
      GoRoute(path: '/exchange', builder: (context, state) => const ExchangeRequestsScreen()),
      GoRoute(
        path: '/quote-checkout',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is QuoteCheckoutData) {
            return QuoteCheckoutScreen(quote: extra);
          }
          if (extra is Map<String, dynamic>) {
            return QuoteCheckoutScreen(quote: QuoteCheckoutData.fromJson(extra));
          }
          return const Scaffold(body: Center(child: Text('Datos de cotización inválidos')));
        },
      ),
      GoRoute(
        path: '/buy-blue-coins',
        builder: (context, state) {
          final mxn = int.tryParse(state.uri.queryParameters['mxn'] ?? '') ?? 220;
          return BuyBlueCoinsScreen(amountMxn: mxn);
        },
      ),
      GoRoute(
        path: '/order/:tracking',
        builder: (context, state) {
          final tracking = state.pathParameters['tracking'] ?? '';
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return ServiceCompletionScreen(tracking: tracking, initialTab: tab);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => SearchScreen(
          initialQuery: state.uri.queryParameters['q'] ?? '',
        ),
      ),
      GoRoute(path: '/projects', builder: (context, state) => const ProjectsScreen()),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ProjectTrackingScreen(projectId: id);
        },
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
          final q = state.uri.queryParameters;
          return UserProfileScreen(
            userId: id,
            fallbackName: q['name'],
            fallbackAvatar: q['avatar'],
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
                  return ProfileScreen(initialTab: tab.clamp(0, 2));
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen())],
          ),
        ],
      ),
    ],
  );
}
