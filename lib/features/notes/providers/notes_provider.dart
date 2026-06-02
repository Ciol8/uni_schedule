import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/note.dart';

// 1. Zwykły FutureProvider - pobiera dane z bazy i SAM załatwia stan ładowania (AsyncValue)
final notesProvider = FutureProvider.family<List<Note>, String>((ref, subjectId) async {
  return ref.read(noteRepositoryProvider).getNotesForSubject(subjectId);
});

// 2. Prosty kontroler do akcji (dodawanie i odhaczanie)
final notesControllerProvider = Provider<NotesController>((ref) => NotesController(ref));

class NotesController {
  final Ref ref;
  NotesController(this.ref);

  Future<void> addNote(String subjectId, Note note) async {
    await ref.read(noteRepositoryProvider).addNote(note);

    // Magia Riverpoda: mówimy mu "odśwież notatki dla tego przedmiotu"
    ref.invalidate(notesProvider(subjectId));
  }

  Future<void> toggleTask(String subjectId, String noteId, bool isCompleted) async {
    await ref.read(noteRepositoryProvider).toggleTaskCompletion(noteId, isCompleted);

    // Znowu odświeżamy listę po zmianie statusu
    ref.invalidate(notesProvider(subjectId));
  }
}