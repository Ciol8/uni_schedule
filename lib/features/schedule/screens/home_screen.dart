import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../providers/calendar_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/class_card.dart';
import '../../../core/providers/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dailyScheduleAsync = ref.watch(scheduleByDateProvider(selectedDay));

    // 1. Pobieramy aktualny motyw
    final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twój Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // 2. NOWY PRZYCISK: Przełącznik Dark Mode
          IconButton(
            icon: Icon(currentTheme == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: 'Zmień motyw',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
              currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
// ... reszta Twojego kodu ...
            tooltip: 'Zarządzaj przedmiotami',
            onPressed: () {
              context.push('/manage-subjects');
            },
          ),
          // --- STARY PRZYCISK WYLOGOWYWANIA ---
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
                // --- PUSTY STAN (Gdy w dany dzień nie ma zajęć) ---
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(scheduleProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.coffee_rounded, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Brak zajęć w tym dniu!',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pociągnij w dół, aby odświeżyć\nalbo po prostu odpocznij.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // --- LISTA ZAJĘĆ Z GESTAMI (Swipe to Cancel / Delete) ---
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(scheduleProvider);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(bottom: 80, top: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      // Sprawdzamy stan odwołania dla wybranej daty w kalendarzu
                      final dateStr = '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
                      final isCancelled = item.cancelledDates.contains(dateStr);

                      return Dismissible(
                        key: ValueKey('${item.id}_$isCancelled'),

                        // Zezwalamy na gesty w obu kierunkach!
                        direction: isCancelled ? DismissDirection.endToStart : DismissDirection.horizontal,

                        // --- TŁO 1: Swipe od LEWEJ do PRAWEJ (Odwołanie w konkretny dzień) ---
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          child: const Icon(Icons.event_busy_rounded, color: Colors.white, size: 32),
                        ),

                        // --- TŁO 2: Swipe od PRAWEJ do LEWEJ (Usuwanie na zawsze z planu) ---
                        secondaryBackground: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
                        ),

                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // ODWOŁANIE ZAJĘĆ
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Odwołać dzisiejsze zajęcia?'),
                                content: const Text('Zajęcia z tego przedmiotu zostaną przekreślone tylko w dniu dzisiejszym. W pozostałe tygodnie pozostaną bez zmian.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nie')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Odwołaj zajęcia'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref.read(scheduleProvider.notifier).cancelItem(item.id!, selectedDay);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zajęcia zostały odwołane!')));
                            }
                            // Blokujemy zniknięcie karty z UI, Riverpod sam odrysuje ją na szaro
                            return false;
                          } else {
                            // USUWANIE ZAJĘĆ
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Usuwanie zajęć', style: TextStyle(fontWeight: FontWeight.bold)),
                                content: Text('Czy na pewno chcesz na zawsze usunąć te zajęcia z przedmiotu ${item.subject?.name ?? "Nieznany"} z planu?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Usuń na zawsze'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            ref.read(scheduleProvider.notifier).deleteItem(item.id!);
                          }
                        },
                        child: ClassCard(item: item, selectedDate: selectedDay),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-class');
        },
        icon: const Icon(Icons.add),
        label: const Text('Dodaj zajęcia'),
      ),
    );
  }
}