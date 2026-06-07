import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/schedule/screens/home_screen.dart';
import '../../features/schedule/screens/add_class_screen.dart';
import '../../features/notes/screens/subject_notes_screen.dart';
import '../../features/schedule/models/subject.dart';
import '../../features/schedule/screens/manage_subjects_screen.dart';
import '../../features/schedule/screens/main_screen.dart';
import '../../features/schedule/screens/class_details_screen.dart';
import '../../features/schedule/models/schedule_item.dart';

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
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/add-class',
        builder: (context, state) {
          // Odbieramy parametry, jeśli jakieś zostały przekazane (extra)
          final item = state.extra as ScheduleItem?;
          return AddClassScreen(itemToEdit: item);
        },
      ),
      // Zadbaj o zaimportowanie nowego ekranu na samej górze pliku:

      GoRoute(
        path: '/class-details',
        builder: (context, state) {
          // Odbieramy mapę przekazaną z ClassCard
          final extras = state.extra as Map<String, dynamic>;
          return ClassDetailsScreen(
            item: extras['item'] as ScheduleItem,
            heroColor: extras['color'] as Color,
          );
        },
      ),
      GoRoute(
        path: '/manage-subjects',
        builder: (context, state) => const ManageSubjectsScreen(),
      ),
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