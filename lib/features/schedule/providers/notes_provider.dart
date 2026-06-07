import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/providers/repository_providers.dart';
import '../../notes/models/note.dart';

// Używamy stabilnego StateNotifierProvider zamiast problematycznego AsyncNotifierProvider.family
final notesProvider = StateNotifierProvider.family<NotesNotifier, AsyncValue<List<Note>>, String>((ref, subjectId) {
  return NotesNotifier(ref, subjectId);
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final Ref ref;
  final String subjectId;

  NotesNotifier(this.ref, this.subjectId) : super(const AsyncValue.loading()) {
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    try {
      final notes = await ref.read(scheduleRepositoryProvider).getNotes(subjectId);
      if (mounted) state = AsyncValue.data(notes);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNote(Note note) async {
    state = const AsyncValue.loading();
    await ref.read(scheduleRepositoryProvider).addNote(note);
    await _fetchNotes();
  }

  Future<void> updateNote(Note note) async {
    // Aktualizujemy bez loading(), żeby checkbox odhaczał się płynnie
    await ref.read(scheduleRepositoryProvider).updateNote(note);
    await _fetchNotes();
  }

  Future<void> deleteNote(String id) async {
    state = const AsyncValue.loading();
    await ref.read(scheduleRepositoryProvider).deleteNote(id);
    await _fetchNotes();
  }
}