import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/signup_screen.dart';
import '../ui/screens/chat_list_screen.dart';
import '../ui/screens/chat_message_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/security_screen.dart';
import '../ui/screens/admin_dashboard_screen.dart';
import '../ui/screens/activity_log_screen.dart';
import '../models/models.dart';

/// Application Router Configuration
/// Provides typed route navigation with deep linking support
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Implement custom redirect logic if needed
    return null;
  },
  routes: [
    // Splash Screen
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Authentication Routes
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),

    // Main Application Routes
    GoRoute(
      path: '/chats',
      name: 'chat_list',
      builder: (context, state) => const ChatListScreen(),
      routes: [
        GoRoute(
          path: ':chatId',
          name: 'chat_message',
          builder: (context, state) {
            final chatId = state.pathParameters['chatId']!;
            final chatName = state.uri.queryParameters['chatName'] ?? 'Chat';
            final chatAvatar = state.uri.queryParameters['chatAvatar'];
            return ChatMessageScreen(
              chatId: chatId,
              chatName: chatName,
              chatAvatar: chatAvatar,
            );
          },
          routes: [
            GoRoute(
              path: 'compose',
              name: 'compose_message',
              builder: (context, state) {
                final chatId = state.pathParameters['chatId']!;
                return ComposeMessageScreen(chatId: chatId);
              },
            ),
          ],
        ),
      ],
    ),

    // User Profile Routes
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    // Security Routes
    GoRoute(
      path: '/security',
      name: 'security',
      builder: (context, state) => const SecurityScreen(),
    ),

    // Admin Routes (admin-only access)
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),

    // Activity Log Route
    GoRoute(
      path: '/activity_log',
      name: 'activity_log',
      builder: (context, state) {
        final message = state.extra as Message;
        return ActivityLogScreen(message: message);
      },
    ),
    ],

  // Error handling
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
);

/// Error Screen for invalid routes
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({Key? key, this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.goNamed('chat_list'),
              child: const Text('Go to Chats'),
            ),
          ],
        ),
      ),
    );
  }
}

class ComposeMessageScreen extends StatelessWidget {
  final String chatId;

  const ComposeMessageScreen({Key? key, required this.chatId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compose Message')),
      body: Center(
        child: Text('Compose Screen for Chat $chatId - Coming Soon'),
      ),
    );
  }
}

// ProfileScreen and SecurityScreen are now using real implementations from profile_screen.dart and security_screen.dart
