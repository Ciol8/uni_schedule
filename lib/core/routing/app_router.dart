import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/schedule/screens/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Podpinamy się pod zmiany stanu autoryzacji
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Czy aktualnie ktoś jest zalogowany?
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      // Czy aktualnie próbujemy wejść na stronę logowania?
      final isGoingToLogin = state.matchedLocation == '/login';

      // Jeśli nie zalogowany i nie idzie do logowania -> zmuś do logowania
      if (!isAuthenticated && !isGoingToLogin) return '/login';
      
      // Jeśli zalogowany, a próbuje wejść na logowanie -> przekieruj na główną
      if (isAuthenticated && isGoingToLogin) return '/';

      return null; // Brak zmian trasy
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});