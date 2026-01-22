import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/ui/theme/app_theme.dart';
import 'src/router/app_router.dart';

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
    );
  }
}
