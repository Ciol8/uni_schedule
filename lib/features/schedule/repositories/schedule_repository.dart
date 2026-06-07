import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject.dart';
import '../models/schedule_item.dart';
import '../../notes/models/note.dart';

class ScheduleRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // --- PRZEDMIOTY ---
  Future<List<Subject>> getSubjects() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client.from('subjects').select().eq('user_id', userId);
    return response.map((json) => Subject.fromJson(json)).toList();
  }

  Future<void> addSubject(Subject subject) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Brak autoryzacji');

    final data = subject.toJson();
    data['user_id'] = userId; // Bezpieczne wstrzyknięcie właściciela dla RLS

    await _client.from('subjects').insert(data);
  }
  Future<void> updateSubject(Subject subject) async {
    await _client.from('subjects').update({
      'name': subject.name,
      'color': subject.color,
    }).eq('id', subject.id!);
  }

  Future<void> deleteSubject(String id) async {
    await _client.from('subjects').delete().eq('id', id);
  }
  // --- PLAN ZAJĘĆ ---
  Future<List<ScheduleItem>> getScheduleItems() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Magia Supabase: W jednym zapytaniu wyciągamy zajęcia ORAZ podpięty pod nie przedmiot
    final response = await _client
        .from('schedule_items')
        .select('*, subjects(*), schedule_cancellations(cancelled_date)')
        .eq('user_id', userId);
        
    return response.map((json) => ScheduleItem.fromJson(json)).toList();
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Brak autoryzacji');

    final data = item.toJson();
    data['user_id'] = userId;

    await _client.from('schedule_items').insert(data);
  }
  
  Future<void> deleteScheduleItem(String id) async {
     await _client.from('schedule_items').delete().eq('id', id);
  }
  Future<void> updateScheduleItem(ScheduleItem item) async {
    // Aktualizujemy rekord po ID. Metoda toJson() pomija pobrane dodatkowe dane z relacji.
    await _client.from('schedule_items').update(item.toJson()).eq('id', item.id!);
  }

  Future<void> cancelClassForDate(String scheduleItemId, DateTime date) async {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await _client.from('schedule_cancellations').insert({
      'schedule_item_id': scheduleItemId,
      'cancelled_date': dateString,
    });
  }
  // --- NOTATKI I ZADANIA ---
  Future<List<Note>> getNotes(String subjectId) async {
    // Pobieramy notatki dla konkretnego przedmiotu, sortując od najnowszych
    final response = await _client.from('notes').select().eq('subject_id', subjectId).order('created_at', ascending: false);
    return response.map((json) => Note.fromJson(json)).toList();
  }

  Future<void> addNote(Note note) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Brak autoryzacji');

    final data = note.toJson();
    data['user_id'] = userId;
    await _client.from('notes').insert(data);
  }

  Future<void> updateNote(Note note) async {
    await _client.from('notes').update(note.toJson()).eq('id', note.id!);
  }

  Future<void> deleteNote(String id) async {
    await _client.from('notes').delete().eq('id', id);
  }
}