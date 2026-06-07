import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/schedule_provider.dart';

class WeeklyScheduleScreen extends ConsumerWidget {
  const WeeklyScheduleScreen({super.key});

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleProvider);
    final days = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Tygodnia', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: scheduleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (items) {
          // W widoku tygodnia pokazujemy tylko stały plan (ignorujemy jednorazowe wyjątki)
          final regularItems = items.where((item) => item.specificDate == null).toList();

          if (regularItems.isEmpty) {
            return const Center(child: Text('Brak stałych zajęć w planie.', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 7, // 7 dni tygodnia
            itemBuilder: (context, index) {
              final dayOfWeek = index + 1;

              // Pobieramy zajęcia dla danego dnia i sortujemy po godzinie
              final dayItems = regularItems.where((item) => item.dayOfWeek == dayOfWeek).toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

              // Jeśli w dany dzień nie ma zajęć, nie rysujemy dla niego pustej karty
              if (dayItems.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 24),
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nagłówek dnia
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text(
                        days[index],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    // Lista zajęć w tym dniu
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: dayItems.map((item) {
                          final color = item.subject?.color != null ? _getColorFromHex(item.subject!.color) : Colors.grey;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Linia czasu z lewej
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(item.startTime.substring(0, 5), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(item.endTime.substring(0, 5), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Pionowy, kolorowy pasek przedmiotu
                                  Container(width: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                                  const SizedBox(width: 12),
                                  // Detale
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(item.subject?.name ?? 'Nieznany', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('${item.classType} • sala: ${item.location ?? "-"}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}