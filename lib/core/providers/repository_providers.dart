import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/schedule/repositories/schedule_repository.dart';
import '../../features/notes/repositories/note_repository.dart';

// Te providery to tzw. Singletony - tworzą jedną instancję repozytorium na całą aplikację
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) => ScheduleRepository());
final noteRepositoryProvider = Provider<NoteRepository>((ref) => NoteRepository());