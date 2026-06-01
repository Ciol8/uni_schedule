import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/subject.dart';

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
}