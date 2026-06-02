import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/schedule/screens/home_screen.dart';
import '../../features/schedule/screens/add_class_screen.dart';
import '../../features/notes/screens/subject_notes_screen.dart';
import '../../features/schedule/models/subject.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Podpinamy się pod zmiany stanu autoryzacji
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isGoingToLogin) return '/login';
      if (isAuthenticated && isGoingToLogin) return '/';

      return null;
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
      GoRoute(
        path: '/add-class',
        builder: (context, state) => const AddClassScreen(),
      ),
      // --- TUTAJ JEST NASZA NOWA TRASA ---
      GoRoute(
        path: '/subject/:id',
        builder: (context, state) {
          final subjectId = state.pathParameters['id']!;
          final subject = state.extra as Subject;
          return SubjectNotesScreen(subjectId: subjectId, subject: subject);
        },
      ),
    ],
  );
});