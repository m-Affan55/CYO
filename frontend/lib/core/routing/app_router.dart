import 'package:go_router/go_router.dart';
import 'package:frontend/features/auth/presentation/welcome_screen.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/auth/presentation/how_it_works_screen.dart';
import 'package:frontend/features/auth/presentation/profile_creation_screen.dart';
import 'package:frontend/features/home/presentation/home_screen.dart';
import 'package:frontend/features/lobby/presentation/online_multiplayer_screen.dart';
import 'package:frontend/features/lobby/presentation/create_game_screen.dart';
import 'package:frontend/features/lobby/presentation/game_lobby_screen.dart';
import 'package:frontend/features/game/presentation/in_game_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/how-it-works',
      builder: (context, state) => const HowItWorksScreen(),
    ),
    GoRoute(
      path: '/profile-creation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final isGuest = extra?['isGuest'] as bool? ?? false;
        return ProfileCreationScreen(isGuest: isGuest);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/online-multiplayer',
      builder: (context, state) => const OnlineMultiplayerScreen(),
    ),
    GoRoute(
      path: '/create-game',
      builder: (context, state) => const CreateGameScreen(),
    ),
    GoRoute(
      path: '/game-lobby',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final isSecretMode = extra?['isSecretMode'] as bool? ?? false;
        return GameLobbyScreen(isSecretMode: isSecretMode);
      },
    ),
    GoRoute(
      path: '/in-game',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final isSecretMode = extra?['isSecretMode'] as bool? ?? false;
        return InGameScreen(isSecretMode: isSecretMode);
      },
    ),
  ],
);
