import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/allergy/presentation/screens/allergy_selection_screen.dart';
import '../../features/avoid_item/presentation/screens/avoid_input_screen.dart';
import '../../features/avoid_item/presentation/screens/avoid_list_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/menu/presentation/screens/analysis_result_screen.dart';
import '../../features/menu/presentation/screens/analysis_loading_screen.dart';
import '../../features/camera/presentation/screens/camera_screen.dart';
import '../../features/history/presentation/screens/history_detail_screen.dart';
import '../../features/history/data/repositories/history_repository.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
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
            path: 'allergy',
            builder: (context, state) => const AllergySelectionScreen(),
          ),
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
          final imageFile = state.extra as XFile;
          return AnalysisLoadingScreen(imageFile: imageFile);
        },
      ),

      GoRoute(
        path: '/analysis-result',
        builder: (context, state) {
          final imagePath = state.extra as String;
          return AnalysisResultScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) {
          return const CameraScreen();
        },
      ),
      GoRoute(
        path: '/history-detail',
        builder: (context, state) {
          final historyItem = state.extra as HistoryItem;
          return HistoryDetailScreen(historyItem: historyItem);
        },
      ),
    ],
  );
});
