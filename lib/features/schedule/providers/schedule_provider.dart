import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../models/schedule_item.dart';

final scheduleProvider = AsyncNotifierProvider<ScheduleNotifier, List<ScheduleItem>>(
  ScheduleNotifier.new,
);

class ScheduleNotifier extends AsyncNotifier<List<ScheduleItem>> {
  @override
  Future<List<ScheduleItem>> build() async {
    return ref.read(scheduleRepositoryProvider).getScheduleItems();
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(scheduleRepositoryProvider).addScheduleItem(item);
      return ref.read(scheduleRepositoryProvider).getScheduleItems();
    });
  }

  Future<void> deleteItem(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(scheduleRepositoryProvider).deleteScheduleItem(id);
      return ref.read(scheduleRepositoryProvider).getScheduleItems();
    });
  }
}

// QoL: Rodzina providerów, która pozwala UI zapytać: "Hej, daj mi tylko zajęcia na wtorek (2)"
final scheduleByDayProvider = Provider.family<List<ScheduleItem>, int>((ref, dayOfWeek) {
  final scheduleState = ref.watch(scheduleProvider);
  
  return scheduleState.maybeWhen(
    data: (items) {
      // Wyciągamy zajęcia z danego dnia i sortujemy od najwcześniejszych
      final filtered = items.where((item) => item.dayOfWeek == dayOfWeek).toList();
      filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
      return filtered;
    },
    orElse: () => [], // Jeśli ładuje lub jest błąd, zwracamy pusto
  );
});