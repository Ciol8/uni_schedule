import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject.dart';
import '../models/schedule_item.dart';

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

  Future<void> cancelClassForDate(String scheduleItemId, DateTime date) async {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await _client.from('schedule_cancellations').insert({
      'schedule_item_id': scheduleItemId,
      'cancelled_date': dateString,
    });
  }
}