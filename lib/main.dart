import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja połączenia z Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  // ProviderScope to "płaszcz" Riverpoda, musi oplatać całą aplikację
  runApp(const ProviderScope(child: UniScheduleApp()));
}

class UniScheduleApp extends StatelessWidget {
  const UniScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plan Zajęć',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF070291)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Aplikacja zainicjalizowana poprawnie! 🚀'),
        ),
      ),
    );
  }
}