import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/ui/theme/app_theme.dart';
import 'src/router/app_router.dart';
import 'src/ui/widgets/notification_overlay.dart';
import 'src/providers/auth_provider.dart';
import 'src/services/services.dart';

void main() {
  runApp(const ProviderScope(child: IntelCryptApp()));
}

class IntelCryptApp extends ConsumerWidget {
  const IntelCryptApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'IntelCrypt',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _WebSocketConnector(
        child: NotificationOverlay(child: child ?? const SizedBox()),
      ),
    );
  }
}

/// Watches auth state and connects/disconnects the STOMP WebSocket accordingly.
class _WebSocketConnector extends ConsumerWidget {
  final Widget child;
  const _WebSocketConnector({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // Connect when authenticated, disconnect on logout
    if (auth.isAuthenticated &&
        auth.token?.accessToken != null &&
        auth.currentUser?.id != null) {
      // Use addPostFrameCallback to avoid calling provider during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final wsNotifier = ref.read(webSocketServiceProvider.notifier);
        final wsState = ref.read(webSocketServiceProvider);
        if (!wsState.connected) {
          wsNotifier.connect(auth.token!.accessToken, auth.currentUser!.id);
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(webSocketServiceProvider.notifier).disconnect();
      });
    }

    return child;
  }
}
