import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/avoid_item/presentation/screens/avoid_input_screen.dart';
import '../../features/avoid_item/presentation/screens/avoid_list_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/menu/presentation/screens/analysis_result_screen.dart';
import '../../features/menu/presentation/screens/analysis_loading_screen.dart';
import '../../features/camera/presentation/screens/camera_screen.dart';
import '../../features/history/presentation/screens/history_detail_screen.dart';
import '../../features/history/data/repositories/history_repository.dart';
import '../../features/team/presentation/screens/team_list_screen.dart';
import '../../features/team/presentation/screens/team_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = ValueNotifier(0);
  ref.onDispose(authRefresh.dispose);
  ref.listen(authProvider, (previous, next) {
    authRefresh.value++;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthLoading = authState.isLoading;
      final isAuthenticated = authState.valueOrNull != null;
      final location = state.matchedLocation;
      final isSplashRoute = location == '/splash';
      final isAuthRoute = location == '/login' || location == '/signup';

      if (isAuthLoading) {
        return isSplashRoute ? null : '/splash';
      }

      if (!isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (isSplashRoute || isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'avoid-input',
            builder: (context, state) => const AvoidInputScreen(),
          ),
          GoRoute(
            path: 'avoid-list',
            builder: (context, state) => const AvoidListScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/analysis-loading',
        builder: (context, state) {
          final extra = state.extra;
          XFile? imageFile;
          int? teamMemberId;
          String? menuLang;

          if (extra is Map) {
            imageFile =
                extra['imageFile'] as XFile? ?? extra['image'] as XFile?;
            teamMemberId = extra['teamMemberId'] as int?;
            menuLang = extra['menuLang'] as String?;
          } else if (extra is XFile) {
            // Backward compatibility: previous flow passed XFile directly
            imageFile = extra;
          }

          if (imageFile == null) {
            return const HomeScreen();
          }

          final localeCode = Localizations.localeOf(context).languageCode;
          final resolvedMenuLang = (menuLang == null || menuLang.trim().isEmpty)
              ? localeCode
              : menuLang.trim();

          return AnalysisLoadingScreen(
            imageFile: imageFile,
            teamMemberId: teamMemberId,
            menuLang: resolvedMenuLang,
          );
        },
      ),

      GoRoute(
        path: '/analysis-result',
        builder: (context, state) {
          final extra = state.extra;
          String? imagePath;
          int? teamMemberId;

          if (extra is Map) {
            imagePath =
                extra['imagePath'] as String? ?? extra['image'] as String?;
            teamMemberId = extra['teamMemberId'] as int?;
          } else if (extra is String) {
            // Backward compatibility: previous flow passed imagePath directly
            imagePath = extra;
          }

          if (imagePath == null || imagePath.trim().isEmpty) {
            return const HomeScreen();
          }

          return AnalysisResultScreen(
            imagePath: imagePath,
            teamMemberId: teamMemberId,
          );
        },
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final teamMemberId = extra?['teamMemberId'] as int?;
          return CameraScreen(teamMemberId: teamMemberId);
        },
      ),
      GoRoute(
        path: '/history-detail',
        builder: (context, state) {
          final historyItem = state.extra as HistoryItem;
          return HistoryDetailScreen(historyItem: historyItem);
        },
      ),
      GoRoute(
        path: '/teams',
        builder: (context, state) => const TeamListScreen(),
        routes: [
          GoRoute(
            path: ':teamMemberId',
            builder: (context, state) {
              final id =
                  int.tryParse(state.pathParameters['teamMemberId'] ?? '0') ??
                  0;
              return TeamDetailScreen(teamMemberId: id);
            },
          ),
        ],
      ),
    ],
  );
});
