import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../providers/calendar_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/class_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dailyScheduleAsync = ref.watch(scheduleByDayProvider(selectedDay.weekday));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twój Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Wyloguj',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDay,
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (newSelectedDay, focusedDay) {
                // Nowy, poprawny sposób na zmianę stanu w Notifierze
                ref.read(selectedDayProvider.notifier).updateDay(newSelectedDay);
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: dailyScheduleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('Błąd ładowania: $error')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.weekend_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Brak zajęć w ten dzień!', style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ClassCard(item: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // --- PODMIEŃ FLOATING ACTION BUTTON NA TO ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-class'); // Przejście do formularza
        },
        icon: const Icon(Icons.add),
        label: const Text('Dodaj zajęcia'),
      ),
    );
  }
}