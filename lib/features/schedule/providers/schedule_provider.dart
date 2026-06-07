import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/schedule_item.dart';
import '../../notifications/notification_service.dart';


final scheduleProvider = AsyncNotifierProvider<ScheduleNotifier, List<ScheduleItem>>(
  ScheduleNotifier.new,
);

class ScheduleNotifier extends AsyncNotifier<List<ScheduleItem>> {
  @override
  Future<List<ScheduleItem>> build() async {
    final items = await ref.read(scheduleRepositoryProvider).getScheduleItems();
    // Przy każdym pobraniu danych z bazy aktualizujemy systemowe alarmy
    await NotificationService.rescheduleAll(items);
    return items;
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(scheduleRepositoryProvider).addScheduleItem(item);
      final items = await ref.read(scheduleRepositoryProvider).getScheduleItems();
      await NotificationService.rescheduleAll(items); // Aktualizacja alarmów
      return items;
    });
  }

  Future<void> deleteItem(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(scheduleRepositoryProvider).deleteScheduleItem(id);
      final items = await ref.read(scheduleRepositoryProvider).getScheduleItems();
      await NotificationService.rescheduleAll(items); // Aktualizacja alarmów
      return items;
    });
  }
}

// QoL: Rodzina providerów, która zwraca zajęcia z zachowaniem stanu ładowania/błędu (AsyncValue)
// Zmieniamy nazwę na scheduleByDateProvider i przyjmujemy obiekt DateTime
final scheduleByDateProvider = Provider.family<AsyncValue<List<ScheduleItem>>, DateTime>((ref, date) {
  final scheduleState = ref.watch(scheduleProvider);
  
  return scheduleState.whenData((items) {
    final filtered = items.where((item) {
      
      // 1. ZAJĘCIA JEDNORAZOWE (Wyjątki)
      if (item.specificDate != null) {
        final specificDate = DateTime.parse(item.specificDate!);
        // Pokaż tylko jeśli dzisiejsza data IDEALNIE zgadza się z datą zajęć
        return specificDate.year == date.year &&
               specificDate.month == date.month &&
               specificDate.day == date.day;
      }
      
      // 2. REGULARNE ZAJĘCIA CO TYDZIEŃ
      return item.dayOfWeek == date.weekday;
      
    }).toList();
    
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  });
});