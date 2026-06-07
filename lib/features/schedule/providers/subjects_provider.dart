import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/subject.dart';
import 'schedule_provider.dart';

final subjectsProvider = AsyncNotifierProvider<SubjectsNotifier, List<Subject>>(
  SubjectsNotifier.new,
);

class SubjectsNotifier extends AsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() async {
    // Odpala się automatycznie przy pierwszym użyciu i pobiera dane
    return ref.read(scheduleRepositoryProvider).getSubjects();
  }

  Future<void> addSubject(Subject subject) async {
    // Zmieniamy stan na "ładowanie"
    state = const AsyncValue.loading();
    
    // Zabezpieczamy się blokiem try-catch
    state = await AsyncValue.guard(() async {
      await ref.read(scheduleRepositoryProvider).addSubject(subject);
      // Pobieramy odświeżoną listę po dodaniu
      return ref.read(scheduleRepositoryProvider).getSubjects();
    });
  }
  Future<void> updateSubject(Subject subject) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(scheduleRepositoryProvider).updateSubject(subject);
      // Musimy odświeżyć też plan zajęć, żeby karty natychmiast zmieniły kolory!
      ref.invalidate(scheduleProvider);
      return await ref.read(scheduleRepositoryProvider).getSubjects();
    });
  }

  Future<void> deleteSubject(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(scheduleRepositoryProvider).deleteSubject(id);
      // Usunięcie przedmiotu usunęło też zajęcia w bazie, więc odświeżamy plan
      ref.invalidate(scheduleProvider);
      return await ref.read(scheduleRepositoryProvider).getSubjects();
    });
  }
}