import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_prof/core/theme/app_theme.dart';
import 'package:pocket_prof/core/router/app_router.dart';
import 'package:pocket_prof/services/storage_service.dart';
import 'package:pocket_prof/providers/settings_provider.dart';
import 'package:web/web.dart' as web;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage before app starts
  // The HTML splash screen will remain visible during this time
  await StorageService.instance.init();

  runApp(const ProviderScope(child: PocketProfApp()));

  // Remove the HTML splash screen once the app (Flutter engine) is running
  // We use a small delay to ensure the first frame of the app is painted, preventing a white flash
  Future.delayed(const Duration(milliseconds: 400), () {
    final splash = web.document.querySelector('#app-splash');
    if (splash != null) {
      // Optional: Add a CSS class for fade-out effect if supported, or just remove
      splash.remove();
    }
  });
}

class PocketProfApp extends ConsumerWidget {
  const PocketProfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PocketProf - AI Eğitmen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
