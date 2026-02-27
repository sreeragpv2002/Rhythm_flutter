import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/features/auth/presentation/login_screen.dart';
import 'package:rhythm_flutter/features/auth/presentation/registration_screen.dart';
import 'package:rhythm_flutter/features/auth/providers/auth_provider.dart';
import 'package:rhythm_flutter/features/main_shell/presentation/main_screen.dart';
import 'package:rhythm_flutter/features/profile/presentation/profile_creation_screen.dart';
import 'package:rhythm_flutter/features/splash/presentation/splash_screen.dart';
import 'package:rhythm_flutter/features/home/presentation/home_tab.dart';
import 'package:rhythm_flutter/features/search/presentation/search_tab.dart';
import 'package:rhythm_flutter/features/settings/presentation/settings_tab.dart';
import 'package:rhythm_flutter/features/player/presentation/song_detail_screen.dart';
import 'package:rhythm_flutter/features/home/presentation/section_detail_screen.dart';
import 'package:rhythm_flutter/features/home/presentation/library_tab.dart';
import 'package:flutter/material.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/profile-creation',
        builder: (context, state) => const ProfileCreationScreen(),
      ),
      GoRoute(
        path: '/player/:musicId',
        pageBuilder: (context, state) {
          final musicId = int.tryParse(state.pathParameters['musicId'] ?? '');
          return CustomTransitionPage(
            key: state.pageKey,
            child: SongDetailScreen(initialMusicId: musicId ?? 0),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeTab(),
                routes: [
                  GoRoute(
                    path: 'section/:slug',
                    builder: (context, state) {
                      final slug = state.pathParameters['slug'] ?? '';
                      final title = state.extra as String? ?? '';
                      return SectionDetailScreen(slug: slug, title: title);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _searchNavigatorKey,
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsTab(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      final isRegister = state.matchedLocation == '/register';
      final isProfileCreation = state.matchedLocation == '/profile-creation';


      // If at splash, don't redirect yet (splash handles its own timer)
      if (isSplash) return null;

      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final hasProfile = authState.hasProfile;

      if (!isLoggedIn) {
        if (isLogin || isRegister) return null;
        return '/login';
      }

      if (!hasProfile) {
        if (isProfileCreation) return null;
        return '/profile-creation';
      }

      // If logged in and has profile, but trying to access auth screens
      if (isLogin || isRegister || isProfileCreation) {
        return '/';
      }

      return null;
    },
  );
});
