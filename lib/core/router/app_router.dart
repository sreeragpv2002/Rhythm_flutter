import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/features/album/presentation/album_detail_screen.dart';
import 'package:rhythm_flutter/features/artist/presentation/artist_detail_screen.dart';
import 'package:rhythm_flutter/features/auth/presentation/login_screen.dart';
import 'package:rhythm_flutter/features/auth/presentation/registration_screen.dart';
import 'package:rhythm_flutter/features/auth/providers/auth_provider.dart';
import 'package:rhythm_flutter/features/main_shell/presentation/main_screen.dart';
import 'package:rhythm_flutter/features/playlist/presentation/playlist_detail_screen.dart';
import 'package:rhythm_flutter/features/playlist/presentation/user_playlist_detail_screen.dart';
import 'package:rhythm_flutter/features/playlist/presentation/user_playlists_screen.dart';
import 'package:rhythm_flutter/features/profile/presentation/profile_creation_screen.dart';
import 'package:rhythm_flutter/features/splash/presentation/splash_screen.dart';
import 'package:rhythm_flutter/features/home/presentation/home_tab.dart';
import 'package:rhythm_flutter/features/search/presentation/search_tab.dart';
import 'package:rhythm_flutter/features/settings/presentation/settings_tab.dart';
import 'package:rhythm_flutter/features/player/presentation/song_detail_screen.dart';
import 'package:rhythm_flutter/features/home/presentation/section_detail_screen.dart';
import 'package:rhythm_flutter/features/language/presentation/language_selection_screen.dart';
import 'package:rhythm_flutter/features/settings/presentation/favorites_screen.dart';
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
          final musicId = state.pathParameters['musicId'] ?? '0';
          return CustomTransitionPage(
            key: state.pageKey,
            child: SongDetailScreen(initialMusicId: musicId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/album/:albumId',
        pageBuilder: (context, state) {
          final albumId = state.pathParameters['albumId'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: AlbumDetailScreen(albumId: albumId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/playlist/:playlistId',
        pageBuilder: (context, state) {
          final playlistId = state.pathParameters['playlistId'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlaylistDetailScreen(playlistId: playlistId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/artist/:artistId',
        pageBuilder: (context, state) {
          final artistId = state.pathParameters['artistId'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ArtistDetailScreen(artistId: artistId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/languages',
        builder: (context, state) {
          final isFirstTime = state.extra as bool? ?? false;
          return LanguageSelectionScreen(isFirstTime: isFirstTime);
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
                routes: [
                  GoRoute(
                    path: 'languages',
                    builder: (context, state) {
                      final isFirstTime = state.extra as bool? ?? false;
                      return LanguageSelectionScreen(isFirstTime: isFirstTime);
                    },
                  ),
                  GoRoute(
                    path: 'favorites',
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                  GoRoute(
                    path: 'playlists',
                    builder: (context, state) => const UserPlaylistsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const FavoritesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/user-playlists',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const UserPlaylistsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/user-playlist/:playlistId',
        pageBuilder: (context, state) {
          final playlistId = state.pathParameters['playlistId'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: UserPlaylistDetailScreen(playlistId: playlistId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
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
