import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/routing/app_router.dart';
import 'features/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- START POWIADOMIEŃ ---
  await NotificationService.init();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: UniScheduleApp()));
}

// Zmieniamy na ConsumerWidget, żeby móc odczytać routerProvider
class UniScheduleApp extends ConsumerWidget {
  const UniScheduleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Plan Zajęć',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF070291)),
        useMaterial3: true,
      ),
      // Podpinamy konfigurację GoRoutera
      routerConfig: router,
    );
  }
}