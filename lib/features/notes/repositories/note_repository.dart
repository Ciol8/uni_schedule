import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';

class NoteRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Note>> getNotesForSubject(String subjectId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('notes')
        .select()
        .eq('user_id', userId)
        .eq('subject_id', subjectId)
        .order('created_at', ascending: false);

    return response.map((json) => Note.fromJson(json)).toList();
  }

  Future<void> addNote(Note note) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Brak autoryzacji');

    final data = note.toJson();
    data['user_id'] = userId;

    await _client.from('notes').insert(data);
  }

  Future<void> toggleTaskCompletion(String noteId, bool isCompleted) async {
    await _client.from('notes').update({'is_completed': isCompleted}).eq('id', noteId);
  }
  
  Future<void> deleteNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }
}