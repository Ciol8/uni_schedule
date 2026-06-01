import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/note.dart';

// Przekazujemy <Parametr (String), Stan (List<Note>)>
final notesProvider = AsyncNotifierProviderFamily<NotesNotifier, List<Note>, String>(
  NotesNotifier.new,
);

class NotesNotifier extends FamilyAsyncNotifier<List<Note>, String> {
  @override
  Future<List<Note>> build(String arg) async {
    // 'arg' to nasz subjectId
    return ref.read(noteRepositoryProvider).getNotesForSubject(arg);
  }

  Future<void> addNote(Note note) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(noteRepositoryProvider).addNote(note);
      return ref.read(noteRepositoryProvider).getNotesForSubject(arg);
    });
  }

  Future<void> toggleTask(String noteId, bool isCompleted) async {
    // Tutaj nie dajemy stanu 'loading', żeby checkboxy w UI klikały się natychmiastowo bez mrugania (Optimistic UI update można dodać tu w przyszłości)
    await ref.read(noteRepositoryProvider).toggleTaskCompletion(noteId, isCompleted);
    // Odświeżamy listę w tle
    ref.invalidateSelf(); 
  }
}